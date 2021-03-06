#!/bin/bash -x
# A custom build script for PHP
#
# For the most part, the configure flags, the --provides flags, the --depends flags, and the file lists are borrowed directly from
# the official CentOS RPMs. Several documentation folders have been skipped for the sake of speed, but it should otherwise be a
# drop-in replacement for PHP on CentOS 6
#
# The following command was used to generate the --provides and --depends flags from a system with the package installed:
# export PK=php-<name>; rpm -q --provides "$PK" | awk '{ print " --provides \""$1"\" \\"}'; rpm -qR "$PK" | awk '{ print " --depends \""$1"\" \\"}';

## Variables

VERSION=5.3.29
ARCH=x86_64
PACKAGE_DIR=/packages

export EXTENSION_DIR=/usr/lib64/php/modules
TEMPDIR="$(mktemp -d)"

## Utility functions
function createmoduleini() {
    mkdir -p /etc/php.d
    for name; do
        echo -e "; Enable $name extension module\nextension=$name.so" > /etc/php.d/"$name".ini
    done
}

## Add CentOS-specific files/directories

mkdir -p /var/lib/php/session/

cat > /etc/rpm/macros.php <<EOF
#
# Interface versions exposed by PHP:
#
%php_core_api 20090626
%php_zend_api 20090626
%php_pdo_api  20080721
%php_version  5.3.29

%php_extdir    %{_libdir}/php/modules
%php_inidir    %{_sysconfdir}/php.d
%php_incldir   %{_includedir}/php
%__php         %{_bindir}/php
EOF

mkdir -p /etc/httpd/conf.d/
cat > /etc/httpd/conf.d/php.conf <<EOF
#
# PHP is an HTML-embedded scripting language which attempts to make it
# easy for developers to write dynamically generated webpages.
#
<IfModule prefork.c>
  LoadModule php5_module modules/libphp5.so
</IfModule>
<IfModule worker.c>
  LoadModule php5_module modules/libphp5-zts.so
</IfModule>

#
# Cause the PHP interpreter to handle files with a .php extension.
#
AddHandler php5-script .php
AddType text/html .php

#
# Add index.php to the list of files that will be served as directory
# indexes.
#
DirectoryIndex index.php

#
# Uncomment the following line to allow PHP to pretty-print .phps
# files as PHP source code:
#
#AddType application/x-httpd-php-source .phps
EOF

cd "$TEMPDIR"

## Fetch & build

tarball=php-"${VERSION}".tar.gz
wget http://us1.php.net/get/php-"${VERSION}".tar.gz/from/this/mirror -O "$tarball"

echo "Extracting $tarball"
tar xzf "$tarball"

cd php-"${VERSION}"

