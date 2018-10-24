################################################################################
#
# arm-trusted-firmware
#
################################################################################

ARM_TRUSTED_FIRMWARE_VERSION = $(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_VERSION))
ARM_TRUSTED_FIRMWARE_LICENSE = BSD-3-Clause
ARM_TRUSTED_FIRMWARE_LICENSE_FILES = license.rst

ifeq ($(ARM_TRUSTED_FIRMWARE_VERSION),custom)
# Handle custom ATF tarballs as specified by the configuration
ARM_TRUSTED_FIRMWARE_TARBALL = $(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_TARBALL_LOCATION))
ARM_TRUSTED_FIRMWARE_SITE = $(patsubst %/,%,$(dir $(ARM_TRUSTED_FIRMWARE_TARBALL)))
ARM_TRUSTED_FIRMWARE_SOURCE = $(notdir $(ARM_TRUSTED_FIRMWARE_TARBALL))
BR_NO_CHECK_HASH_FOR += $(ARM_TRUSTED_FIRMWARE_SOURCE)
else ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_GIT),y)
ARM_TRUSTED_FIRMWARE_SITE = $(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_REPO_URL))
ARM_TRUSTED_FIRMWARE_SITE_METHOD = git
BR_NO_CHECK_HASH_FOR += $(ARM_TRUSTED_FIRMWARE_SOURCE)
else
ARM_TRUSTED_FIRMWARE_SITE = $(call github,ARM-software,arm-trusted-firmware,$(ARM_TRUSTED_FIRMWARE_VERSION))
endif

ARM_TRUSTED_FIRMWARE_INSTALL_IMAGES = YES

ARM_TRUSTED_FIRMWARE_PLATFORM = $(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_PLATFORM))
ARM_TRUSTED_FIRMWARE_IMG_DIR = $(@D)/build/$(ARM_TRUSTED_FIRMWARE_PLATFORM)/release

ARM_TRUSTED_FIRMWARE_MAKE_OPTS += \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	$(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES)) \
	PLAT=$(ARM_TRUSTED_FIRMWARE_PLATFORM)

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_UBOOT_AS_BL33),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += BL33=$(BINARIES_DIR)/u-boot.bin
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += uboot
endif

ifeq ($(BR2_TARGET_VEXPRESS_FIRMWARE),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += SCP_BL2=$(BINARIES_DIR)/scp-fw.bin
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += vexpress-firmware
endif

ifeq ($(BR2_TARGET_BINARIES_MARVELL),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += SCP_BL2=$(BINARIES_DIR)/scp-fw.bin
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += binaries-marvell
endif

ifeq ($(BR2_TARGET_MV_DDR_MARVELL),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MV_DDR_PATH=$(MV_DDR_MARVELL_DIR)
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += mv-ddr-marvell
endif

ARM_TRUSTED_FIRMWARE_MAKE_TARGETS = all

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_FIP),y)
ARM_TRUSTED_FIRMWARE_MAKE_TARGETS += fip
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += host-openssl
# fiptool only exists in newer (>= 1.3) versions of ATF, so we build
# it conditionally. We need to explicitly build it as it requires
# OpenSSL, and therefore needs to be passed proper variables to find
# the host OpenSSL.
define ARM_TRUSTED_FIRMWARE_BUILD_FIPTOOL
	if test -d $(@D)/tools/fiptool; then \
		$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D)/tools/fiptool \
			$(ARM_TRUSTED_FIRMWARE_MAKE_OPTS) \
			CPPFLAGS="$(HOST_CPPFLAGS)" \
			LDLIBS="$(HOST_LDFLAGS) -lcrypto" ; \
	fi
endef
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_BL31),y)
ARM_TRUSTED_FIRMWARE_MAKE_TARGETS += bl31
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_BL31_UBOOT),y)
define ARM_TRUSTED_FIRMWARE_BL31_UBOOT_BUILD
# Get the entry point address from the elf.
	BASE_ADDR=$$($(TARGET_READELF) -h $(ARM_TRUSTED_FIRMWARE_IMG_DIR)/bl31/bl31.elf | \
	             sed -r '/^  Entry point address:\s*(.*)/!d; s//\1/') && \
	$(MKIMAGE) \
		-A arm64 -O arm-trusted-firmware -C none \
		-a $${BASE_ADDR} -e $${BASE_ADDR} \
		-d $(ARM_TRUSTED_FIRMWARE_IMG_DIR)/bl31.bin \
		$(ARM_TRUSTED_FIRMWARE_IMG_DIR)/atf-uboot.ub
endef
define ARM_TRUSTED_FIRMWARE_BL31_UBOOT_INSTALL
	$(INSTALL) -m 0644 $(ARM_TRUSTED_FIRMWARE_IMG_DIR)/atf-uboot.ub \
		$(BINARIES_DIR)/atf-uboot.ub
endef
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += RESET_TO_BL31=1
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += host-uboot-tools
endif

define ARM_TRUSTED_FIRMWARE_BUILD_CMDS
	$(ARM_TRUSTED_FIRMWARE_BUILD_FIPTOOL)
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) $(ARM_TRUSTED_FIRMWARE_MAKE_OPTS) \
		$(ARM_TRUSTED_FIRMWARE_MAKE_TARGETS)
	$(ARM_TRUSTED_FIRMWARE_BL31_UBOOT_BUILD)
endef

define ARM_TRUSTED_FIRMWARE_INSTALL_IMAGES_CMDS
	cp -dpf $(ARM_TRUSTED_FIRMWARE_IMG_DIR)/*.bin $(BINARIES_DIR)/
	$(ARM_TRUSTED_FIRMWARE_BL31_UBOOT_INSTALL)
endef

# Configuration check
ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE)$(BR_BUILDING),yy)

ifeq ($(ARM_TRUSTED_FIRMWARE_VERSION),custom)
ifeq ($(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_TARBALL_LOCATION))),)
$(error No tarball location specified. Please check BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_TARBALL_LOCATION))
endif
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_GIT),y)
ifeq ($(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_REPO_URL)),)
$(error No repository specified. Please check BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_REPO_URL)
endif
endif

endif

$(eval $(generic-package))
