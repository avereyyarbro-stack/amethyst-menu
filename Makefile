TARGET := iphone:16.5:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = Amethyst

Amethyst_FILES = AmethystLoader.m \
	AmethystMenu/AmethystMenuViewController.m \
	AmethystMenu/AmethystToggleRow.m \
	AmethystMenu/AmethystSettings.m \
	AmethystMenu/AmethystFloatingButton.m \
	AmethystMenu/AmethystLayoutLogger.m
Amethyst_CFLAGS = -fobjc-arc
Amethyst_FRAMEWORKS = UIKit QuartzCore

include $(THEOS)/makefiles/library.mk

after-all::
	@mkdir -p packages/inject
	@DYLIB="$(THEOS_OBJ_DIR)/Amethyst.dylib"; \
	if [ ! -f "$$DYLIB" ]; then \
	  DYLIB=$$(find $(THEOS_OBJ_DIR) -type f -name 'Amethyst.dylib' -print -quit); \
	fi; \
	if [ -z "$$DYLIB" ] || [ ! -f "$$DYLIB" ]; then \
	  echo "Amethyst.dylib missing under $(THEOS_OBJ_DIR)"; \
	  find $(THEOS_OBJ_DIR) -type f -print; \
	  exit 1; \
	fi; \
	cp "$$DYLIB" packages/inject/Amethyst.dylib; \
	install_name_tool -id @executable_path/Frameworks/Amethyst.dylib packages/inject/Amethyst.dylib || true; \
	echo "Staged packages/inject/Amethyst.dylib from $$DYLIB"
