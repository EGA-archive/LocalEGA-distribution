# Deploying the LocalEGA dual distribution system

## Preliminaries

We install all in /opt/LocalEGA

sudo mkdir -p /opt/LocalEGA/{bin,etc,lib,home}

apt install meson ninja libpq-dev
openssl 3

Install libfuse 3.16.2
uncomment `user_allow_other` in /usr/local/etc/fuse.conf


## Install the live distribution: crypt4gh-db.fs

autoreconf -i
./configure --prefix=/opt/LocalEGA
make
sudo make install

Create fs.conf for the crypt4gh-db.fs



## Install the NSS module

make 
sudo make install

echo '/opt/LocalEGA/lib' > /etc/ld.so.conf.d/LocalEGA.conf

sudo ldconfig -v | grep egafiles

In /etc/nsswitch.conf, add `egafiles` such as:

	passwd:         files egafiles systemd
	group:          files egafiles systemd
	shadow:         files egafiles

## Vault-DB extension

In the Vault database, load the SQL files:

	$ make load

Update the `nss.*` configurations in `pg.conf`

	# Create the landing directories for the NSS files
	$ docker-compose exec --user root vault-db chown postgres /etc/ega/nss
	$ docker-compose exec --user root vault-db chown postgres /etc/ega/authorized_keys
	
	# Call the NSS file creation
	$ make nss

And test it

	$ id jane
	uid=10001(jane) gid=20000(requesters) groups=20000(requesters)


