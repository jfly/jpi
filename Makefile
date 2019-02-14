.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Hi there! Someday something useful may go here."
	@echo "For now, try 'make build' or 'make sdcard'."

.PHONY: configure
configure:
	make O=$(CURDIR)/out -C buildroot raspberrypi0w_defconfig

.PHONY: nconfig
nconfig:
	make O=$(CURDIR)/out -C buildroot nconfig

.PHONY: build
build:
	make O=$(CURDIR)/out -C buildroot all

.PHONY: clean
clean:
	make O=$(CURDIR)/out -C buildroot clean

.PHONY: sdcard
sdcard:
	lsblk
	@echo ""
	@echo "For now, I'm too cowardly to actually do this for you."
	@echo "Pick a device above (something like /dev/sdX),"
	@echo "and then run 'sudo dd bs=4M if=out/images/sdcard.img of=/dev/sdX status=progress conv=fsync'"
