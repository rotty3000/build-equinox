#!/bin/bash
#
#   Copyright 2016, 2021 Raymond Augé
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

BRANCH=${1:-master}
LOG=/tmp/build-equinox.log

checkoutSubmodule() {
	(
		local name=${1##*/}
		echo "[----> Initing Submodule '${name}']" | tee $LOG
		git submodule update "${name}" >>$LOG 2>&1
		cd "${name}"
		git fetch origin ${BRANCH}:${BRANCH} >>$LOG 2>&1
		git checkout ${BRANCH} >>$LOG 2>&1
	)&
	spin $!
}

clone_and_init() {
	repo_dir=${1##*/}
	repo_dir=${repo_dir%.git}
	(
		echo "[----> Cloning '${repo_dir}']" | tee $LOG
		git clone -b master --depth=1 --progress "$1" ${repo_dir} >>$LOG 2>&1
		cd ${repo_dir}
		git fetch origin ${BRANCH}:${BRANCH} >>$LOG 2>&1
		git checkout ${BRANCH} >>$LOG 2>&1
		git submodule init >>$LOG 2>&1
	)&
	spin $!

	cd "${repo_dir}"
}

install() {
	(
		echo "[----> Installing '${1##*/}']" | tee $LOG
		cd "$1"
		mvn -N install >>$LOG 2>&1
	)&
	spin $!
}

integrationTest() {
	(
		echo "[----> Integration Testing '${1##*/}']" | tee $LOG
		cd "$1"
		mvn verify 2>&1 | tee $LOG
	)
}

spin() {
	local s=("|" "/" "-" '\x5C')
	local i=0
	while kill -0 $1 2> /dev/null; do
		echo -en "[${s[$i]}]"\\r
		i=$(( $i == 3 ? 0 : $i + 1 ))
		sleep .1
	done
}

if [ -e $LOG ]; then
	rm $LOG
fi

START=$(date +%s.%N)

cd ../

# (optional) Save this in your .profile or .bashrc for reuse, speeds up the build
export MAVEN_OPTS="-Xmx2048m -Declipse.p2.mirrors=false"

clone_and_init "https://git.eclipse.org/r/platform/eclipse.platform.releng.aggregator.git"

checkoutSubmodule "eclipse.platform.runtime"
checkoutSubmodule "rt.equinox.framework"
checkoutSubmodule "rt.equinox.bundles"

install "eclipse-platform-parent"
install "eclipse.platform.releng.prereqs.sdk"

install "rt.equinox.framework"
install "rt.equinox.framework/bundles/org.eclipse.osgi"
install "rt.equinox.framework/bundles/org.eclipse.osgi.util"
install "rt.equinox.framework/bundles/org.eclipse.osgi.services"
install "rt.equinox.framework/bundles/org.eclipse.equinox.launcher"

install "rt.equinox.bundles"
install "rt.equinox.bundles/bundles/org.eclipse.equinox.http.servlet"
install "rt.equinox.bundles/bundles/org.eclipse.equinox.util"
install "rt.equinox.bundles/bundles/org.eclipse.equinox.http.jetty"
install "rt.equinox.bundles/bundles/org.eclipse.equinox.common"
install "rt.equinox.bundles/bundles/org.eclipse.equinox.registry"
install "rt.equinox.bundles/bundles/org.eclipse.equinox.app"
install "rt.equinox.bundles/bundles/org.eclipse.equinox.preferences"

install "eclipse.platform.runtime"
install "eclipse.platform.runtime/bundles/org.eclipse.core.jobs"
install "eclipse.platform.runtime/bundles/org.eclipse.core.contenttype"
install "eclipse.platform.runtime/bundles/org.eclipse.core.runtime"

#integrationTest "rt.equinox.bundles/bundles/org.eclipse.equinox.http.servlet.tests"

END=$(date +%s.%N)
DIFF=$(bc -l <<< "scale=3; ($END - $START)")
echo "[----> Build Time: ${DIFF}s]"
