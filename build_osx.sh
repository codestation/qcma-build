#!/bin/bash

readlink2() {
    TARGET_FILE=$1

    cd `dirname $TARGET_FILE`
    TARGET_FILE=`basename $TARGET_FILE`

    # Iterate down a (possible) chain of symlinks
    while [ -L "$TARGET_FILE" ]
    do
        TARGET_FILE=`readlink $TARGET_FILE`
        cd `dirname $TARGET_FILE`
        TARGET_FILE=`basename $TARGET_FILE`
    done

    # Compute the canonicalized name by finding the physical path 
    # for the directory we're in and appending the target file.
    PHYS_DIR=`pwd -P`
    RESULT=$PHYS_DIR/$TARGET_FILE
    echo $RESULT
}

show_usage() {
    echo -e "Usage: $0 <vitamtp_version> <qcma_version>"
}

PATH="$PATH:/usr/local/bin"

if [ $# -lt 2 ]
then
    show_usage
    exit 1
fi

set -ex

VITAMTP_VERSION=$1
QCMA_VERSION=$2

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

CURDIR=$(dirname $(readlink2 $0))

rm -f "${CURDIR}"/qcma-${QCMA_VERSION}.dmg
rm -rf "${CURDIR}/build"
mkdir -p "${CURDIR}/build"

pushd "${CURDIR}/build" > /dev/null

if [ -f "${CURDIR}/sources/vitamtp-${VITAMTP_VERSION}.tar.gz" ]; then
    cp "${CURDIR}/sources/vitamtp-${VITAMTP_VERSION}.tar.gz" vitamtp-${VITAMTP_VERSION}.tar.gz
else
    wget -c https://github.com/codestation/vitamtp/archive/v${VITAMTP_VERSION}/vitamtp-${VITAMTP_VERSION}.tar.gz \
        -O vitamtp-${VITAMTP_VERSION}.tar.gz
fi

tar xf vitamtp-${VITAMTP_VERSION}.tar.gz
pushd vitamtp-${VITAMTP_VERSION} > /dev/null

sed -i "" -e "s/libtoolize/glibtoolize/" autogen.sh
./autogen.sh
./configure
make -j2
make install

popd > /dev/null

if [ -f "${CURDIR}/sources/qcma-${QCMA_VERSION}.tar.gz" ]; then
    cp "${CURDIR}/sources/qcma-${QCMA_VERSION}.tar.gz" qcma-${QCMA_VERSION}.tar.gz
else
    wget -c https://github.com/codestation/qcma/archive/v${QCMA_VERSION}/qcma-${QCMA_VERSION}.tar.gz \
        -O qcma-${QCMA_VERSION}.tar.gz
fi

tar xf qcma-${QCMA_VERSION}.tar.gz
pushd qcma-${QCMA_VERSION} > /dev/null

lrelease qcma.pro
qmake qcma.pro
make -j2
macdeployqt qcma.app

cp -r qcma.app "${CURDIR}/build/Qcma.app"

popd > /dev/null

hdiutil create -volname qcma-${QCMA_VERSION} -srcfolder Qcma.app -ov -format UDZO qcma-${QCMA_VERSION}.dmg

cp qcma-${QCMA_VERSION}.dmg "${CURDIR}"

popd > /dev/null

rm -r "${CURDIR}/build"
