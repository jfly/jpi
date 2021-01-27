.DEFAULT_GOAL := build

BUILDDIR=out

SOURCE_URL=http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-4-latest.tar.gz
SOURCE_NOTDIR=$(notdir $(SOURCE_URL))
SOURCE_TARZIP=$(BUILDDIR)/$(SOURCE_NOTDIR)
RESULT_IMAGE=$(BUILDDIR)/archarm-jpi.img

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

# Download source image if it does not exist.
$(SOURCE_TARZIP): $(BUILDDIR)
	@if [ ! -f $(SOURCE_TARZIP) ]; then \
		wget $(SOURCE_URL) -O $(SOURCE_TARZIP); \
	fi

$(RESULT_IMAGE): build.sh $(SOURCE_TARZIP)
	SOURCE_TARZIP=$(SOURCE_TARZIP) ./build.sh

.PHONY: build
build: $(RESULT_IMAGE)

.PHONY: all
all: build
	@mkdir -p $(O)/images
	@cp $(RESULT_IMAGE) $(O)/images/sdcard.img

.PHONY: clean
clean:
	sudo rm -rf $(BUILDDIR)
