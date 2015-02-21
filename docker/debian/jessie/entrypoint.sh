#!/bin/sh

set -ex

cd /target
for debfile in $(find /target -maxdepth 1 -name '*.deb'); do
	rm -f "${debfile}"
done

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
	cp /target/secring.gpg ~/.gnupg
	cp /target/pubring.gpg ~/.gnupg
else
	DEBUILD_OPTS="-us -uc ${DEBUILD_OPTS}"
fi

for i; do (
	set -e
	cd "$i"

	if [ $DOCKER_SOURCE_ONLY -eq 1 ]; then
	        mkdir -p debian/patches
	        EDITOR=/bin/true dpkg-source -q --commit . $i.patch
	else
		mk-build-deps --install --remove --tool "apt-get --no-install-recommends --yes"
	fi

	eval "debuild $DOCKER_DEBUILD_OPTS $DEBUILD_OPTS"

	mkdir -p /target/output

	if [ $DOCKER_SOURCE_ONLY -eq 1 ]; then
		for changes in $(find /target -maxdepth 1 -name '*.changes'); do
			cp "${changes}" /target/output/
		done
		for desc in $(find /target -maxdepth 1 -name '*.dsc'); do
			cp "${desc}" /target/output/
		done
		for debian in $(find /target -maxdepth 1 -name '*.debian.tar.gz'); do
			cp "${debian}" /target/output/
		done
		for orig in $(find /target -maxdepth 1 -name '*.orig.tar.gz'); do
			cp "${orig}" /target/output/
		done
	else
		dpkg -i /target/*.deb
		mv /target/*.deb /target/output/
	fi
)
done

chmod -R o+w /target/

if [ $DOCKER_DEBUILD_SIGN -eq 1 ]; then
	if [ -n "${GPG_AGENT_INFO}" ]; then
		kill $(echo ${GPG_AGENT_INFO} | cut -d':' -f 2) >/dev/null 2>&1
	fi
fi
