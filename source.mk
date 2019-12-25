# define compile source file

INCLUDE_DIR += include \
	       arch/arm64/include

KERNEL_SRCS += arch/arm64/entry.S \
	       kernel/mp_stack.c

PLATFORM_SRCS +=

LIBC_SRCS +=

DRIVER_SRCS +=

TEST_SRCS +=
