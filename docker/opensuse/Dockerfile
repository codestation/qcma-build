FROM opensuse:42.1
MAINTAINER codestation codestation404@gmail.com

RUN zypper ar -f -n packman http://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_42.1/ packman
RUN zypper --gpg-auto-import-keys -n install gcc gcc-c++ rpm-build
RUN zypper modifyrepo -k --all

VOLUME ["/var/cache/zypp/"]
VOLUME ["/sources"]
VOLUME ["/output"]

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV BUILDER_HOME=/home/builder

ARG user=builder
ARG group=builder
ARG uid=1000
ARG gid=1000

RUN groupadd -g ${gid} ${group} \
    && useradd -d "$BUILDER_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

RUN echo "%_topdir $BUILDER_HOME/rpmbuild" > $BUILDER_HOME/.rpmmacros

WORKDIR $BUILDER_HOME

ENTRYPOINT ["/entrypoint.sh"]