## Configure flags
# recode support was stripped out due to incompatibility with IMAP and MySQL
# --with-system-tzdata wasn't recognized, and appears to be deprecated, so it was stripped out
# --enable-fastcgi is enabled automatically when CGI in general is enabled, so it was removed as well
configure_flags="--build=x86_64-redhat-linux-gnu --host=x86_64-redhat-linux-gnu --target=x86_64-redhat-linux-gnu \
    --program-prefix= \
    --prefix=/usr --exec-prefix=/usr \
    --bindir=/usr/bin --sbindir=/usr/sbin \
    --sysconfdir=/etc \
    --datadir=/usr/share \
    --includedir=/usr/include \
    --libdir=/usr/lib64 --libexecdir=/usr/libexec \
    --localstatedir=/var --sharedstatedir=/var/lib \
    --mandir=/usr/share/man --infodir=/usr/share/info \
    --cache-file=../config.cache --with-libdir=lib64 \
    --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d \
    --disable-debug \
    --with-pic \
    --disable-rpath \
    --without-pear \
    --with-bz2 \
    --with-exec-dir=/usr/bin \
    --with-freetype-dir=/usr \
    --with-png-dir=/usr \
    --with-xpm-dir=/usr \
    --enable-gd-native-ttf \
    --with-t1lib=/usr \
    --without-gdbm \
    --with-gettext \
    --with-gmp \
    --with-iconv \
    --with-jpeg-dir=/usr \
    --with-openssl \
    --with-zlib \
    --with-layout=GNU \
    --enable-exif \
    --enable-ftp \
    --enable-magic-quotes \
    --enable-sockets \
    --with-kerberos \
    --enable-ucd-snmp-hack \
    --enable-shmop \
    --enable-calendar \
    --with-libxml-dir=/usr \
    --enable-xml \
    --with-mhash \
    --libdir=/usr/lib64/php \
    --enable-pcntl \
    --with-imap=shared \
    --with-imap-ssl \
    --enable-mbstring=shared \
    --enable-mbregex \
    --with-gd=shared \
    --enable-bcmath=shared \
    --enable-dba=shared \
    --with-db4=/usr \
    --with-xmlrpc=shared \
    --with-ldap=shared \
    --with-ldap-sasl \
    --enable-mysqlnd=shared \
    --with-mysql=shared,mysqlnd \
    --with-mysqli=shared,mysqlnd \
    --with-mysql-sock=/var/lib/mysql/mysql.sock \
    --enable-dom=shared \
    --with-pgsql=shared \
    --enable-wddx=shared \
    --with-snmp=shared,/usr \
    --enable-soap=shared \
    --with-xsl=shared,/usr \
    --enable-xmlreader=shared \
    --enable-xmlwriter=shared \
    --with-curl=shared,/usr \
    --enable-cgi \
    --enable-pdo=shared \
    --with-pdo-odbc=shared,unixODBC,/usr \
    --with-pdo-mysql=shared,mysqlnd \
    --with-pdo-pgsql=shared,/usr \
    --with-pdo-sqlite=shared,/usr \
    --with-pdo-dblib=shared,/usr \
    --with-sqlite3=shared,/usr \
    --with-sqlite=shared,/usr \
    --enable-json=shared \
    --enable-zip=shared \
    --without-readline \
    --with-libedit \
    --with-pspell=shared \
    --enable-phar=shared \
    --with-mcrypt=shared,/usr \
    --with-tidy=shared,/usr \
    --with-mssql=shared,/usr \
    --enable-sysvmsg=shared \
    --enable-sysvshm=shared \
    --enable-sysvsem=shared \
    --enable-posix=shared \
    --with-unixODBC=shared,/usr \
    --enable-fileinfo=shared \
    --enable-intl=shared \
    --with-icu-dir=/usr \
    --with-enchant=shared,/usr"

./configure $configure_flags

make 
make install

# Apache support disables building php-cgi binary, so we have to build
# it again in order to have our cake and eat it too
./configure $configure_flags --with-apxs2=shared,/usr --with-apxs2=/usr/sbin/apxs

make
make install

## Package

mkdir -p "$PACKAGE_DIR"

cd /

# php-pdo
createmoduleini pdo pdo_sqlite sqlite3
fpm -f -s dir -t rpm \
    -n php-pdo -v "${VERSION}" \
    -p "$PACKAGE_DIR"/php-pdo-"${VERSION}"."${ARCH}".rpm \
    --depends "config(php-pdo)" \
    --depends "libc.so.6()(64bit)" \
    --depends "libc.so.6(GLIBC_2.2.5)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.4)(64bit)" \
    --depends "librt.so.1()(64bit)" \
    --depends "libsqlite3.so.0()(64bit)" \
    --depends "php-common(x86-64)" \
    --depends "rpmlib(CompressedFileNames)" \
    --depends "rpmlib(FileDigests)" \
    --depends "rpmlib(PayloadFilesHavePrefix)" \
    --depends "rpmlib(VersionedDependencies)" \
    --depends "rtld(GNU_HASH)" \
    --depends "rpmlib(PayloadIsXz)" \
    --provides "config(php-pdo)" \
    --provides "pdo.so()(64bit)" \
    --provides "pdo_sqlite.so()(64bit)" \
    --provides "php-pdo-abi" \
    --provides "php-pdo_sqlite" \
    --provides "php-sqlite3" \
    --provides "sqlite3.so()(64bit)" \
    --provides "php-pdo" \
    --provides "php-pdo(x86-64)" \
    /etc/php.d/pdo.ini /etc/php.d/pdo_sqlite.ini  /etc/php.d/sqlite3.ini /usr/lib64/php/modules/pdo_sqlite.so /usr/lib64/php/modules/pdo.so /usr/lib64/php/modules/sqlite3.so

# php
chown root:48 /var/lib/php/session/ # 49 = apache GID
chmod 770 /var/lib/php/session/

