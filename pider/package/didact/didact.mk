################################################################################
#
# didact package
#
################################################################################

DIDACT_VERSION = 1.0
DIDACT_SITE = $(BR2_EXTERNAL_PIDER_PATH)/package/didact/src
DIDACT_SITE_METHOD = local

define DIDACT_BUILD_CMDS
    $(MAKE) CXX="$(TARGET_CXX)" LD="$(TARGET_LD)" -C $(@D) all
endef

define DIDACT_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/didact $(TARGET_DIR)/usr/bin
endef

$(eval $(generic-package))
