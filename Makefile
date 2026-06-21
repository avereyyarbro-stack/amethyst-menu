TARGET := iphone:16.5:14.0
ARCHS = arm64

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

after-all::
	@DYLIB=$$(find $(THEOS_OBJ_DIR) -type f -name 'Amethyst.dylib' | head -n1); \
	if [ -n "$$DYLIB" ]; then \
	  install_name_tool -id @executable_path/Frameworks/Amethyst.dylib "$$DYLIB" || true; \
	fi