fpm -f -s dir -t rpm -n php \
    -p "$PACKAGE_DIR"/php-"${VERSION}"."${ARCH}".rpm -v "${VERSION}" \
    --rpm-use-file-permissions \
    --provides "config(php)" \
    --provides "libphp5.so()(64bit)" \
    --provides "mod_php" \
    --provides "php" \
    --provides "php(x86-64)" \
    --depends "config(php)" \
    --depends "httpd" \
    --depends "httpd-mmn" \
    --depends "libbz2.so.1()(64bit)" \
    --depends "libc.so.6()(64bit)" \
    --depends "libc.so.6(GLIBC_2.11)(64bit)" \
    --depends "libc.so.6(GLIBC_2.2.5)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.7)(64bit)" \
    --depends "libc.so.6(GLIBC_2.8)(64bit)" \
    --depends "libcom_err.so.2()(64bit)" \
    --depends "libcrypt.so.1()(64bit)" \
    --depends "libcrypto.so.10()(64bit)" \
    --depends "libcrypto.so.10(OPENSSL_1.0.1)(64bit)" \
    --depends "libcrypto.so.10(libcrypto.so.10)(64bit)" \
    --depends "libdl.so.2()(64bit)" \
    --depends "libdl.so.2(GLIBC_2.2.5)(64bit)" \
    --depends "libgmp.so.3()(64bit)" \
    --depends "libgssapi_krb5.so.2()(64bit)" \
    --depends "libk5crypto.so.3()(64bit)" \
    --depends "libkrb5.so.3()(64bit)" \
    --depends "libm.so.6()(64bit)" \
    --depends "libm.so.6(GLIBC_2.2.5)(64bit)" \
    --depends "libnsl.so.1()(64bit)" \
    --depends "libpcre.so.0()(64bit)" \
    --depends "libssl.so.10()(64bit)" \
    --depends "libssl.so.10(libssl.so.10)(64bit)" \
    --depends "libxml2.so.2()(64bit)" \
    --depends "libxml2.so.2(LIBXML2_2.4.30)(64bit)" \
    --depends "libxml2.so.2(LIBXML2_2.5.2)(64bit)" \
    --depends "libxml2.so.2(LIBXML2_2.6.0)(64bit)" \
    --depends "libxml2.so.2(LIBXML2_2.6.11)(64bit)" \
    --depends "libxml2.so.2(LIBXML2_2.6.5)(64bit)" \
    --depends "libz.so.1()(64bit)" \
    --depends "php-cli(x86-64)" \
    --depends "php-common(x86-64)" \
    --depends "rpmlib(CompressedFileNames)" \
    --depends "rpmlib(FileDigests)" \
    --depends "rpmlib(PayloadFilesHavePrefix)" \
    --depends "rpmlib(VersionedDependencies)" \
    --depends "rtld(GNU_HASH)" \
    --depends "rpmlib(PayloadIsXz)" \
    /etc/httpd/conf.d/php.conf /usr/lib64/httpd/modules/libphp5.so /var/lib/php/session/

