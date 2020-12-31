%ifndef ENABLE_A20_THROUGH_BIOS_ASM_
%define ENABLE_A20_THROUGH_BIOS_ASM_

enable_a20_through_bios:
        mov ax,2401h
        int 15h
        jc .error_enabling_a20
        ret

.error_enabling_a20:
        mov bx, .ERROR_MSG
        call print_string
        jmp $
            
        .ERROR_MSG db "Couldn't enable A20 with BIOS.", 0

%include 'print-string.asm'

%endif  ; ENABLE_A20_THROUGH_BIOS_ASM_
