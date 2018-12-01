include common.mk

# 将变量 DEVICE 的字符串以"_"为 delimiter 分割，前部赋值给 DEVICE_VENDOR，后部分赋值给 DEVICE_NAME
# 输入 "arduino_uno"，则 DEVICE_VENDOR := arduino, DEVICE_NAME := uno
DEVICE_VENDOR := $(firstword $(subst _, ,$(DEVICE)))
DEVICE_NAME := $(word 2,$(subst _, ,$(DEVICE)))

# 和 shell script 一样，字符串分多行使用 "\"
summary = \
	echo "\n$(ccgreen)avr-os build summary:$(ccend)\n"; \
	echo "$(ccyellow)OS static library:$(ccend) $(TARGET_AVR_OS_OUT)"; \
	echo "$(ccyellow)Example image:$(ccend) $(TARGET_AVR_EXAMPLE_OUT)";

# target: (dependencies)
#     (rules)

# target `example` 由 device/$(DEVICE_VENDOR)/$(DEVICE_NAME)/device.mk 通过 include 包含
all: example
	$(summary)

# include <relative/path/to/file> 包含一个 make 语法文件
include device/$(DEVICE_VENDOR)/$(DEVICE_NAME)/device.mk

build-dir:
	mkdir -p build

# target 名即执行该 target 所对应的 rules 之后生成的文件名
#
# 猜测：通过列举 target 及其对应的 dependencies，可建立一个依赖关系树
# 每次执行 make (target) 时，会遍历以 target 为根结点的树
# 如果关系树中的任意结点(target)满足下面 2 个条件：
#   1. target 对应文件不存在
#   2. target 的 mtime 比它的父节点晚
# 则该节点及其祖先结点的 rule 都会被执行
#
# .PHONY 用于指定伪 target，这些 target 不需满足上述2个条件，一定会执行
.PHONY: clean
clean:
	rm -rf build
