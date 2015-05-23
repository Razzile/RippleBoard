ARCHS = armv7 arm64
include theos/makefiles/common.mk

BUNDLE_NAME = RipplePrefs
RipplePrefs_FILES = RipplePrefs.mm
RipplePrefs_INSTALL_PATH = /Library/PreferenceBundles
RipplePrefs_FRAMEWORKS = UIKit QuartzCore CoreGraphics
RipplePrefs_PRIVATE_FRAMEWORKS = Preferences
ADDITIONAL_OBJCFLAGS = -fobjc-arc
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/RipplePrefs.plist$(ECHO_END)
