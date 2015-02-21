## Docker build scripts.

These scripts builds Qcma for several distros using Docker containers. Install Docker before running any scripts.

## Create rpmbuild/debuild containers

```
./create.sh
```

## Check supported distros/versions

``` sh
./build.sh
```

## Build package for a distro/version

``` sh
./build.sh ubuntu:utopic
```

## Configuration options in build.sh

* `SOURCES_ONLY`: set to 1 to only generate .changes files.
* `SIGN_SOURCES`: if set to 1 the packages will be signed with a gpg key.
* `PACKAGE_REVISION`: increment when another build with the same version is needed.
* `PPA_NAMING`: use ubuntu ppa naming for changelog/package.
