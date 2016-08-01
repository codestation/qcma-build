FROM ubuntu:trusty
MAINTAINER codestation404@gmail.com

RUN apt-get update
RUN apt-get --no-install-recommends --yes install build-essential fakeroot devscripts equivs
RUN apt-get --no-install-recommends --yes install pinentry-curses gnupg-agent
RUN rm -f /etc/apt/apt.conf.d/docker-clean

VOLUME ["/var/cache/apt"]
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

WORKDIR $BUILDER_HOME

ENTRYPOINT ["/entrypoint.sh"]
