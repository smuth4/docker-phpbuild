FROM centos:6

RUN mkdir /tmp/php-build

COPY build.sh /tmp/php-build/build.sh
COPY php.ini /etc/php.ini

CMD /bin/bash
