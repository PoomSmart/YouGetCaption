TARGET := iphone:clang:latest:11.0
INSTALL_TARGET_PROCESSES = YouTube
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouGetCaption

YouGetCaption_FILES = Tweak.x
YouGetCaption_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
