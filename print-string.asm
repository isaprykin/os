	; Print the null-terminated BX string.
print_string:
	mov si, bx

.keep_printing:
	mov al, [si]
	inc si
	or al, 0
	je .done

	mov ah, 0x0e
	mov bh, 0
	mov bl, 4
	int 0x10

	jmp .keep_printing
.done:
	ret