# php-cli
fpm -f -s dir -t rpm -n php-cli \
    -p "$PACKAGE_DIR"/php-cli-"${VERSION}"."${ARCH}".rpm -v "${VERSION}" \
    --provides "php-cgi" \
    --provides "php-pcntl" \
    --provides "php-readline" \
    --provides "php-cli" \
    --provides "php-cli(x86-64)" \
    --depends "/usr/bin/php" \
    --depends "libbz2.so.1()(64bit)" \
    --depends "libc.so.6()(64bit)" \
    --depends "libc.so.6(GLIBC_2.11)(64bit)" \
    --depends "libc.so.6(GLIBC_2.2.5)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.7)(64bit)" \
    --depends "libc.so.6(GLIBC_2.8)(64bit)" \
    --depends "libcom_err.so.2()(64bit)" \
    --depends "libcrypt.so.1()(64bit)" \
    --depends "libcrypto.so.10()(64bit)" \
    --depends "libcrypto.so.10(OPENSSL_1.0.1)(64bit)" \
    --depends "libcrypto.so.10(libcrypto.so.10)(64bit)" \
    --depends "libdl.so.2()(64bit)" \
    --depends "libdl.so.2(GLIBC_2.2.5)(64bit)" \
    --depends "libedit.so.0()(64bit)" \
    --depends "libgmp.so.3()(64bit)" \
    --depends "libgssapi_krb5.so.2()(64bit)" \
    --depends "libk5crypto.so.3()(64bit)" \
    --depends "libkrb5.so.3()(64bit)" \
    --depends "libm.so.6()(64bit)" \
    --depends "libm.so.6(GLIBC_2.2.5)(64bit)" \
    --depends "libncurses.so.5()(64bit)" \
    --depends "libnsl.so.1()(64bit)" \
    --depends "libpcre.so.0()(64bit)" \
    --depends "libresolv.so.2()(64bit)" \
    --depends "libresolv.so.2(GLIBC_2.2.5)(64bit)" \
    --depends "libssl.so.10()(64bit)" \
    --depends "libssl.so.10(libssl.so.10)(64bit)" \
    --depends "libxml2.so.2()(64bit)" \
    --depends "libxml2.so.2(LIBXML2_2.4.30)(64bit)" \
    --depends "libxml2.so.2(LIBXML2_2.5.2)(64bit)" \
    --depends "libxml2.so.2(LIBXML2_2.6.0)(64bit)" \
    --depends "libxml2.so.2(LIBXML2_2.6.11)(64bit)" \
    --depends "libxml2.so.2(LIBXML2_2.6.5)(64bit)" \
    --depends "libz.so.1()(64bit)" \
    --depends "php-common(x86-64)" \
    --depends "rpmlib(CompressedFileNames)" \
    --depends "rpmlib(FileDigests)" \
    --depends "rpmlib(PayloadFilesHavePrefix)" \
    --depends "rpmlib(VersionedDependencies)" \
    --depends "rtld(GNU_HASH)" \
    --depends "rpmlib(PayloadIsXz)" \
    /usr/bin/phar /usr/bin/phar.phar /usr/bin/php /usr/bin/php-cgi /usr/share/man/man1/php.1

# php-common
createmoduleini curl fileinfo json phar zip
fpm -f -s dir -t rpm -n php-common -p "$PACKAGE_DIR"/php-common-"${VERSION}"."${ARCH}".rpm -v "${VERSION}" \
    --provides "config(php-common)" \
    --provides "curl.so()(64bit)" \
    --provides "fileinfo.so()(64bit)" \
    --provides "json.so()(64bit)" \
    --provides "phar.so()(64bit)" \
    --provides "php(api)" \
    --provides "php(language)" \
    --provides "php(zend-abi)" \
    --provides "php-api" \
    --provides "php-bz2" \
    --provides "php-calendar" \
    --provides "php-core" \
    --provides "php-ctype" \
    --provides "php-curl" \
    --provides "php-date" \
    --provides "php-ereg" \
    --provides "php-exif" \
    --provides "php-fileinfo" \
    --provides "php-filter" \
    --provides "php-ftp" \
    --provides "php-gettext" \
    --provides "php-gmp" \
    --provides "php-hash" \
    --provides "php-iconv" \
    --provides "php-json" \
    --provides "php-libxml" \
    --provides "php-openssl" \
    --provides "php-pcre" \
    --provides "php-pecl(Fileinfo)" \
    --provides "php-pecl(json)" \
    --provides "php-pecl(phar)" \
    --provides "php-pecl(zip)" \
    --provides "php-pecl-Fileinfo" \
    --provides "php-pecl-json" \
    --provides "php-pecl-phar" \
    --provides "php-pecl-zip" \
    --provides "php-phar" \
    --provides "php-reflection" \
    --provides "php-session" \
    --provides "php-shmop" \
    --provides "php-simplexml" \
    --provides "php-sockets" \
    --provides "php-spl" \
    --provides "php-standard" \
    --provides "php-tokenizer" \
    --provides "php-zend-abi" \
    --provides "php-zip" \
    --provides "php-zlib" \
    --provides "zip.so()(64bit)" \
    --provides "php-common" \
    --provides "php-common(x86-64)" \
    --depends "config(php-common)" \
    --depends "libc.so.6()(64bit)" \
    --depends "libc.so.6(GLIBC_2.2.5)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.7)(64bit)" \
    --depends "libc.so.6(GLIBC_2.8)(64bit)" \
    --depends "libcurl.so.4()(64bit)" \
    --depends "libz.so.1()(64bit)" \
    --depends "rpmlib(CompressedFileNames)" \
    --depends "rpmlib(FileDigests)" \
    --depends "rpmlib(PayloadFilesHavePrefix)" \
    --depends "rpmlib(VersionedDependencies)" \
    --depends "rtld(GNU_HASH)" \
    --depends "rpmlib(PayloadIsXz)" \
    /etc/php.d/curl.ini /etc/php.d/fileinfo.ini /etc/php.d/json.ini /etc/php.d/phar.ini /etc/php.d/zip.ini /etc/php.ini \
    /usr/lib64/php/modules/curl.so /usr/lib64/php/modules/fileinfo.so /usr/lib64/php/modules/json.so \
    /usr/lib64/php/modules/phar.so /usr/lib64/php/modules/zip.so var/lib/php

