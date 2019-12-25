/*
 * multi core stack define
 */
#include <sizes.h>

#define STACK_SIZE    SZ_4K
#define CORE_NUM      8

unsigned char mp_stack[STACK_SIZE * CORE_NUM]__attribute__ ((section ("_mp_stack")));
