[EXTERN isr_handler]

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
   pushad

   mov ax, ds
   push eax

   mov ax, 0x10 ; The offset that skips over the two segments in GDT: the null segment
   mov ds, ax   ; and the code segment.
   mov es, ax
   mov fs, ax
   mov gs, ax
 
   mov ebx, esp
   sub esp, 4           ; Make space for the pointer.
   and esp, 0xFFFFFFF0  ; Stack is 16-byte aligned per System V ABI.
   mov [esp], ebx       ; Pass `struct registers` by pointer to `isr_handler`.
   call isr_handler
   mov esp, ebx

   pop eax      ; reload the original data segment descriptor
   mov ds, ax
   mov es, ax
   mov fs, ax
   mov gs, ax

   popad
   add esp, 8   ; Cleans up the pushed error code and pushed ISR number
   sti
   iret
