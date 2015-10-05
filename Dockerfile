FROM centos:6

VOLUME /packages

RUN yum install -y wget tar gcc gcc-c++ rpm-build
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm

RUN yum install -y httpd-devel \
    mysql-devel \
    libmcrypt-devel \
    curl-devel \
    openssl-devel \
    libedit-devel \
    readline-devel \
    sqlite-devel \
    db4-devel \
    enchant-devel \
    libjpeg-devel \
    libpng-devel \
    libXpm-devel \
    freetype-devel \
    t1lib-devel \
    gmp-devel \
    libicu-devel \
    openldap-devel \
    unixODBC-devel \
    postgresql-devel \
    aspell-devel \
    net-snmp-devel \
    sqlite2-devel \
    libtidy-devel \
    libxml2-devel \
    bzip2-devel \
    httpd-devel \
    libc-client-devel \
    freetds-devel \
    libxslt-devel

RUN yum install -y ruby rubygems ruby-devel && gem install --no-rdoc --no-ri fpm



RUN mkdir /tmp/php-build

COPY build.sh /tmp/php-build/build.sh
COPY php.ini /etc/php.ini

CMD /tmp/php-build/build.sh
