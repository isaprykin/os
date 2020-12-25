[EXTERN isr_handler]

%macro ISR_NOERRCODE 1  ; define a macro, taking one parameter
  [GLOBAL isr%1]        ; %1 accesses the first parameter.
  isr%1:
    cli
    push byte 0         ; A dummy error code
    push %1             ; The interrupt number.
    jmp isr_common_stub
%endmacro

%macro ISR_ERRCODE 1
  [GLOBAL isr%1]
  isr%1:
    cli
    push %1            ; The interrupt number.
    jmp isr_common_stub
%endmacro

ISR_NOERRCODE 0
ISR_NOERRCODE 1
ISR_NOERRCODE 2
ISR_NOERRCODE 3
ISR_NOERRCODE 4
ISR_NOERRCODE 5
ISR_NOERRCODE 6
ISR_NOERRCODE 7
ISR_ERRCODE   8
ISR_NOERRCODE 9
ISR_ERRCODE   10
ISR_ERRCODE   11
ISR_ERRCODE   12
ISR_ERRCODE   13
ISR_ERRCODE   14
ISR_NOERRCODE 15
ISR_NOERRCODE 16
ISR_ERRCODE   17
ISR_NOERRCODE 18
ISR_NOERRCODE 19
ISR_NOERRCODE 20
ISR_NOERRCODE 21
ISR_NOERRCODE 22
ISR_NOERRCODE 23
ISR_NOERRCODE 24
ISR_NOERRCODE 25
ISR_NOERRCODE 26
ISR_NOERRCODE 27
ISR_NOERRCODE 28
ISR_NOERRCODE 29
ISR_ERRCODE   30
ISR_NOERRCODE 31

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
