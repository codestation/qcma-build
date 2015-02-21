FROM opensuse:13.2
MAINTAINER codestation codestation404@gmail.com

RUN zypper addrepo -n packman-multimedia http://packman.inode.at/suse/openSUSE_13.2/Essentials/ packman-essentials
RUN zypper --gpg-auto-import-keys -n install gcc gcc-c++ rpm-build
RUN zypper modifyrepo -k --all

VOLUME ["/var/cache/zypp/"]
VOLUME ["/target"]

RUN echo "%_topdir /root/rpmbuild" > /root/.rpmmacros
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
