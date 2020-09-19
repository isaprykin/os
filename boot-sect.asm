[org 0x7c00]

        mov bx, 0x1000          ; The memory offest where to place the kernel.
        mov dh, 15              ; Read 15*512=7680 bytes.
        mov dl, 0               ; The boot drive.
        call load_disk_starting_second_sector

        call 0x1000             ; The kernel got loaded to the address 1000h.
loop:
        jmp loop                ; Jump in the sample place forever.

%include 'read-disk.asm'

        ; The boot program has to be 512 bytes. NASM syntax here is:
        ; - $ is the address of current position
        ; - $$ is the address of the beginning of the current segment
        times 510-($-$$) db 0   ; Pad till the 510th byte.

        dw 0xaa55               ; Magic value to indicate "bootable".
