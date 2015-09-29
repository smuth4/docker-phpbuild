## docker-phpbuild
Build php inside a Docker container

### Usage

```
docker build -t phpbuild .
docker -d -v "$(pwd)":/packages phpbuild
```

This will generate the finished RPMs in the current directory.

### Details

PHP is compiled against CentOS 6 libraries, with the flags taken from the CentOS 6 default PHP installation, and turned in RPMs via FPM. An effort has also been made to replicate the package structure CentOS uses for php.

### Caveats

The build script installs PHP system-wide, it should not be run on a "snowflake" machine.