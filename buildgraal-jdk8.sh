#!/bin/bash

set -e

GRAAL_SOURCE_URL=https://github.com/oracle/graal.git

#JDK8_JVMCI_PREBUILT_URL=https://github.com/graalvm/openjdk8-jvmci-builder/releases/download/jvmci-20.0-b02/openjdk-8u242-jvmci-20.0-b02-darwin-amd64.tar.gz
JDK8_JVMCI_PREBUILT_URL=https://github.com/graalvm/openjdk8-jvmci-builder/releases/download/jvmci-20.0-b02/openjdk-8u242-jvmci-20.0-b02-fastdebug-darwin-amd64.tar.gz


## if true, then download a prebuilt jvmci JDK8
## if false, then build one locally
DOWNLOAD_JCVMCI_JDK8=true

# define build environment
BUILD_DIR=`pwd`
TMP_DIR="$BUILD_DIR/tmp"
GRAAL_DIR="$BUILD_DIR/graal8"
pushd `dirname $0`
SCRIPT_DIR=`pwd`
PATCH_DIR="$SCRIPT_DIR/jdk8u-patch"
popd
TOOL_DIR="$BUILD_DIR/tools"

##############################################

download_jvmci_jdk8() {
	if test -d "$TOOL_DIR/jvmci_jdk8" ; then
		return
	fi
	download_and_open $JDK8_JVMCI_PREBUILT_URL "$TOOL_DIR/jvmci_jdk8"
}

build_jdk8() {
	cd "$BUILD_DIR"
	clone_or_update https://github.com/stooke/jdk8u-xcode10.git "$TMP_DIR/jdk8u-xcode10"
	JDK_BASE=jdk8u-dev BUILD_SHENANDOAH=false BUILD_JAVAFX=false DEBUG_LEVEL=fastdebug "$TMP_DIR/jdk8u-xcode10/build8.sh"
	NEW_JAVA_HOME="$BUILD_DIR/jdk8u-dev/build/macosx-x86_64-normal-server-fastdebug/images/j2sdk-image"
}

build_jvmci_jdk8() {
	build_jdk8
	clone_or_update https://github.com/graalvm/graal-jvmci-8 "$BUILD_DIR/graal-jvmci-8"
	cd "$BUILD_DIR/graal-jvmci-8"
	JAVA_HOME="$NEW_JAVA_HOME"
	mx --java-home "$NEW_JAVA_HOME" build
	mx --java-home "$NEW_JAVA_HOME" unittest
	echo JVMCI_JDK_HOME is `mx --java-home "$NEW_JAVA_HOME" jdkhome`
}

#################################################

build_graal() {
	cd "$GRAAL_DIR"
 	mx --primary-suite-path substratevm build
}

debug_graal() {
	cd "$GRAAL_DIR"
	mx --primary-suite-path substratevm native-image -J-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005 ListDir
}

download_graal() {
	clone_or_update $GRAAL_SOURCE_URL "$GRAAL_DIR"
	cd "$GRAAL_DIR"
}

test_graal() {
	clone_or_update https://github.com/graalvm/graalvm-demos "$BUILD_DIR/graalvm-demos"
	cd "$BUILD_DIR/graalvm-demos/native-list-dir"
	./build.sh
	./run.sh
}
	
clean_graal() {
	cd "$GRAAL_DIR"
	for a in compiler sdk substratevm sulong tools vm truffle ; do 
		pushd $a
		mx clean
		popd
	done 
}

###############################################

. $SCRIPT_DIR/tools.sh "$TOOL_DIR" mx 

if $DOWNLOAD_JCVMCI_JDK8 ; then
	download_jvmci_jdk8
	export JAVA_HOME="$TOOL_DIR/jvmci_jdk8/Contents/Home"
else
	build_jvmci_jdk8
	cd "$BUILD_DIR/graal-jvmci-8"
	export JAVA_HOME=$(mx --java-home "$NEW_JAVA_HOME" jdkhome)
fi

echo Using JAVA_HOME=$JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

download_graal
#clean_graal
build_graal
export GRAALVM_HOME="$GRAAL_DIR/sdk/mxbuild/darwin-amd64/GRAALVM_UNKNOWN_JAVA8/graalvm-unknown-java8-20.1.0-dev/Contents/Home"

test_graal


