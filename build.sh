#!/bin/bash

# Variables
VERSION=5.3.29

mkdir -p /tmp/php-build 
cd /tmp/php-build

yum install wget tar -y
wget http://us1.php.net/get/php-"${VERSION}".tar.gz/from/this/mirror -O php-"${VERSION}".tar.gz 

tar xzvf php-"${VERSION}".tar.gz

cd php-"${VERSION}"

sudo yum install #list of pac${VERSION}

./configure  --build=x86_64-redhat-linux-gnu --host=x86_64-redhat-linux-gnu --target=x86_64-redhat-linux-gnu \
--program-prefix= --prefix=/usr --exec-prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc \
--datadir=/usr/share --includedir=/usr/include --libdir=/usr/lib64 --libexecdir=/usr/libexec --localstatedir=/var \
--sharedstatedir=/var/lib --mandir=/usr/share/man --infodir=/usr/share/info --cache-file=../config.cache --with-libdir=lib64 \
--with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --disable-debug \
--with-pic --disable-rpath --without-pear --with-bz2 --with-exec-dir=/usr/bin --with-freetype-dir=/usr --with-png-dir=/usr --with-xpm-dir=/usr \
--enable-gd-native-ttf --with-t1lib=/usr --without-gdbm --with-gettext --with-gmp --with-iconv --with-jpeg-dir=/usr \
--with-openssl --with-zlib --with-layout=GNU --enable-exif --enable-ftp --enable-magic-quotes --enable-sockets \
--with-kerberos --enable-ucd-snmp-hack --enable-shmop --enable-calendar --with-libxml-dir=/usr --enable-xml --with-system-tzdata \
--with-mhash --enable-force-cgi-redirect --libdir=/usr/lib64/php --enable-pcntl --with-imap=shared --with-imap-ssl --enable-mbstring=shared \
--enable-mbregex --with-gd=shared --enable-bcmath=shared --enable-dba=shared --with-db4=/usr --with-xmlrpc=shared --with-ldap=shared \
--with-ldap-sasl --enable-mysqlnd=shared --with-mysql=shared,mysqlnd --with-mysqli=shared,mysqlnd --with-mysql-sock=/var/lib/mysql/mysql.sock \
--enable-dom=shared --with-pgsql=shared --enable-wddx=shared --with-snmp=shared,/usr --enable-soap=shared --with-xsl=shared,/usr \
--enable-xmlreader=shared --enable-xmlwriter=shared --with-curl=shared,/usr --enable-fastcgi --enable-pdo=shared \
--with-pdo-odbc=shared,unixODBC,/usr --with-pdo-mysql=shared,mysqlnd --with-pdo-pgsql=shared,/usr --with-pdo-sqlite=shared,/usr \
--with-pdo-dblib=shared,/usr --with-sqlite3=shared,/usr --with-sqlite=shared,/usr --enable-json=shared --enable-zip=shared --without-readline \
--with-libedit --with-pspell=shared --enable-phar=shared --with-mcrypt=shared,/usr --with-tidy=shared,/usr --with-mssql=shared,/usr \
--enable-sysvmsg=shared --enable-sysvshm=shared --enable-sysvsem=shared --enable-posix=shared --with-unixODBC=shared,/usr --enable-fileinfo=shared \
--enable-intl=shared --with-icu-dir=/usr --with-enchant=shared,/usr --with-recode=shared,/usr

make 

make install

fpm -s dir -t rpm -p php-pdo-"${VERSION}".rpm -n php-pdo -v "${VERSION}" \
-f /etc/php.d/pdo.ini /etc/php.d/pdo_sqlite.ini  /etc/php.d/sqlite3.ini \
   /usr/lib64/php/modules/pdo_sqlite.so /usr/lib64/php/modules/pdo.so /usr/lib64/php/modules/sqlite3.so \

