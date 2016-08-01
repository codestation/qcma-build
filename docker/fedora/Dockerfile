FROM fedora:24
MAINTAINER codestation codestation404@gmail.com

VOLUME ["/var/cache/dnf"]

RUN rpm --import "http://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-fedora-24"
RUN dnf -y install http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-24.noarch.rpm
RUN dnf -y update rpmfusion\*
RUN dnf -y groupinstall "Development Tools"
RUN dnf -y install fedora-packager dnf-plugins-core
RUN echo 'keepcache=true' >> /etc/dnf/dnf.conf

VOLUME ["/sources"]
VOLUME ["/output"]

ENV BUILDER_HOME=/home/builder

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ARG user=builder
ARG group=builder
ARG uid=1000
ARG gid=1000

RUN groupadd -g ${gid} ${group} \
    && useradd -d "$BUILDER_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

RUN echo "%_topdir $BUILDER_HOME/rpmbuild" > $BUILDER_HOME/.rpmmacros

WORKDIR $BUILDER_HOME

ENTRYPOINT ["/entrypoint.sh"]
