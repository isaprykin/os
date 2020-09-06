loop:
	jmp loop		; Jump in the sample place forever.
	; The boot program has to be 512 bytes.
	; NASM syntax here is:
	;  - $ is the address of current position
	;  - $$ is the address of the beginning of the current segment
times 510-($-$$) db 0		; Pad till the 510th byte.

dw 0xaa55			; Magic value to indicate "bootable".
