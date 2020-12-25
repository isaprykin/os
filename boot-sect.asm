[org 0x7c00]
KERNEL_ADDRESS equ 0x1000

        mov bx, KERNEL_ADDRESS  ; The memory offest where to place the kernel.
        mov dh, 15              ; Read 15*512=7680 bytes.
        mov dl, 0               ; The boot drive.
        call load_disk_starting_second_sector
        call enable_a20_through_bios
        call switch_to_protected_mode

%include 'a20.asm'
%include 'read-disk.asm'
%include 'switch-to-32-protected-mode.asm'

[bits 32]
protected_mode:
        call KERNEL_ADDRESS	; We will not return.
        jmp $	                ; Jump in the same place forever.

        ; The boot program has to be 512 bytes. NASM syntax here is:
        ; - $ is the address of current position
        ; - $$ is the address of the beginning of the current segment
        times 510-($-$$) db 0   ; Pad till the 510th byte.

        dw 0xaa55               ; Magic value to indicate "bootable".
