################################################################################
#
# pider-init
#
################################################################################

PIDER_INIT_VERSION = HEAD
PIDER_INIT_SITE = $(BR2_EXTERNAL_PIDER_PATH)/package/pider-init/src
PIDER_INIT_SITE_METHOD = local
PIDER_INIT_INSTALL_TARGET = YES

define PIDER_INIT_BUILD_CMDS
    $(MAKE) CXX="$(TARGET_CXX)" -C $(@D) all
endef

define PIDER_INIT_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/init $(TARGET_DIR)/sbin
endef

$(eval $(generic-package))
