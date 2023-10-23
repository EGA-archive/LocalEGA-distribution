# Distribution system for a Federated EGA node


This contains...


## Required packages

* libfuse 3
* openssl
* libpq
* glib-2.0
* make cmake gcc git autoconf ...
* patch

```bash
    apt-get update && \
    apt-get install -y --no-install-recommends \
            ca-certificates pkg-config git gcc cmake make automake autoconf patch \
            libssl-dev libpq-dev libpam0g-dev libglib2.0-dev libfuse3-dev
```


## Installation

You need to install the following components:

* the [distribution file system](src/fuse) (to output Crypt4GH files)
* the [NSS module](src/nss) (to find users)
* the [PAM modules](src/pam) (to create the user's homedirectory and automount its file system)
* [patch and deploy the SFTP server](src/openssh)

