# 1 "arch/arm64/entry.S"
# 1 "<built-in>"
# 1 "<command-line>"
# 31 "<command-line>"
# 1 "/home/puck/work/download/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/usr/include/stdc-predef.h" 1 3 4
# 32 "<command-line>" 2
# 1 "arch/arm64/entry.S"





.section .init.entry, "ax"
.global entry
entry:

 b 0f
 .word 0
 .quad 0x1000
 .quad image_size
 .quad 0
 .quad 0
 .quad 0
 .quad 0
 .word 0x644d5241
 .word 0





0: adrp x25, entry
 add x25, x25, :lo12:entry

 ldr w29, =ORIGIN_ADDRESS

 sub x25, x25, x29


 adrp x29, rela_begin
 add x29, x29, :lo12:rela_begin

 adrp x30, rela_end
 add x30, x30, :lo12:rela_end


1: cmp x29, x30
 b.eq 2f

 ldp x26, x27, [x29], #16
 ldr x28, [x29], #8

 cmp w27, #1027
# b.ne 1b
 b.ne .

 add x28, x28, x25
 str x28, [x26, x25]
 b 1b


2: adrp x29, bss_begin
 add x29, x29, :lo12:bss_begin

 adrp x30, bss_end
 add x30, x30, :lo12:bss_end

3: cmp x29, x30
 b.hs 4f

 stp xzr, xzr, [x29], #16
 b 3b


4: b prepare_for_c







prepare_for_c:

 msr spsel, #1


 #ldr x1, [x0, #CPU_STACK_BOTTOM]
 mov sp, x1


 #adr x2, vector_table_el2
 #msr vbar_el2, x2
 ret
