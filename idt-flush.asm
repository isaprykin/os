[GLOBAL idt_flush]

; Load the IDT descriptor structure that is passed as the first parameter.
idt_flush:
   lidt [rdi]
   ret
