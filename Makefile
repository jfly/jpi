.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Hi there! Someday something useful may go here."
	@echo "For now, try 'make build' or 'make sdcard'."

ifndef BOARD
$(error BOARD must be defined)
endif

ifeq ($(BOARD),basic-arch)
OUTDIR=$(CURDIR)/out/$(BOARD)
MAKE=make O=$(OUTDIR) -C basic-arch
else ifeq ($(BOARD),basic-raspbian)
OUTDIR=$(CURDIR)/out/$(BOARD)
MAKE=make O=$(OUTDIR) -C basic-raspbian
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

.PHONY: menuconfig
menuconfig:
	$(MAKE) $@

.PHONY: %-menuconfig
%-menuconfig:
	$(MAKE) $@

.PHONY: %-update-config
%-update-config:
	$(MAKE) $@

DEVICE_PATH=/dev/$(USB_DRIVE)
.PHONY: sdcard
sdcard: build
	@if [ "$(USB_DRIVE)" = "" ]; then \
		echo ""; \
		echo "You must specify USB_DRIVE."; \
		echo "Pick something from this list: "; \
		lsblk; \
		exit 1; \
	fi
	@if [ ! -b $(DEVICE_PATH) ]; then \
		echo ""; \
		echo "$(DEVICE_PATH) not found or not a block device! Aborting."; \
		echo "Pick something from this list: "; \
		lsblk; \
		exit 1; \
	fi
	@device_re="^mmc.*"; \
	if [[ ! $(USB_DRIVE) =~ $$device_re ]]; then \
		echo "$(DEVICE_PATH) does not match this regex: $$device_re."; \
		echo ""; \
		echo "I'm cowardly refusing to flash this drive."; \
		exit 2; \
	fi
	@echo "Flashing..."
	@sudo dd bs=4M if=$(OUTDIR)/images/sdcard.img of=$(DEVICE_PATH) status=progress conv=fsync
	@echo "Success!"
	@echo "Resizing the last partition to occupy the full space..."
	sudo parted -s $(DEVICE_PATH) "resizepart 2 -1" quit
	sudo fsck -f $(DEVICE_PATH)p2
	sudo resize2fs $(DEVICE_PATH)p2
	@echo "Success!"
