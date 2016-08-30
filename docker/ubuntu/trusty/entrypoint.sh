#!/bin/bash

set -ex

su - builder -c "cp -r /sources/* $BUILDER_HOME"

DEBUILD_OPTS="--lintian-opts --allow-root"

if [ $DOCKER_SOURCE_ONLY -eq 1 ]; then
	DEBUILD_OPTS="-S -nc ${DEBUILD_OPTS}"
else
	apt-get update
	DEBUILD_OPTS="-b ${DEBUILD_OPTS}"
fi

if [ $DOCKER_DEBUILD_SIGN -eq 1 ]; then
	eval "$(gpg-agent --daemon)"
	mkdir -p ~/.gnupg
        echo use-agent >> ~/.gnupg/gpg.conf
        echo "pinentry-program /usr/bin/pinentry-curses" >> ~/.gnupg/gpg-agent.conf
	cp /sources/secring.gpg ~/.gnupg
	cp /sources/pubring.gpg ~/.gnupg
else
	DEBUILD_OPTS="-us -uc ${DEBUILD_OPTS}"
fi

for i; do
	pushd "$i"

	if [ $DOCKER_SOURCE_ONLY -eq 1 ]; then
	        su - builder -c "mkdir -p debian/patches"
	        EDITOR=/bin/true su - builder -c "cd $i && dpkg-source -q --commit . $i.patch"
	else
		mk-build-deps --install --remove --tool "apt-get --no-install-recommends --yes"
	fi

	debuild $DOCKER_DEBUILD_OPTS $DEBUILD_OPTS

	if [ $DOCKER_SOURCE_ONLY -eq 1 ]; then
		for changes in $(find $BUILDER_HOME -maxdepth 1 -name '*.changes'); do
			cp ${changes} /output/
		done
		for desc in $(find $BUILDER_HOME -maxdepth 1 -name '*.dsc'); do
			cp ${desc} /output/
		done
		for debian in $(find $BUILDER_HOME -maxdepth 1 -name '*.debian.tar.*'); do
			cp ${debian} /output/
		done
		for orig in $(find $BUILDER_HOME -maxdepth 1 -name '*.orig.tar.gz'); do
			cp ${orig} /output/
		done
		chown builder:builder /output/*.changes
		chown builder:builder /output/*.dsc
		chown builder:builder /output/*.debian.tar.*
		chown builder:builder /output/*.orig.tar.gz
	else
		dpkg -i $BUILDER_HOME/*.deb
		mv $BUILDER_HOME/*.deb /output/
		chown builder:builder /output/*.deb
	fi

	popd
done

if [ $DOCKER_DEBUILD_SIGN -eq 1 ]; then
	if [ -n "${GPG_AGENT_INFO}" ]; then
		kill $(echo ${GPG_AGENT_INFO} | cut -d':' -f 2) >/dev/null 2>&1
	fi
fi
