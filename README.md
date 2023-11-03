# Distribution system for a Federated EGA node

This repository contains the code part of the [LocalEGA software stack](https://github.com/EGA-archive/LocalEGA).  
It allows the distribution of Crypt4GH-encrypted files.


The required packages are:
* libfuse 3
* OpenSSL
* libpq
* glib-2.0
* Compilation tools: make cmake gcc git autoconf ...
* patch
* PAM

On Debian/Ubuntu, you can install the dependencies with:
```bash
    apt-get update && \
    apt-get install -y --no-install-recommends \
            ca-certificates pkg-config git gcc cmake make automake autoconf patch \
            libssl-dev libpq-dev libpam0g-dev libglib2.0-dev libfuse3-dev meson ninja
```

You need to install the following components:

* the [distribution file system](src/fuse) (to output Crypt4GH files)
* the [NSS module](src/nss) (to find users)
* the [PAM modules](src/pam) (to create the user's homedirectory and automount its file system)
* [patch and deploy the SFTP server](src/openssh)


Once installed, you can extend the Vault database with [functions used
by the file system](db). They allow the fuse filesystem to be smaller,
as most string manipulation are done in the Postgres database itself.
