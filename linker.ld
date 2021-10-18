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
        . = 0x1000;
        .text BLOCK(512) : ALIGN(512) {
                *(.text)
        }
        .rodata BLOCK(512) : ALIGN(512) {
                *(.rodata)
        }
        .data BLOCK(512) : ALIGN(512) {
                *(.data)
	}
	.eh_frame BLOCK(512) : ALIGN(512) {
		*(.eh_frame)
	}
	.bss BLOCK(512) : ALIGN(512) {
		*(COMMON)
		*(.bss)
	}
}
