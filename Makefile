targets := $(sort $(patsubst default/scripts/%,%,$(wildcard default/scripts/*)) $(patsubst working/scripts/%,%,$(wildcard working/scripts/*)))
helpers := $(wildcard platforms/*) $(wildcard customizations/*)


default:
	@echo "See README.md for usage"


# Make 'install' recursive.  Dependencies may have changed if helpers were called first.
install:
	$(MAKE) .install

# Install
.install:  settings.sh $(targets:%=working/status/%)
	@echo
	@echo
	@echo -e "\e[1;32m"					# Green
	@echo "Install Successful"
	@echo -e "\e[m"						# Reset colors
	@-grep --color -nsE "TODO|$$" working/messages
	@echo


# Run an installation script
$(targets:%=working/status/%): working/status/%: working/scripts/% settings.sh working/chroot-settings.sh install-wrapper.sh | working/status/
	echo $@ > working/current_target
	./install-wrapper.sh $^
	touch $@
	rm -f working/current_target

# Mark the current target resolved
continue: working/current_target
	touch `cat working/current_target`
	rm -f working/current_target


# Copy a default script, if needed
$(targets:%=working/scripts/%): working/scripts/%: | working/scripts/
	cp default/scripts/$* $@

# Copy the default chroot-settings.sh, if needed
working/chroot-settings.sh: default/chroot-settings.sh | working/
	cp $< $@


# Queue helper scripts
$(helpers): | working/
	cp -r $@/* working


# Rsync all files to archiso.  Useful when debugging.
sync:
	rsync -vcrt * archiso.local:/root/archer


# Create needed directories
%/:
	mkdir -p $@

clean:
	rm -rf working/
	-umount -R /mnt
	-cryptsetup close /dev/dm*

.PHONY: default install .install $(helpers) continue sync clean

