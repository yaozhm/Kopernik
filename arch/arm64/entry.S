/**
 * This is a generic entry point for an image. It carries out the operations
 * required to prepare the loaded image to be run. Specifically, it performs
 * relocations and zeroing of the bss section using registers x25 and above.
 */
.section .init.entry, "ax"
.global entry
entry:
	/* Linux aarch64 image header. */
	b 0f
	.word 0
	.quad 0x1000      /* text_offset */
	.quad image_size  /* image_size */
	.quad 0           /* flags */
	.quad 0           /* res2 */
	.quad 0           /* res3 */
	.quad 0           /* res4 */
	.word 0x644d5241  /* magic */
	.word 0

	/*
	 * Calculate the difference between the actual load address and the
	 * preferred one. We'll use this to relocate.
	 */
0:	adrp x25, entry
	add x25, x25, :lo12:entry

	ldr w29, =ORIGIN_ADDRESS

	sub x25, x25, x29

	/* Find where the relocations begin and end. */
	adrp x29, rela_begin
	add x29, x29, :lo12:rela_begin

	adrp x30, rela_end
	add x30, x30, :lo12:rela_end

	/* Iterate over all relocations. */
1:	cmp x29, x30
	b.eq 2f

	ldp x26, x27, [x29], #16
	ldr x28, [x29], #8

	cmp w27, #1027 /* R_AARCH64_RELATIVE */
#	b.ne 1b
	b.ne .

	add x28, x28, x25
	str x28, [x26, x25]
	b 1b

	/* Zero out the bss section. */
2:	adrp x29, bss_begin
	add x29, x29, :lo12:bss_begin

	adrp x30, bss_end
	add x30, x30, :lo12:bss_end

3:	cmp x29, x30
	b.hs 4f

	stp xzr, xzr, [x29], #16
	b 3b

	/* Branch to the entry point for the specific image. */
4:	b prepare_for_c

/**
 * Set up CPU environment for executing C code. This is called on first boot
 * with caches disabled but subsequent calls will have caches enabled.
 *
 * x0 points to the current CPU on entry and exit.
 */
prepare_for_c:
	/* Use SPx (instead of SP0). */
	msr spsel, #1

	/* Prepare the stack. */
	ldr x1, [x0, #CPU_STACK_BOTTOM]
	mov sp, x1

	/* Configure exception handlers. */
	adr x2, vector_table_el2
	msr vbar_el2, x2
	ret