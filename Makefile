THEOS = /Users/runner/theos
TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DLGMem

DLGMem_FILES = Tweak.xm DLGMem.m DLGMemUIView.m DLGMemUIViewCell.m IGGView.m JianghuPlayer.m KingSessionConfiguration.m SSKeychain.m NSString+Extend.m NSData+AES.m memory_engine.cpp fishhook.c
DLGMem_CFLAGS = -fobjc-arc -Wno-error
DLGMem_CXXFLAGS = -std=c++17 -fobjc-arc
DLGMem_PRIVATE_FRAMEWORKS = UIKit Foundation CoreGraphics Security

include $(THEOS_MAKE_PATH)/tweak.mk
