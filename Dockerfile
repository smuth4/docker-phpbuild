FROM centos:6

RUN mkdir /tmp/php-build

COPY build.sh /tmp/php-build/build.sh

CMD /bin/bash
