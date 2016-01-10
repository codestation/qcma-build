FROM fedora:23
MAINTAINER codestation codestation404@gmail.com

VOLUME ["/var/cache/dnf"]

RUN rpm --import "http://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-fedora-23"
RUN dnf -y install http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-23.noarch.rpm
RUN dnf -y update rpmfusion\*
RUN dnf -y groupinstall "Development Tools"
RUN dnf -y install fedora-packager dnf-plugins-core
RUN echo 'keepcache=true' >> /etc/dnf/dnf.conf

VOLUME ["/target"]

RUN echo "%_topdir /root/rpmbuild" > /root/.rpmmacros
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
