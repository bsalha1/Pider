################################################################################
#
# libpisp
#
################################################################################

LIBPISP_VERSION = v1.0.7
LIBPISP_SITE = $(call github,raspberrypi,libpisp,$(LIBPISP_VERSION))
LIBPISP_DEPENDENCIES = json-for-modern-cpp
LIBPISP_INSTALL_STAGING = YES

$(eval $(meson-package))
