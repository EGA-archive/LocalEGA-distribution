# Deploying the LocalEGA distribution system

## Preliminaries

On Debian/Ubuntu, you can install the dependencies with:
```bash
apt-get update && \
apt-get install -y --no-install-recommends \
            pkg-config git gcc make autoconf \
            meson ninja-build openssl \
            libssl-dev libpq-dev libglib2.0-dev libfuse3-dev
```

We install all in `/opt/LocalEGA`:
```bash
sudo mkdir -p /opt/LocalEGA/{bin,etc,lib,homes}
```

Install libfuse 3.16.2 from the [official repository](https://github.com/libfuse/libfuse).

Uncomment `user_allow_other` in `/usr/local/etc/fuse.conf`

## Install the live distribution: crypt4gh.fs
```bash
cd crypt4gh-fs
autoreconf -i
./configure --prefix=/opt/LocalEGA
make
sudo make install
```
Find more details in [crypt4gh-fs](crypt4gh-fs/README.md).

## Install the NSS module

```bash
cd nss
make 
sudo make install

echo '/opt/LocalEGA/lib' > /etc/ld.so.conf.d/LocalEGA.conf

sudo ldconfig -v | grep egafiles
```

In `/etc/nsswitch.conf`, add `egafiles` such as:
```
passwd:         files egafiles systemd
group:          files egafiles systemd
shadow:         files egafiles
```
Find more details in [nss](nss/README.md).

## PAM
```bash
cd pam
make
sudo make install
```
Find more details in [pam](pam/README.md).

## OpenSSH

Follow the instructions in [openssh/README](openssh/README.md).

## Vault-DB extension

In the Vault database, go to `LocalEGA/deploy/docker` and load the SQL files:
```bash
make load
```
Update the `nss.*` configurations in `pg.conf`.

Create the landing directories for the NSS files:
```bash
sudo chown 999 /opt/LocalEGA/etc/nss
sudo chown 999:lega /opt/LocalEGA/etc/authorized_keys
sudo chmod g+s /opt/LocalEGA/etc/authorized_keys
```

Call the NSS file creation:
```
make nss
```

And test it:
```bash
id jane
```

You should see:
```
uid=10001(jane) gid=20000(requesters) groups=20000(requesters)
```

For the Crypt4GH-fuse, copy the sample config file and change permissions:
```bash
cp crypt4gh-fs/fs.conf.sample /opt/LocalEGA/etc/fuse-vault-db.conf
chmod 600 /opt/LocalEGA/etc/fuse-vault-db.conf
```
Update password in `fuse-vault.db.conf`.
