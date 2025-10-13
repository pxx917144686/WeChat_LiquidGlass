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
export PATH := $(CURDIR):$(PATH)

# TARGET
ARCHS = arm64
TARGET = iphone:clang:latest:15.6
# 引入 Theos 的通用设置
include $(THEOS)/makefiles/common.mk

# 插件名称
TWEAK_NAME = WeChat_LiquidGlass

# 源代码文件
ASM_SOURCES = $(shell find . -name "*.s")
OBJC_SOURCES = $(shell find . -name "*.m") $(shell find . -name "*.xm")
SWIFT_SOURCES = $(shell find . -name "*.swift")
$(TWEAK_NAME)_FILES = $(ASM_SOURCES) $(OBJC_SOURCES) $(SWIFT_SOURCES)

# 使用 Logos 语法
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation CoreFoundation

# 链接库
$(TWEAK_NAME)_LIBRARIES = 

include $(THEOS_MAKE_PATH)/tweak.mk