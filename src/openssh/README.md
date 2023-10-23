# Install SSHD for EGA requesters


For Ubuntu, install the following packages:

	apt update
	apt upgrade -y
	apt install -y --no-install-recommends ca-certificates pkg-config git gcc make automake autoconf libtool bzip2 zlib1g-dev libssl-dev libedit-dev libpam0g-dev libpq-dev libsystemd-dev uuid-dev

Then run the following to configure it with its own user/group and privilege-separation.

	export OPENSSH_DIR=/opt/openssh
	export SSHD_UID=75
	export SSHD_GID=75
	export OPENSSH_PRIVSEP_PATH=/run/ega-sshd
	export OPENSSH_PRIVSEP_USER=ega-sshd
	export OPENSSH_PRIVSEP_GROUP=ega-sshd
	# export OPENSSH_GROUP_SSHKEYS=ega-ssh-keys
	export OPENSSH_PID_PATH=/run/ega-sshd


	getent group ${OPENSSH_PRIVSEP_GROUP} || groupadd -g ${SSHD_GID} -r ${OPENSSH_PRIVSEP_GROUP}

	mkdir -p ${OPENSSH_PRIVSEP_PATH}
	chmod 700 ${OPENSSH_PRIVSEP_PATH}

	# ${OPENSSH_PRIVSEP_PATH} must be owned by root and not group or world-writable.
	useradd -c "Privilege-separated SSH" \
            -u ${SSHD_UID} \
	        -g ${OPENSSH_PRIVSEP_GROUP} \
	        -s /usr/sbin/nologin \
	        -r \
	        -d ${OPENSSH_PRIVSEP_PATH} ${OPENSSH_PRIVSEP_USER}


	patch -p1 < ../patches/systemd-readyness.patch

	patch -p1 < ../patches/ega.patch

	autoreconf
	./configure --prefix=${OPENSSH_DIR} \
                --with-pam --with-pam-service=ega \
    		    --with-zlib \
    		    --with-openssl \
    		    --with-libedit \
    		    --with-privsep-user=${OPENSSH_PRIVSEP_USER} \
    		    --with-privsep-path=${OPENSSH_PRIVSEP_PATH} \
		        --without-xauth \
		        --without-maildir \
			    --without-selinux \
			    --with-systemd \
			    --with-pid-dir=${OPENSSH_PID_PATH}

	make
	make install-nosysconf

Create the new host keys

	mkdir -p /etc/ega
	rm -f /etc/ega/sshd_host_{rsa,dsa,ed25519}_key{,.pub}
	/opt/openssh/bin/ssh-keygen -t ed25519 -N '' -f /etc/ega/sshd_host_ed25519_key
	/opt/openssh/bin/ssh-keygen -t rsa     -N '' -f /etc/ega/sshd_host_rsa_key
	/opt/openssh/bin/ssh-keygen -t dsa     -N '' -f /etc/ega/sshd_host_dsa_key

Copy the System-D file into place

	cp sshd_banner /etc/ega/sshd_banner
	cp sshd_config /etc/ega/sshd_config
	echo 'SSHD_OPTS=-o LogLevel=DEBUG3' > /etc/ega/sshd_options
	cp pam.ega /etc/pam.d/ega
	cp ega-sshd.service /etc/systemd/system/ega-sshd.service
	systemctl daemon-reload
	

