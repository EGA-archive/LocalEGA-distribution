
# Preliminaries

Create a `Makefile` with:

	PG_SU_PASSWORD=some-secret

	# Choose between docker and systemd deployment
	# For docker deployment
	include docker.mk
	# For systemd deployment
	include systemd.mk


Then adjust the conf files (pg.conf and pg_hba.conf)


# Build

	make build
	# or
	make rebuild

	make subscription
	# wait for replication to be over
	make later-nss-triggers
	make nss


# After restoring

	make after-globals # reset 'change-me' passwords
	
	make nss
