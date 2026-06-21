TARGET := iphone:16.5:14.0
INSTALL_TARGET_PROCESSES = WarRobots

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Amethyst

Amethyst_FILES = Tweak.x \
	AmethystMenu/AmethystMenuViewController.m \
	AmethystMenu/AmethystToggleRow.m \
	AmethystMenu/AmethystSettings.m \
	AmethystMenu/AmethystFloatingButton.m
Amethyst_CFLAGS = -fobjc-arc
Amethyst_FRAMEWORKS = UIKit QuartzCore

include $(THEOS)/makefiles/tweak.mk

after-install::
	install.exec "killall -9 WarRobots" || true