# php-devel
fpm -s dir -t rpm -n php-devel -p "$PACKAGE_DIR"/php-devel-"${VERSION}"."${ARCH}".rpm -v "${VERSION}" -f \
    --provides "config(php-devel)" \
    --provides "php-devel" \
    --provides "php-devel(x86-64)" \
    --depends "/bin/sh" \
    --depends "autoconf" \
    --depends "automake" \
    --depends "config(php-devel)" \
    --depends "php(x86-64)" \
    --depends "rpmlib(CompressedFileNames)" \
    --depends "rpmlib(FileDigests)" \
    --depends "rpmlib(PayloadFilesHavePrefix)" \
    --depends "rpmlib(PayloadIsXz)" \
    /etc/rpm/macros.php /usr/bin/php-config /usr/bin/phpize usr/lib64/php/build usr/include/php

# php-gd
createmoduleini gd
fpm -n php-gd -s dir -t rpm -p "$PACKAGE_DIR"/php-gd-"${VERSION}"."${ARCH}".rpm -v "${VERSION}" -f \
    --provides "config(php-gd)" \
    --provides "gd.so()(64bit)" \
    --provides "php-gd" \
    --provides "php-gd(x86-64)" \
    --depends "config(php-gd)" \
    --depends "libX11.so.6()(64bit)" \
    --depends "libXpm.so.4()(64bit)" \
    --depends "libc.so.6()(64bit)" \
    --depends "libc.so.6(GLIBC_2.11)(64bit)" \
    --depends "libc.so.6(GLIBC_2.2.5)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.7)(64bit)" \
    --depends "libfreetype.so.6()(64bit)" \
    --depends "libjpeg.so.62()(64bit)" \
    --depends "libjpeg.so.62(LIBJPEG_6.2)(64bit)" \
    --depends "libpng12.so.0()(64bit)" \
    --depends "libpng12.so.0(PNG12_0)(64bit)" \
    --depends "libz.so.1()(64bit)" \
    --depends "php-common(x86-64)" \
    --depends "rpmlib(CompressedFileNames)" \
    --depends "rpmlib(FileDigests)" \
    --depends "rpmlib(PayloadFilesHavePrefix)" \
    --depends "rtld(GNU_HASH)" \
    --depends "rpmlib(PayloadIsXz)" \
    /etc/php.d/gd.ini /usr/lib64/php/modules/gd.so

# php-mcrypt
createmoduleini mcrypt
fpm -f -s dir -t rpm -n php-mcrypt -v "${VERSION}" -p "$PACKAGE_DIR"/php-mcrypt-"${VERSION}"."${ARCH}".rpm \
    --provides "config(php-mcrypt)" \
    --provides "mcrypt.so()(64bit)" \
    --provides "php-mcrypt" \
    --provides "php-mcrypt(x86-64)" \
    --depends "config(php-mcrypt)" \
    --depends "libc.so.6()(64bit)" \
    --depends "libc.so.6(GLIBC_2.2.5)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.4)(64bit)" \
    --depends "libmcrypt.so.4()(64bit)" \
    --depends "php(api)" \
    --depends "php(zend-abi)" \
    --depends "rpmlib(CompressedFileNames)" \
    --depends "rpmlib(FileDigests)" \
    --depends "rpmlib(PayloadFilesHavePrefix)" \
    --depends "rtld(GNU_HASH)" \
    --depends "rpmlib(PayloadIsXz)" \
    /etc/php.d/mcrypt.ini /usr/lib64/php/modules/mcrypt.so

