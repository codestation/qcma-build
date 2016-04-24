#!/bin/bash

CONTAINERS=(fedora:23 opensuse:13.2 debian:jessie ubuntu:trusty ubuntu:wily ubuntu:xenial)

CURDIR=$(dirname $(readlink -f $0))

set -ex

for container in ${CONTAINERS[@]}; do
    DISTRO=${container%:*}
    VERSION=${container#*:}

    if [ $DISTRO == "fedora" ] || [ $DISTRO == "opensuse" ]; then
        docker build -t code/rpmbuild-${DISTRO}:${VERSION} "${CURDIR}/docker/${DISTRO}"
    else
        docker build -t code/debuild-${DISTRO}:${VERSION} "${CURDIR}/docker/${DISTRO}/${VERSION}"
    fi
done
