all install clean:
	@make -C pam_ega_auth $@
	@make -C pam_ega_homedir $@
	@make -C pam_ega_localnss $@
	@make -C pam_ega_mount $@

debug1 debug2 debug3:
	make clean install DEBUG=$(@:debug%=%)
