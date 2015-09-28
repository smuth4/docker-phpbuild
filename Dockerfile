FROM centos:6

VOLUME /packages

RUN mkdir /tmp/php-build

COPY build.sh /tmp/php-build/build.sh
COPY php.ini /etc/php.ini

CMD /tmp/php-build/build.sh
