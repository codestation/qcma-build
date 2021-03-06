#!/bin/bash

set -ex

chown builder:builder /output
su - builder -c "cp -r /sources/* $BUILDER_HOME"

for i; do (
  # install deps
  zypper -n install $(rpmspec -P $BUILDER_HOME/rpmbuild/SPECS/${i}.spec | grep BuildRequires | awk '{print $2}')
  # build package
  su - builder -c "rpmbuild -bb $BUILDER_HOME/rpmbuild/SPECS/${i}.spec"

  for rpmname in $(rpm --specfile $BUILDER_HOME/rpmbuild/SPECS/${i}.spec); do
    if [ -f $BUILDER_HOME/rpmbuild/RPMS/x86_64/${rpmname}.rpm ]; then
      # copy rpms outside docker container
      su - builder -c "cp $BUILDER_HOME/rpmbuild/RPMS/x86_64/${rpmname}.rpm /output/"
      # install rpms
      zypper -n install $BUILDER_HOME/rpmbuild/RPMS/x86_64/${rpmname}.rpm
    fi
  done
)
done
