#!/bin/bash
# GRAALVM_HOME=/Users/stooke/dev/ojdk/graal/vm/mxbuild/darwin-amd64/GRAALVM_SVM/graalvm-svm-20.0.0-beta.02-dev/Contents/Home

# define build environment
BUILD_DIR=`pwd`
TMP_DIR="$BUILD_DIR/tmp"
GRAAL_DIR="$BUILD_DIR/graal11"
pushd `dirname $0`
SCRIPT_DIR=`pwd`
popd
mkdir -p "$TMP_DIR"
TOOL_DIR="$BUILD_DIR/tools"

download_graal() {
	clone_or_update https://github.com/oracle/graal.git "$GRAAL_DIR"
	clone_or_update https://github.com/graalvm/graalvm-demos "$BUILD_DIR/graalvm-demos"
}

clean_graal() {
	cd "$GRAAL_DIR"
	for a in compiler sdk substratevm sulong tools vm truffle ; do 
		pushd $a
		mx clean
		popd
	done 
}

make_foo() {
	echo "class Foo { public static void main(String[] args) { System.out.println(\"Hello, world\"); } }" >"$TMP_DIR/Foo.java"
	$JAVA_HOME/bin/javac -classpath "$TMP_DIR" "$TMP_DIR/Foo.java"
}

build_graal() {
	cd "$GRAAL_DIR"
	make_foo
	#mx --primary-suite-path compiler build
	#mx --primary-suite-path substratevm build
	#mx --primary-suite-path vm build
	mx --primary-suite-path substratevm native-image --help
	mx --primary-suite-path substratevm native-image -classpath "$TMP_DIR" "Foo" "$TMP_DIR/foo"
#	mx --primary-suite-path compiler vm -XX:+PrintFlagsFinal -version 2>&1 || grep JVMCI
}

. "$SCRIPT_DIR/tools.sh" "$TOOL_DIR" autoconf mx mercurial bootstrap_jdk11

download_graal

export PATH="$JAVA_HOME/bin:$PATH"

set -x
#clean_graal
build_graal

