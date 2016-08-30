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
	su - builder -c eval "$(gpg-agent --daemon)"
	su - builder -c mkdir -p ~/.gnupg
        su - builder -c "echo use-agent >> ~/.gnupg/gpg.conf"
        su - builder -c "echo "pinentry-program /usr/bin/pinentry-curses" >> ~/.gnupg/gpg-agent.conf"
	su - builder -c cp /sources/secring.gpg ~/.gnupg
	su - builder -c cp /sources/pubring.gpg ~/.gnupg
else
	DEBUILD_OPTS="-us -uc ${DEBUILD_OPTS}"
fi

for i; do
	pushd "$i"

	if [ $DOCKER_SOURCE_ONLY -eq 1 ]; then
	        su - builder -c mkdir -p debian/patches
	        EDITOR=/bin/true su - builder -c dpkg-source -q --commit . $i.patch
	else
		mk-build-deps --install --remove --tool "apt-get --no-install-recommends --yes"
	fi

	su - builder -c "cd $i && debuild $DOCKER_DEBUILD_OPTS $DEBUILD_OPTS"

	if [ $DOCKER_SOURCE_ONLY -eq 1 ]; then
		for changes in $(find /sources -maxdepth 1 -name '*.changes'); do
			su - builder -c cp "${changes}" /output/
		done
		for desc in $(find /sources -maxdepth 1 -name '*.dsc'); do
			su - builder -c cp "${desc}" /output/
		done
		for debian in $(find /sources -maxdepth 1 -name '*.debian.tar.*'); do
			su - builder -c cp "${debian}" /output/
		done
		for orig in $(find /sources -maxdepth 1 -name '*.orig.tar.gz'); do
			su - builder -c cp "${orig}" /output/
		done
	else
		dpkg -i $BUILDER_HOME/*.deb
		mv $BUILDER_HOME/*.deb /output/
		chown builder:builder /output/*.deb
	fi

	popd
done

if [ $DOCKER_DEBUILD_SIGN -eq 1 ]; then
	if [ -n "${GPG_AGENT_INFO}" ]; then
		su - builder -c kill $(echo ${GPG_AGENT_INFO} | cut -d':' -f 2) >/dev/null 2>&1
	fi
fi
