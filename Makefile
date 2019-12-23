CFLAGS = $(cflags)

SOURCE_ROOT = .

CROSS_COMPILE := aarch64-none-linux-gnu-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
READELF = $(CROSS_COMPILE)readelf

BUILD = $(SOURCE_ROOT)/build

include source.mk

ALL_SRCS = $(KERNEL_SRCS) $(PLATFORM_SRCS) $(LIBC_SRCS) $(DRIVER_SRCS) $(TEST_SRCS)

C_SRCS   = $(filter %.c, $(ALL_SRCS))
ASM_SRCS = $(filter %.S, $(ALL_SRCS))
H_SRCS   = $(wildcard $(INCLUDE_DIR)/*.h)

C_OBJS   = $(addprefix $(BUILD)/, $(patsubst %.c,%.o,$(C_SRCS)))
ASM_OBJS = $(addprefix $(BUILD)/, $(patsubst %.S,%.o,$(ASM_SRCS)))

ALL_OBJS = $(C_OBJS) $(ASM_OBJS)
#$(warning ALL_SRCS $(ALL_SRCS))
#$(warning ALL_OBJS $(ALL_OBJS))

#$(warning C_SRCS $(C_SRCS) ASM_SRCS $(ASM_SRCS))
#$(warning C_OBJS $(C_OBJS) ASM_OBJS $(ASM_OBJS))


OBJ_PATHS = $(addprefix $(BUILD)/, $(sort $(dir $(ALL_SRCS))))
#$(warning OBJ_PATHS $(OBJ_PATHS))


TARGET = Kopernik
TARGET_ELF = $(BUILD)/$(TARGET).elf
TARGET_IMG = $(BUILD)/$(TARGET).bin
TARGET_MAP = $(BUILD)/$(TARGET).map

LDS = $(SOURCE_ROOT)/$(TARGET).ld

CFLAGS  += -nostdlib -funwind-tables -fno-builtin -Wall -O3 -g -I$(INCLUDE_DIR)

LDFLAGS = -T $(LDS) -Map $(TARGET_MAP) -nostdlib -nostartfiles --defsym=ORIGIN_ADDRESS=0x80000000

.PHONY: build_all clean tags

build_all: all

$(C_OBJS): $(BUILD)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(ASM_OBJS): $(BUILD)/%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

build_objs: $(C_OBJS) $(ASM_OBJS)

init:
	mkdir -p build
	@$(foreach d,$(OBJ_PATHS), mkdir -p $(d);)

all: init build_objs
	$(LD) $(ALL_OBJS) $(LDFLAGS) -o $(TARGET_ELF)
	$(OBJCOPY) $(TARGET_ELF) -O binary $(TARGET_IMG)
	cp $(TARGET_IMG) Kopernik.bin
	cp $(TARGET_ELF) Kopernik.elf

tags:
	@echo "  create ctags"

ccount:
	@echo "  counting sizes"
	find . | egrep ".*\.[ch]$$" | xargs wc -l


clean:
	-rm -rf build
