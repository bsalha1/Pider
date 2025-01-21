################################################################################
#
# libcamera-rpi
#
################################################################################

LIBCAMERA_RPI_VERSION = v0.3.2+rpt20241119
LIBCAMERA_RPI_SITE = $(call github,raspberrypi,libcamera,$(LIBCAMERA_RPI_VERSION))
LIBCAMERA_RPI_DEPENDENCIES = \
	host-openssl \
	host-pkgconf \
	host-python-jinja2 \
	host-python-ply \
	host-python-pyyaml \
	libpisp \
	libyaml \
	gnutls
LIBCAMERA_RPI_CONF_OPTS = \
	-Dandroid=disabled \
	-Ddocumentation=disabled \
	-Dtest=false \
	-Dwerror=false
LIBCAMERA_RPI_INSTALL_STAGING = YES
LIBCAMERA_RPI_LICENSE = \
	LGPL-2.1+ (library), \
	GPL-2.0+ (utils), \
	MIT (qcam/assets/feathericons), \
	BSD-2-Clause (raspberrypi), \
	GPL-2.0 with Linux-syscall-note or BSD-3-Clause (linux kernel headers), \
	CC0-1.0 (meson build system), \
	CC-BY-SA-4.0 (doc)
LIBCAMERA_RPI_LICENSE_FILES = \
	LICENSES/LGPL-2.1-or-later.txt \
	LICENSES/GPL-2.0-or-later.txt \
	LICENSES/MIT.txt \
	LICENSES/BSD-2-Clause.txt \
	LICENSES/GPL-2.0-only.txt \
	LICENSES/Linux-syscall-note.txt \
	LICENSES/BSD-3-Clause.txt \
	LICENSES/CC0-1.0.txt \
	LICENSES/CC-BY-SA-4.0.txt

LIBCAMERA_RPI_CXXFLAGS = -faligned-new
LIBCAMERA_RPI_CONF_OPTS += -Dpycamera=disabled
LIBCAMERA_RPI_CONF_OPTS += -Dv4l2=true
LIBCAMERA_RPI_CONF_OPTS += -Dpipelines=rpi/pisp
LIBCAMERA_RPI_CONF_OPTS += -Dlc-compliance=disabled
LIBCAMERA_RPI_CONF_OPTS += -Dqcam=disabled
LIBCAMERA_RPI_CONF_OPTS += -Dudev=disabled
LIBCAMERA_RPI_CONF_OPTS += -Dtracing=disabled

ifeq ($(BR2_PACKAGE_TIFF),y)
LIBCAMERA_RPI_DEPENDENCIES += tiff
endif

# Open-Source IPA shlibs need to be signed in order to be runnable within the
# same process, otherwise they are deemed Closed-Source and run in another
# process and communicate over IPC.
# Buildroot sanitizes RPATH in a post build process. meson gets rid of rpath
# while installing so we don't need to do it manually here.
# Buildroot may strip symbols, so we need to do the same before signing
# otherwise the signature won't match the shlib on the rootfs. Since meson
# install target is signing the shlibs, we need to strip them before.
LIBCAMERA_RPI_STRIP_FIND_CMD = \
	find $(@D)/build/src/ipa \
	$(if $(call qstrip,$(BR2_STRIP_EXCLUDE_FILES)), \
		-not \( $(call findfileclauses,$(call qstrip,$(BR2_STRIP_EXCLUDE_FILES))) \) ) \
	-type f -name 'ipa_*.so' -print0

define LIBCAMERA_RPI_BUILD_STRIP_IPA_SO
	$(LIBCAMERA_RPI_STRIP_FIND_CMD) | xargs --no-run-if-empty -0 $(STRIPCMD)
endef

LIBCAMERA_RPI_POST_BUILD_HOOKS += LIBCAMERA_RPI_BUILD_STRIP_IPA_SO

$(eval $(meson-package))
