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

For the distribution file system:

	pushd src/fuse
	autoreconf
	./configure
	make
	sudo make install
	popd

For the NSS module (aka finding users)

	pushd src/nss
	make
	sudo make install
	popd

For the PAM modules (aka automount)

	pushd src/pam
	make
	sudo make install
	popd

For the file system (aka fuse)

	pushd src/fuse
	autoreconf
	./configure
	make
	sudo make install
	popd

Finally, [patch and deploy the SFTP server](src/openssh/README.md)

