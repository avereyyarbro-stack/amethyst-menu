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
