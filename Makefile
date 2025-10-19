export DEBUG = 0
export THEOS_STRICT_LOGOS = 0
export ERROR_ON_WARNINGS = 0
export LOGOS_DEFAULT_GENERATOR = internal

# Rootless 无根
export THEOS_PACKAGE_SCHEME = rootless
THEOS_PACKAGE_INSTALL_PREFIX = /var/jb

# 直接输出到根路径
export THEOS_PACKAGE_DIR = $(CURDIR)

# 设置工具路径
export PATH := $(CURDIR):$(PATH) - 支持iOS 16.0以上版本
ARCHS = arm64
TARGET = iphone:clang:latest:16.0
# 引入 Theos 的通用设置
include $(THEOS)/makefiles/common.mk

# 插件名称
TWEAK_NAME = WeChat_LiquidGlass

# 源代码文件
OBJC_SOURCES = AdvancedHooks.m SettingsViewController.m 
$(TWEAK_NAME)_FILES = $(ASM_SOURCES) $(OBJC_SOURCES)

# 使用 Logos 语法
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
# 移除Swift相关配置
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation CoreFoundation
$(TWEAK_NAME)_LDFLAGS = 

# 链接库
$(TWEAK_NAME)_LIBRARIES = 

include $(THEOS_MAKE_PATH)/tweak.mk