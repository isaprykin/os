[GLOBAL idt_flush]

; Load the IDT descriptor structure that is passed as the first parameter.
idt_flush:
   mov eax, [esp+4]
   lidt [eax]
   ret
