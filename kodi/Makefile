.DEFAULT_GOAL := build

BUILDDIR=out

SOURCE_BASENAME=LibreELEC-RPi2.arm-9.2.6.img
SOURCE_IMAGE=$(BUILDDIR)/$(SOURCE_BASENAME)
RESULT_IMAGE=$(BUILDDIR)/LibreELEC-jpi.img

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

# Download source image if it does not exist.
$(SOURCE_IMAGE): $(BUILDDIR)
	@if [ ! -f $(SOURCE_IMAGE) ]; then \
		wget http://releases.libreelec.tv/$(SOURCE_BASENAME) http://archive.libreelec.tv/$(SOURCE_BASENAME) -O $(SOURCE_IMAGE).gz; \
		gunzip $(SOURCE_IMAGE).gz; \
	fi

$(RESULT_IMAGE): build.sh $(SOURCE_IMAGE)
	SOURCE_BASENAME=$(SOURCE_BASENAME) ./build.sh

.PHONY: build
build: $(RESULT_IMAGE)

.PHONY: all
all: build
	@mkdir -p $(O)/images
	@cp $(RESULT_IMAGE) $(O)/images/sdcard.img

.PHONY: clean
clean:
	sudo rm -rf $(BUILDDIR)

# Clobbers the ~/.kodi directory on the host computer and configures it for a
# "fresh" setup. This is a decent approximation of setting up a fresh sdcard,
# and a lot less work.
.PHONY: test-local
test-local: build
	./test-local.sh
