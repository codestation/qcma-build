#!/bin/bash

set -ex

cd /target

cp -r /target /root/rpmbuild
chown -R root:root /root/rpmbuild
cd /root/rpmbuild

for i; do (
	# install deps
	dnf builddep -y SPECS/${i}.spec
	# build package
	rpmbuild -bb SPECS/${i}.spec

	mkdir -p /target/output
	for rpmname in $(rpm --specfile SPECS/${i}.spec); do
		if [ -f RPMS/x86_64/${rpmname}.rpm ]; then
			# copy rpms outside docker container
			cp RPMS/x86_64/${rpmname}.rpm /target/output/
			# install rpms
			dnf -y install RPMS/x86_64/${rpmname}.rpm
		fi
	done
	chmod -R o+w /target/
)
done

cd /root
# remove build directory
rm -rf /root/rpmbuild
