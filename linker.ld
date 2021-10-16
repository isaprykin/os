ENTRY(_start)
SECTIONS {
	/* We are trying to have an 9216-bytes long boot sector, */
	/* because that's how much fits on the outer ring of the */
	/* floopy.                                               */
	/* This linker script is used for assembling an elf file.*/
        /* The sections of the elf file are then copied into a   */
        /* .bin file.                                            */
        /* The first 512 bytes are going to be the boot-sector   */
        /* that gets prepended to what's linked here             */
        /* (bytes 0-0x200).                                      */
        . = 0x1000;
        /* bytes 0x200 - 0x1600 */
        .text BLOCK(1K) : ALIGN(1K) {
                *(.text)
        }
        /* bytes 0x1600 - 0x1a00 */
        .rodata BLOCK(1K) : ALIGN(1K) {
                *(.rodata)
        }
        /* bytes 0x1a00 - 0x1a00 */
        .data BLOCK(1K) : ALIGN(1K) {
                *(.data)
	}
	/* bytes 0x1a00 - 0x2630 */
	/* This section only gets loaded into the memory till 0x2200, */
	/* because that's how much we read from the floppy. */
	.eh_frame BLOCK(1K) : ALIGN(1K) {
		*(.eh_frame)
	}
	/* bytes 0x2630 - 0x2630 */
	.bss BLOCK(1K) : ALIGN(1K) {
		*(COMMON)
		*(.bss)
	}
}
