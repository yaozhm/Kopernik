/*
 * Code will start running at this symbol which is places at the start of the
 * image.
 */
ENTRY(entry)

SECTIONS
{
	/*
	 * Set the image origin to a platform specific address. The images are
	 * relocatable but some platforms, e.g. QEMU, load to the same address
	 * and it makes debugging easier if the addresses match the symbols.
	 */
	. = ORIGIN_ADDRESS;

	/*
	 * Collect together the code. This is page aligned so it can be mapped
	 * as executable-only.
	 */
	text_begin = .;
	.init : {
		*(.init.entry)
		*(.init.*)
	}
	.text : {
		*(.text.*)
	}
	text_size = ABSOLUTE(. - text_begin);
	. = ALIGN(4096);
	text_end = .;

	/*
	 * Collect together read-only data including relocations at the end
	 * which are applied by the entry code.  This is page aligned so it can
	 * be mapped as read-only and non-executable.
	 */
	. = ALIGN(4096);
	rodata_begin = .;
	.rodata : {
		*(.rodata.*)
	}
	/*
	 * .rela contains Elf64_Rela entries which contain 8-byte fields so
	 * should be 8-byte aligned.
	 */
	. = ALIGN(8);
	rela_begin = .;
	.rela : {
		*(.rela.*)
	}
	rela_end = .;
	/*
	 * The linker doesn't allow .dynsym and .dynstr to be discarded, see
	 * /DISCARD/ below, so make sure they don't get in the way.
	 */
	.dynsym : {
		*(.dynsym.*)
	}
	.dynstr : {
		*(.dynstr.*)
	}

	. = ALIGN(64);
	.stacks : {
		__stacks_start__ = .;
		*(_mp_stack)
		__stacks_end__ = .;
    	}
	/*
	 * Collect together the read-write data including .bss at the end which
	 * will be zero'd by the entry code. This is page aligned so it can be
	 * mapped as non-executable.
	 */
	. = ALIGN(4096);
	data_begin = .;
	.data : {
		*(.data)
	}
	/*
	 * Global offset table used for relocations. This is where relocation
	 * fix-ups are applied.
	 */
	.got : {
		*(.got.*)
	}
	/*
	 * The linker doesn't allow .dynamic to be discarded, see /DISCARD/
	 * below, so make sure it doesn't get in the way.
	 */
	.dynamic : {
		*(.dynamic.*)
	}
	/* Everything beyond this point will not be included in the binary. */
	bin_end = .;
	/* The entry point code assumes that .bss is 16-byte aligned. */
	. = ALIGN(16);
	bss_begin = .;
	.bss : {
		*(.bss)
		*(COMMON)
	}
	. = ALIGN(16);
	bss_end = .;
	data_size = ABSOLUTE(. - data_begin);
	. = ALIGN(4096);
	data_end = .;

	/*
	 * Remove unused sections from the image.
	 */
	/DISCARD/ : {
		/* The image loads itself so doesn't need these sections. */
		/* ld.lld doesn't allow these to be discarded.
		*(.dynsym)
		*(.dynstr)
		*(.dynamic)
		*/
		*(.gnu.hash)
		*(.hash)
		*(.interp)
	}

	/*
	 * Make note of some useful values.
	 */

	/* Note the first page not used in the image. */
	. = ALIGN(4096);
	image_end = .;

	/*
	 * Calculate sizes of the binary file and image loaded into memory as
	 * well as the text, read-only and read-write data sections.
	 */
	bin_size = ABSOLUTE(bin_end - ORIGIN_ADDRESS);
	image_size = ABSOLUTE(image_end - ORIGIN_ADDRESS);
}
