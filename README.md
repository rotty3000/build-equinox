# build-equinox
The equinox build is complex. This repo contains a `bash` script to make it a little simpler.

Simply run the `build-equinox.sh` script in a root directory which already contains the top level `eclipse.platform.releng.aggregator` git repo. If the directory does not contain that repository, it will be checked out.

`./build-equinox.sh`

If you want to build a specific branch execute the script with the name of the branch as the only argument.

`./build-equinox.sh R4_5_maintenance`

There is a prerequisite that `git` be installed as well as a version of `maven` >= 3.3 be installed as the equinox build requires it.

# Java 8
The master branch also requires Java 8. If you already run Java 8 then there is nothing to do. However, if you are using an older JVM for any reason you can execute the script exporting `JAVA_HOME` variable pointing to a Java 8 JDK install.

e.g. for Debian
```
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64; ./build-equinox.sh R4_5_maintenance
```

This should satisfy the build.

If you checkout a branch which does not require Java 8 then this is obviously not needed.