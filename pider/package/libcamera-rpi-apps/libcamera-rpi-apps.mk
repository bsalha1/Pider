################################################################################
#
# libcamera-rpi-apps
#
# Same as libcamera-apps except has libcamera-rpi as the dependency.
#
################################################################################

LIBCAMERA_RPI_APPS_VERSION = 1.5.0
LIBCAMERA_RPI_APPS_SOURCE = rpicam-apps-$(LIBCAMERA_RPI_APPS_VERSION).tar.xz
LIBCAMERA_RPI_APPS_SITE = https://github.com/raspberrypi/rpicam-apps/releases/download/v$(LIBCAMERA_RPI_APPS_VERSION)
LIBCAMERA_RPI_APPS_LICENSE = BSD-2-Clause
LIBCAMERA_RPI_APPS_LICENSE_FILES = license.txt
LIBCAMERA_RPI_APPS_DEPENDENCIES = \
	host-pkgconf \
	boost \
	jpeg \
	libcamera-rpi \
	libexif \
	libpng \
	tiff \
	libdrm \
	ffmpeg

LIBCAMERA_RPI_APPS_CONF_OPTS = \
	-Denable_opencv=disabled \
	-Denable_tflite=disabled \
	-Denable_drm=enabled \
	-Denable_libav=enabled \
	-Denable_egl=disabled \
	-Denable_qt=disabled

$(eval $(meson-package))
