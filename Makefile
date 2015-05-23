ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = RippleBoard
RippleBoard_FILES = Tweak.xm
RippleBoard_FRAMEWORKS = UIKit CoreGraphics QuartzCore
ADDITIONAL_OBJCFLAGS = -fobjc-arc
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += rippleprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
