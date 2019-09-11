#!/bin/bash

set -e

# define build environment
BUILD_DIR=`pwd`
TMP_DIR="$BUILD_DIR/tmp"
LOOM_DIR="$BUILD_DIR/loom"
pushd `dirname $0`
SCRIPT_DIR=`pwd`
popd
mkdir -p "$TMP_DIR"
TOOL_DIR="$BUILD_DIR/tools"
LOOM_URL=https://github.com/openjdk/loom
#LOOM_URL=http://hg.openjdk.java.net/loom/loom

download_loom() {
	clone_or_update $LOOM_URL "$LOOM_DIR"
}

clean_loom() {
	cd "$LOOM_DIR"
	make clean
}

make_foo() {
	echo "class Foo { public static void main(String[] args) { System.out.println(\"Hello, world\"); } }" >"$TMP_DIR/Foo.java"
	$JAVA_HOME/bin/javac -classpath "$TMP_DIR" "$TMP_DIR/Foo.java"
}

build_loom() {
	cd "$LOOM_DIR"
	#make_foo
	#hg update -r fibers
	git checkout fibers
	sh configure  
	make images
}

. "$SCRIPT_DIR/tools.sh" "$TOOL_DIR" autoconf mercurial jtreg bootstrap_jdk12

download_loom

export PATH="$JAVA_HOME/bin:$PATH"

set -x
#clean_loom
build_loom

