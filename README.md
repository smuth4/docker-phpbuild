## docker-phpbuild
Build php inside a Docker container

### Usage

```
docker build --no-cache -t phpbuild .
docker -d -v "$(pwd)":/packages phpbuild
```

This will generate the finished RPMs in the current directory.

### Details

* PHP is compiled against CentOS 6 libraries, with the flags taken from the CentOS 6 default PHP installation, and turned in RPMs via FPM. An effort has also been made to replicate the package structure CentOS uses for PHP.
* While the `provides` and `depends` parts of the build process are exactly the same as CentOS, the list of files often don't include all the documentation, in the interest of time
* Several files (such as `/etc/php.ini`) don't get generated with the build process, so they were stolen directly from recent installations of PHP on CentOS 6 VMs.

### Caveats

The build script installs PHP system-wide, it should not be run on a "special snowflake" machine.
TODO: Change this.

Development packages are cached in intermediate layers to speed up build testing, hence the '--no-cache' when actually building the image.