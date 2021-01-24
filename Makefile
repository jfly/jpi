.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Hi there! Someday something useful may go here."
	@echo "For now, try 'make build' or 'make sdcard'."

ifndef BOARD
$(error BOARD must be defined)
endif

ifeq ($(BOARD),basic)
OUTDIR=$(CURDIR)/out/$(BOARD)
MAKE=make O=$(OUTDIR) -C basic
else ifeq ($(BOARD),kodi)
OUTDIR=$(CURDIR)/out/$(BOARD)
MAKE=make O=$(OUTDIR) -C kodi
else ifeq ($(wildcard boards/$(BOARD)/.),)
$(error BOARD '$(BOARD)' not found. Try one of: $(shell ls boards/))
else
OUTDIR=$(CURDIR)/out/$(BOARD)
MAKE=make O=$(OUTDIR) -C buildroot
endif

.PHONY: configure
configure:
	$(MAKE) raspberrypi0w_defconfig

.PHONY: nconfig
nconfig:
	$(MAKE) nconfig

.PHONY: build
build:
	$(MAKE) all

.PHONY: clean
clean:
	$(MAKE) clean

.PHONY: sdcard
sdcard:
	lsblk
	@echo ""
	@echo "For now, I'm too cowardly to actually do this for you."
	@echo "Pick a device above (something like /dev/sdX),"
	@echo "and then run 'sudo dd bs=4M if=$(OUTDIR)/images/sdcard.img of=/dev/sdX status=progress conv=fsync'"
