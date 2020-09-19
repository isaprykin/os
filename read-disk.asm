        ; Load [2, 2 + DH) sectors into ES:BX from the drive DL.  The
        ; first sector is skipped because it contains the boot sector
        ; that is loaded by BIOS.
load_disk_starting_second_sector:
        push dx

        mov ah, 0x02            ; Read sectors into memory BIOS function.
        mov al, dh              ; Read DH many sectors.
        mov ch, 0x00            ; Start from the first cyclinder.
        mov dh, 0x00            ; Start from the first head.
        mov cl, 0x02            ; Start from the second sector.
        int 0x13                ; Call BIOS's disk interrupt.

        jc error_reading_disk   ; Carry-flag is set on error.

        pop dx                  ; Original requested number of sectors.
        cmp dh, al              ; AL is set to the number of sectors transferred.
        jne error_reading_disk  ; It's an error to not read all requested sectors.
        ret

        ; Print an error message.
error_reading_disk:
        mov bx, ERROR_MSG
        call print_string
        jmp $

%include 'print-string.asm'

        ERROR_MSG db 'Error reading the disk!', 0
