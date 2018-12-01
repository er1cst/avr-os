# ifeq (<string1>,<string2>)
# 	...
# endif
ifeq ($(AVR_HOME),)
	# AVR_HOME := /Applications/Arduino.app/Contents/Java
	AVR_HOME := /usr/local/avr8-gnu-toolchain-linux_x86_64
endif

# if CONFIG_AVR_TIMER equals to ""
ifeq ($(CONFIG_AVR_TIMER),)
CONFIG_AVR_TIMER := 1
endif

# for more text functions of GNU make, see: https://www.gnu.org/software/make/manual/html_node/Text-Functions.html
# 如果 CONFIG_AVR_TIMER 的值不等于 0 1 2 其中一个，则报错
ifeq (,$(filter $(CONFIG_AVR_TIMER), 0 1 2))
$(error Only TIMER 0, 1, and 2 are supported for CONFIG_AVR_TIMER)
endif

# the compiler
CC := $(AVR_HOME)/bin/avr-gcc
# the linker
LD := $(AVR_HOME)/bin/avr-ld
# the archiver combines a collection of object files into one archive file (the library)
AR := $(AVR_HOME)/bin/avr-ar

# -Wl,option1,option2,...,optionN	将 option1, option2, ..., optionN 传递给 linker
# -D name=definition			可以认为在预处理过程中定义 #define name definition
# -I dir				将 dir 增加到一个目录列表中，compiler 会在这个列表中列出的目录寻找头文件
# -Wall					show all warnings
#
# VAR_NAME += string1 会以空格做分隔符将 string1 附加到`$(VAR_NAME)`的末尾
CFLAGS += -Wl,--undefined=_mmcu,--section-start=.mmcu=0x910000 \
	-DF_CPU=16000000 -I $(AVR_HOME)/avr/include -O1 -Wall
CFLAGS += -mmcu=$(TARGET_MMCU)

# 如果 CONFIG_SIMAVR 为 1，则编译时增加相关 macro
ifeq ($(CONFIG_SIMAVR),1)
CFLAGS += -DSIMAVR
endif

CFLAGS += -DMAX_TASKS=$(TARGET_OS_MAX_TASKS)
CFLAGS += -DTASK_STACK_SIZE=$(TARGET_OS_TASK_STACK_SIZE)
CFLAGS += -DTICK_INTERVAL=$(TARGET_OS_TICK_INTERVAL_MS)

CFLAGS += -DCONFIG_AVR_TIMER=$(CONFIG_AVR_TIMER)

TARGET_AVR_OS_OUT = build/avr-os.a
TARGET_AVR_EXAMPLE_OUT = build/avr-os-example.img

os: build-dir
	@echo "Compiling OS sources..."
	$(CC) $(CFLAGS) -c os.c -o build/os.o
	$(CC) $(CFLAGS) -c utility/avr.c -o build/avr.o
	rm -f $(TARGET_AVR_OS_OUT)
	$(AR) rcs $(TARGET_AVR_OS_OUT) build/os.o
	$(AR) rcs $(TARGET_AVR_OS_OUT) build/avr.o 

example: os
	@echo "Creating example..."
	$(CC) $(CFLAGS) -I. -c example/main.c -o build/main.o
	$(CC) $(CFLAGS) build/main.o $(TARGET_AVR_OS_OUT) -o $(TARGET_AVR_EXAMPLE_OUT)

run: example
	simavr -m $(TARGET_MMCU) -v -v -f 16000000 $(TARGET_AVR_EXAMPLE_OUT)

test: os
	$(CC) $(CFLAGS) -I. -c test/test.c -o build/test.o
	$(CC) $(CFLAGS) build/test.o $(TARGET_AVR_OS_OUT) -o build/test
	simavr -m $(TARGET_MMCU) -v -v -f 16000000 build/test

.PHONY: os example run test
