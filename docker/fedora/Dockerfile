FROM fedora:21
MAINTAINER codestation codestation404@gmail.com

VOLUME ["/var/cache/yum"]

RUN yum -y install --nogpgcheck http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-stable.noarch.rpm
RUN yum -y update rpmfusion\*
RUN yum -y groupinstall "Development Tools"
RUN yum -y install fedora-packager yum-utils
RUN sed -i 's/keepcache=0/keepcache=1/' /etc/yum.conf

VOLUME ["/target"]

RUN echo "%_topdir /root/rpmbuild" > /root/.rpmmacros
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
