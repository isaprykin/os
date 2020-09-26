	; Setting up the Global Descriptor Table for switching to the
	; 32-bit protected mode.
	;
	; Call `switch_to_protected_mode` and set the `protected_mode`
	; label after `[bits 32]` on the code that is going to be
	; executed in the 32-bit protected mode.

gdt_start:

null_descriptor:		; The null descriptor.  It's not used and it is
	dd 0x0			; generally considered a idea.  It can be used
	dd 0x0          	; to initialize unused segment registers.

code_segment_descriptor:
	dw 0xffff		; Limit of the segment.
	dw 0x0			; The base (start) of the segment.First 2 bytes.
	db 0x0			; 3rd byte of the base.
	; The access byte has the following format:
	; |Pr|Privl2bits|S|Ex|DC|RW|AC|
	; Pr - present bit.  It should be 1 to be valid.
	; Privl - 2 bits that contain the 0-3 ring number.
	; S - type, 1 for code or data and 0 for system segments.
	; Ex - 1 if the segment is executable code or 0 for non-executable data.
	; DC - 1) Direction for data segments: 0 grows up, 1 grows down.
	;      2) Conforming for code segments: 1 if the code can be executed
	;         by an equal or lower privelege level.
	; RW - 1) For code segments, 1 if readable.  Can't be writable.
	;      2) For data segments, 1 if writable.  Always readable.
	; Ac - Accessed.  The CPU will set to 0 when accessed.
	db 10011010b		; 0 ring code executable readable segment.
	; Flags and the top nibble of the limit.
	; |Flags 4 bits| Limit 4 bits|
	; Format of the flags is:
	; |Gr|Sz|0|0|
	; Gr - granularity bit. 0 if the the limit is in byte granularity and
	;      1 if it's in 4KiB (page) granularity.
	; Sz - size bit.  0 defines a 16 bit protected mode, 1 defines a 32 bit
	;      protected mode.
	; page granularity, 32-bit protected mode. Limit 0xFF.. :
	db 11001111b
	db 0x0			; 4th byte of the base.

data_segment_descriptor:
	dw 0xffff		; Limit
	dw 0x0			; Starts at 00
	db 0x0			; Starts at 000
	; 0 ring non-executable data writable segment that grows up:
	db 10010010b
	; page granularity, 32 bit protected mode. Limit 0xFF.. :
	db 11001111b
	db 0x0			; Starts at 0000.

gdt_end:

gdt_descriptors:
	; Size of the descriptor in bytes:
	dw gdt_end - gdt_start - 1
	dd gdt_start		; Start address of the descriptor.

	CODE_SEG equ code_segment_descriptor - gdt_start
	DATA_SEG equ data_segment_descriptor - gdt_start


[bits 16]
switch_to_protected_mode:
	cli			; Disable interrupts.
	lgdt [gdt_descriptors]	; Re-load the Global Descriptors Table.

	mov eax, cr0		; Load in the control register.
	or eax, 0x1		; Set the "Protected Mode Enable" bit.
	mov cr0, eax		; Set the value back into the control register.

	; Far jump to set the CS register and reset the pipeline of CPU
	; instructions.
	jmp CODE_SEG:.init_protected_mode

[bits 32]
.init_protected_mode:
	mov ax, DATA_SEG	; Point the segments to the data segment.
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ebp, 0xC00000	; Set stack somewhere far away, otherwise its
	mov esp, ebp		; value is from before the protected mode.

	call protected_mode
