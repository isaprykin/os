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

%macro IRQ 2
  [GLOBAL irq%1]
  irq%1:
    cli
    push byte 0
    push byte %2
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

IRQ   0,    32
IRQ   1,    33
IRQ   2,    34
IRQ   3,    35
IRQ   4,    36
IRQ   5,    37
IRQ   6,    38
IRQ   7,    39
IRQ   8,    40
IRQ   9,    41
IRQ   10,   42
IRQ   11,   43
IRQ   12,   44
IRQ   13,   35
IRQ   14,   46
IRQ   15,   47


isr_common_stub:
   mov r8, rsp
   push rax
   push rcx
   push rdx
   push rbx
   push r8
   push rbp
   push rsi
   push rdi

   mov ax, ds
   push rax

   mov ax, 0x10 ; The offset that skips over the two segments in GDT: the null segment
   mov ds, ax   ; and the code segment.
   mov es, ax
   mov fs, ax
   mov gs, ax

   mov rbx, rsp
   mov rdi, rbx
   call isr_handler
   mov rsp, rbx

   pop rax      ; reload the original data segment descriptor
   mov ds, ax
   mov es, ax
   mov fs, ax
   mov gs, ax

   pop rdi
   pop rsi
   pop rbp
   add rsp, 8
   pop rbx
   pop rdx
   pop rcx
   pop rax 
   add rsp, 16   ; Cleans up the pushed error code and pushed ISR number
   sti
   iretq