# php-mysql
createmoduleini mysql mysqli pdo_mysql mysqlnd
fpm -f -s dir -t rpm -n php-mysql -v "${VERSION}" -p "$PACKAGE_DIR"/php-mysql-"${VERSION}"."${ARCH}".rpm \
    --provides "config(php-mysql)" \
    --provides "mysql.so()(64bit)" \
    --provides "mysqli.so()(64bit)" \
    --provides "pdo_mysql.so()(64bit)" \
    --provides "php-mysqli" \
    --provides "php-pdo_mysql" \
    --provides "php_database" \
    --provides "php-mysql" \
    --provides "php-mysql(x86-64)" \
    --depends "config(php-mysql)" \
    --depends "libc.so.6()(64bit)" \
    --depends "libc.so.6(GLIBC_2.2.5)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.4)(64bit)" \
    --depends "libcrypt.so.1()(64bit)" \
    --depends "libcrypto.so.10()(64bit)" \
    --depends "libm.so.6()(64bit)" \
    --depends "libmysqlclient.so.16()(64bit)" \
    --depends "libmysqlclient.so.16(libmysqlclient_16)(64bit)" \
    --depends "libnsl.so.1()(64bit)" \
    --depends "libssl.so.10()(64bit)" \
    --depends "libz.so.1()(64bit)" \
    --depends "libt1.so.5()(64bit)" \
    --depends "php-common(x86-64)" \
    --depends "php-pdo(x86-64)" \
    --depends "rpmlib(CompressedFileNames)" \
    --depends "rpmlib(FileDigests)" \
    --depends "rpmlib(PayloadFilesHavePrefix)" \
    --depends "rtld(GNU_HASH)" \
    --depends "rpmlib(PayloadIsXz)" \
    /etc/php.d/mysql.ini /etc/php.d/mysqli.ini /etc/php.d/pdo_mysql.ini /etc/php.d/mysqlnd.ini \
    /usr/lib64/php/modules/mysql.so /usr/lib64/php/modules/mysqli.so /usr/lib64/php/modules/pdo_mysql.so /usr/lib64/php/modules/mysqlnd.so

# php-bcmath
createmoduleini bcmath
fpm -f -s dir -t rpm -n php-bcmath -v "${VERSION}" -p "$PACKAGE_DIR"/php-bcmath-"${VERSION}"."${ARCH}".rpm \
    --provides "bcmath.so()(64bit)" \
    --provides "config(php-bcmath)" \
    --provides "php-bcmath" \
    --provides "php-bcmath(x86-64)" \
    --depends "config(php-bcmath)" \
    --depends "libc.so.6()(64bit)" \
    --depends "libc.so.6(GLIBC_2.2.5)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.4)(64bit)" \
    --depends "php-common(x86-64)" \
    --depends "rpmlib(CompressedFileNames)" \
    --depends "rpmlib(FileDigests)" \
    --depends "rpmlib(PayloadFilesHavePrefix)" \
    --depends "rtld(GNU_HASH)" \
    --depends "rpmlib(PayloadIsXz)" \
    /etc/php.d/bcmath.ini /usr/lib64/php/modules/bcmath.so

# php-mbstring
createmoduleini mbstring
fpm -f -s dir -t rpm -n php-mbstring -v "${VERSION}" -p "$PACKAGE_DIR"/php-mbstring-"${VERSION}"."${ARCH}".rpm \
    --provides "config(php-mbstring)" \
    --provides "mbstring.so()(64bit)" \
    --provides "php-mbstring" \
    --provides "php-mbstring(x86-64)" \
    --depends "config(php-mbstring)" \
    --depends "libc.so.6()(64bit)" \
    --depends "libc.so.6(GLIBC_2.2.5)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3)(64bit)" \
    --depends "libc.so.6(GLIBC_2.3.4)(64bit)" \
    --depends "libc.so.6(GLIBC_2.4)(64bit)" \
    --depends "php-common(x86-64)" \
    --depends "rpmlib(CompressedFileNames)" \
    --depends "rpmlib(FileDigests)" \
    --depends "rpmlib(PayloadFilesHavePrefix)" \
    --depends "rtld(GNU_HASH)" \
    --depends "rpmlib(PayloadIsXz)" \
    /etc/php.d/mbstring.ini /usr/lib64/php/modules/mbstring.so
    
echo "Packages are available in $PACKAGE_DIR"
