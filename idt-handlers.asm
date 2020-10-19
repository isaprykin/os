[GLOBAL isr0]
isr0:
  cli
  push byte 0   ; A dummy error code
  push byte 0   ; The interrupt number.
  jmp isr_common_stub

[GLOBAL isr1]
isr1:
  cli
  push byte 0
  push byte 1
  jmp isr_common_stub

isr_common_stub:
   pusha

   mov ax, ds
   push eax

   mov ax, 0x10 ; The offset that skips over the two segments in GDT: the null segment
   mov ds, ax   ; and the code segment.
   mov es, ax
   mov fs, ax
   mov gs, ax

   ; Call a handler in C here.

   pop eax      ; reload the original data segment descriptor
   mov ds, ax
   mov es, ax
   mov fs, ax
   mov gs, ax

   popa
   add esp, 8   ; Cleans up the pushed error code and pushed ISR number
   sti
   iret
