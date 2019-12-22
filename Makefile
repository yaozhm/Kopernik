VERSION_MAJOR			:= 1
VERSION_MINOR			:= 0

BUILD_STRING	:=	$(shell git describe --always --dirty --tags 2> /dev/null)
BUILD_BRANCH	:=	$(shell git branch 2> /dev/null)
VERSION_STRING	:=	v${VERSION_MAJOR}.${VERSION_MINOR}:${BUILD_STRING}:$(BUILD_BRANCH)

################################################################################
# Toolchain
################################################################################

HOSTCC			:=	gcc
export HOSTCC

CC			:=	${CROSS_COMPILE}gcc
CPP			:=	${CROSS_COMPILE}cpp
AS			:=	${CROSS_COMPILE}gcc
AR			:=	${CROSS_COMPILE}ar
LINKER			:=	${CROSS_COMPILE}ld
OC			:=	${CROSS_COMPILE}objcopy
OD			:=	${CROSS_COMPILE}objdump
NM			:=	${CROSS_COMPILE}nm
PP			:=	${CROSS_COMPILE}gcc -E
DTC			:=	dtc


# Additional warnings
# Level 1
WARNING1 := -Wextra
WARNING1 += -Wmissing-format-attribute
WARNING1 += -Wmissing-prototypes
WARNING1 += -Wold-style-definition

# Level 2
WARNING2 := -Waggregate-return
WARNING2 += -Wcast-align
WARNING2 += -Wnested-externs

WARNING3 := -Wbad-function-cast
WARNING3 += -Wcast-qual
WARNING3 += -Wconversion
WARNING3 += -Wpacked
WARNING3 += -Wpointer-arith
WARNING3 += -Wredundant-decls
WARNING3 += -Wswitch-default

ifeq (${W},1)
WARNINGS += $(WARNING1)
else ifeq (${W},2)
WARNINGS += $(WARNING1) $(WARNING2)
else ifeq (${W},3)
WARNINGS += $(WARNING1) $(WARNING2) $(WARNING3)
endif

WARNINGS	+=		-Wunused-but-set-variable -Wmaybe-uninitialized	\
				-Wpacked-bitfield-compat -Wshift-overflow=2 \
				-Wlogical-op

CPPFLAGS		=	${DEFINES} ${INCLUDES} ${MBEDTLS_INC} -nostdinc	\
				$(ERRORS) $(WARNINGS)

ASFLAGS			+=	$(CPPFLAGS) $(ASFLAGS_$(ARCH))			\
				-ffreestanding -Wa,--fatal-warnings

CFLAGS			+=	$(CPPFLAGS) $(TF_CFLAGS_$(ARCH))		\
				-ffunction-sections -fdata-sections		\
				-ffreestanding -fno-builtin -fno-common		\
				-Os -std=gnu99

INCLUDES		+=	-Iinclude				\
				-Iinclude/arch/${ARCH}			\
				-Iinclude/lib/cpus/${ARCH}		\
				-Iinclude/lib/el3_runtime/${ARCH}	\
				${PLAT_INCLUDES}			\
				${SPD_INCLUDES}


################################################################################
# Build targets
################################################################################

.PHONY:	all msg_start clean

all: clean msg_start targets_bin

msg_start:
	@echo "  Building ${VERSION_STRING}"

clean:
	@echo "  CLEAN"

targets_elf:
	@echo "  ELF"

targets_bin: targets_elf
	@echo "  BIN"
