FROM ubuntu:vivid
MAINTAINER codestation404@gmail.com

RUN apt-get update
RUN apt-get --no-install-recommends --yes install build-essential fakeroot devscripts equivs
RUN apt-get --no-install-recommends --yes install pinentry-curses gnupg-agent
RUN rm -f /etc/apt/apt.conf.d/docker-clean

VOLUME ["/var/cache/apt"]
VOLUME ["/target"]

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
