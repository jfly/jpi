.DEFAULT_GOAL := build

BUILDDIR=out

SOURCE_URL=https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-01-12/2021-01-11-raspios-buster-armhf-lite.zip
SOURCE_NOTDIR=$(notdir $(SOURCE_URL))
SOURCE_ZIP=$(BUILDDIR)/$(basename $(SOURCE_NOTDIR)).zip
SOURCE_IMAGE=$(BUILDDIR)/$(basename $(SOURCE_NOTDIR)).img
RESULT_IMAGE=$(BUILDDIR)/raspbian-jpi.img

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

# Download source image if it does not exist.
$(SOURCE_IMAGE): $(BUILDDIR)
	@if [ ! -f $(SOURCE_IMAGE) ]; then \
		wget $(SOURCE_URL) -O $(SOURCE_ZIP); \
		unzip $(SOURCE_ZIP) -d $(BUILDDIR); \
	fi

$(RESULT_IMAGE): build.sh $(SOURCE_IMAGE)
	SOURCE_IMAGE=$(SOURCE_IMAGE) ./build.sh

.PHONY: build
build: $(RESULT_IMAGE)

.PHONY: all
all: build
	@mkdir -p $(O)/images
	@cp $(RESULT_IMAGE) $(O)/images/sdcard.img

.PHONY: clean
clean:
	sudo rm -rf $(BUILDDIR)
