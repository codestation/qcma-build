#!/bin/bash

PACKAGE_LIST=(vitamtp-2.5.9 qcma-0.3.12)
SUPPORTED_DISTROS=(fedora:24 opensuse:42.1 debian:jessie ubuntu:trusty ubuntu:xenial)
SOURCES_ONLY=0
SIGN_SOURCES=0
PACKAGE_REVISION=1
PPA_NAMING=1
GPG_PRIVKEY=~/.gnupg/secring.gpg
GPG_PUBKEY=~/.gnupg/pubring.gpg

show_usage() {
    echo -e "Usage: $0 <distro:version>"
    echo ""
    echo -e "distro/version choices:"
    for distro in ${SUPPORTED_DISTROS[@]}; do
        echo -e $distro
    done
    echo -e "all (make builds for all supported distros)"
}

if [ $# -lt 1 ]
then
    show_usage
    exit 1
fi

set -ex

DISTRO_FOUND=0

for distro in ${SUPPORTED_DISTROS[@]}; do
    if [ $1 == $distro ]; then
        DISTRO_FOUND=1
    fi
done

if [ $DISTRO_FOUND -eq 0 ]; then
    if [ $1 == "all" ]; then
        for distro in ${SUPPORTED_DISTROS[@]}; do
            echo "Building $distro"
            ./$0 $distro
        done
        exit 0
    else
        echo -e "Invalid distro/version combination: $1"
        exit 1
    fi
fi

DISTRO=${1%:*}
DISTRO_VERSION=${1#*:}

CACHE_DIR="${1/:/_}_cache"

if [ $DISTRO == "fedora" ]; then
    CACHE_VOLUME="/var/cache/dnf"
    METHOD="rpmbuild"
elif [ $DISTRO == "opensuse" ]; then
    CACHE_VOLUME="/var/cache/zypp"
    METHOD="rpmbuild"
else
    CACHE_VOLUME="/var/cache/apt"
    METHOD="debuild"
fi

PACKAGE_NAMES=()
for package in ${PACKAGE_LIST[@]}; do
    if [ $DISTRO == "debian" ] || [ $DISTRO == "ubuntu" ]; then
        PACKAGE_NAMES+=(${package})
    else
	PACKAGE_NAMES+=(${package%-*})
    fi
done

CURDIR=$(dirname $(readlink -f $0))

function prepare_package() {
    PACKAGE=$1
    VERSION=$2

    if [ "$VERSION" == "testing" ] || [ "$VERSION" == "master" ]; then
        VERSION_PATH=${VERSION}
    else
        VERSION_PATH="v${VERSION}"
    fi

    pushd "${CURDIR}/sources" > /dev/null

    if [ $DISTRO == "debian" ] || [ $DISTRO == "ubuntu" ]; then
        if [ -f "${CURDIR}/tarballs/${PACKAGE}-${VERSION}.tar.gz" ]; then
            cp "${CURDIR}/tarballs/${PACKAGE}-${VERSION}.tar.gz" ${PACKAGE}_${VERSION}.orig.tar.gz
        else
            wget -c https://github.com/codestation/${PACKAGE}/archive/${VERSION_PATH}/${PACKAGE}-${VERSION}.tar.gz \
                -O ${PACKAGE}_${VERSION}.orig.tar.gz
        fi

        tar xf ${PACKAGE}_${VERSION}.orig.tar.gz

        if [ $DISTRO == "ubuntu" ] && [ $PPA_NAMING -eq 1 ]; then
            VERSION_STR="-0ubuntu1~${DISTRO_VERSION}1~ppa${PACKAGE_REVISION}"
            sed --follow-symlinks -i "s/${PACKAGE} (\(.*\)) unstable/${PACKAGE} (\1${VERSION_STR}) ${DISTRO_VERSION}/" ${PACKAGE}-${VERSION}/ChangeLog
        else
            sed --follow-symlinks -i "s/${PACKAGE} (\(.*\)) unstable/${PACKAGE} (\1) ${DISTRO_VERSION}/" ${PACKAGE}-${VERSION}/ChangeLog
        fi

        # Force quilt for ubuntu packages
        if [ $DISTRO == "ubuntu" ]; then
            # force quilt to apply patches.
            sed -i 's/native/quilt/' ${PACKAGE}-${VERSION}/debian/source/format
        fi

        # do not patch debian packages, stick to native
        if [ $DISTRO != "debian" ]; then
            # apply global package patches
            pushd ${PACKAGE}-${VERSION} > /dev/null
            for global_patches in $(find "${CURDIR}/patches/${PACKAGE}" -maxdepth 1 -name '*.patch'); do
                patch -p1 < "${global_patches}"
            done

            # apply distro-only patches
            for distro_patches in $(find "${CURDIR}/patches/${PACKAGE}/${DISTRO}" -maxdepth 1 -name '*.patch'); do
                patch -p1 < "${distro_patches}"
            done

            # apply patches for only distro:version
            for versioned_patches in $(find "${CURDIR}/patches/${PACKAGE}/${DISTRO}/${DISTRO_VERSION}" -maxdepth 1 -name '*.patch'); do
                patch -p1 < "${versioned_patches}"
            done
            popd > /dev/null
        fi

    else
        if [ -f "${CURDIR}/tarballs/${PACKAGE}-${VERSION}.tar.gz" ]; then
            cp "${CURDIR}/tarballs/${PACKAGE}-${VERSION}.tar.gz" rpmbuild/SOURCES/${PACKAGE}-${VERSION}.tar.gz
        else
            wget -c https://github.com/codestation/${PACKAGE}/archive/${VERSION_PATH}/${PACKAGE}-${VERSION}.tar.gz \
                -O rpmbuild/SOURCES/${PACKAGE}-${VERSION}.tar.gz
        fi

        tar xf rpmbuild/SOURCES/$PACKAGE-${VERSION}.tar.gz --strip-components 2 \
            -C rpmbuild/SPECS $PACKAGE-${VERSION}/rpmbuild/${PACKAGE}.spec

        sed -i "s/%define _version.*/%define _version ${VERSION}/" rpmbuild/SPECS/${PACKAGE}.spec
    fi
    
    popd > /dev/null
}

rm -rf "${CURDIR}/sources/*"

if [ $DISTRO == "fedora" ] || [ $DISTRO == "opensuse" ]; then
    mkdir -p "${CURDIR}"/sources/rpmbuild/{BUILD,RPMS,SPECS,SRPMS,SOURCES}
fi

for package in ${PACKAGE_LIST[@]}; do
    PACKAGE_NAME=${package%-*}
    PACKAGE_VERSION=${package#*-}
    prepare_package ${PACKAGE_NAME} ${PACKAGE_VERSION}
done

if [ $SIGN_SOURCES -eq 1 ]; then
    cp "${GPG_PRIVKEY}" "${CURDIR}/sources/secring.gpg"
    cp "${GPG_PUBKEY}" "${CURDIR}/sources/pubring.gpg"
fi

docker run --rm -it -v "${CACHE_DIR}":${CACHE_VOLUME} \
    -v "${CURDIR}/${DISTRO}_${DISTRO_VERSION}_output":/output \
    -v ${CURDIR}/sources:/sources \
    -e DOCKER_SOURCE_ONLY=${SOURCES_ONLY} \
    -e DOCKER_DEBUILD_SIGN=${SIGN_SOURCES} \
    -it code/${METHOD}-${DISTRO}:${DISTRO_VERSION} ${PACKAGE_NAMES[@]}
