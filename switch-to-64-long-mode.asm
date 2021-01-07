%ifndef SWITCH_TO_64_LONG_MODE_ASM_
%define SWITCH_TO_64_LONG_MODE_ASM_

	; Setting up the Global Descriptor Table for switching to the
	; 64-bit long mode.
	;
	; Call `switch_to_long_mode` and set the `long_mode`
	; label after `[bits 64]` on the code that is going to be
	; executed in the 64-bit long mode.

ALIGN 4             ; AMD recommends to alignment for GDT pointer for
                    ; performance reasons.
gdt_start:

null_descriptor:        ; The null descriptor.  It's not used and it is
	dd 0x0              ; generally considered a good idea.  It can be used
	dd 0x0              ; to initialize unused segment registers.

code_segment_descriptor:
	dw 0xffff		; Limit of the segment.
	dw 0x0			; The base (start) of the segment.First 2 bytes.
	db 0x0			; 3rd byte of the base.
	; The access byte has the following format:
	; |Pr|Privl2bits|S|Ex|DC|RW|AC|
	; Pr - present bit.  It should be 1 to be valid.
	; Privl - 2 bits that contain the 0-3 ring number.
	; S - type, 1 for code or data and 0 for system segments.
	; Ex - 1 if the segment is executable code or 0 for non-executable data.
	; DC - 1) Direction for data segments: 0 grows up, 1 grows down.
	;      2) Conforming for code segments: 1 if the code can be executed
	;         by an equal or lower privelege level.
	; RW - 1) For code segments, 1 if readable.  Can't be writable.
	;      2) For data segments, 1 if writable.  Always readable.
	; Ac - Accessed.  The CPU will set to 0 when accessed.
    ; In 64-bit long mode, bits other than Pr, Priv and DC are ignored.
	db 10011010b		; 0 ring code executable readable segment.
	; Flags and the top nibble of the limit.
	; |Flags 4 bits| Limit 4 bits|
	; Format of the flags is:
	; |Gr|Sz|L|0|
	; Gr - granularity bit. 0 if the the limit is in byte granularity and
	;      1 if it's in 4KiB (page) granularity.
	; Sz - size bit.  0 defines a 16 bit protected mode, 1 defines a 32 bit
	;      protected mode.  Aslo called a D/B bit. It has to be 0 when L = 1.
    ;  L - Long mode.
	; page granularity, protected mode. Limit 0xFF.. :
    ; In 64-bit long mode bit other than Gr and L are ignored.
	db 10101111b
	db 0x0			; 4th byte of the base.

data_segment_descriptor:
	dw 0xffff		; Limit
	dw 0x0			; Starts at 00
	db 0x0			; Starts at 000
    ; Pr - present bit is the most significant one.
	; 0 ring non-executable data writable segment that grows up:
	db 10010010b
	; page granularity, protected mode. Limit 0xFF.. :
	db 11001111b
	db 0x0			; Starts at 0000.
    ; In 64-bit bits other than the present bit are ignored.

gdt_end:

gdt_descriptors:
	; Size of the descriptor in bytes:
	dw gdt_end - gdt_start - 1
	dd gdt_start		; Start address of the descriptor.

	CODE_SEG equ code_segment_descriptor - gdt_start
	DATA_SEG equ data_segment_descriptor - gdt_start

ALIGN 4
triple_fault_idt:   ; We are jumping into long mode directly from real-mode.
    dw 0            ; Triple-fault if we get an interrupt before we are there.
    dd 0

[bits 16]
switch_to_long_mode:
    ; We are going to create page translation tables and point cr3 to their 
    ; start. cr3 is going to point to the beginning of Page Map Level-4 Table 
    ; (PML4E):
    ;   cr3 -> 0x9000
    ; PMPL4 is a table with a single element that points to the beginning of 
    ; Page Directory Pointer Table (PDPE):
    ;   0x9000->0xa003
    ; The addresses are aligned at x1000 and '3' are flags.
    ; PDPE is a table with a single element that points to the beginning of 
    ; Page Directory Table (PDE):
    ;   0xa000->0xb003
    ; PDE is a table with a single element that points to the beginning of 
    ; Page Table (PTE):
    ;   0xb000->0xc003
    ; A 64 bit address is split into 6 equal parts and parts 2-5 are the index 
    ; into the above structure.  Each table can have 512 elements.
    ; For example, the virtual address 0x10000 gets translated to:
    ;    PMPL4  PDPE PDE  PTE
    ; 0x0  000  000  000  010  000         = 
    ;   PMPL4[0]->PDPE[0]->PDE[0]->PTE[16] = 
    ;   PTE[0xc000 + 0x10 * 8]= 0x0000000000010003.
	mov di, 0x9000
    push di
    mov ecx, 0x1000
    xor eax, eax
    cld
    rep stosd                         ; Transfers from EAX to [DI] ECX times.
    pop di

    lea eax, [es:di + 0x1000]         ; PDPE points to the beginning of PDPE.
    or eax, 3                         ; Present and writable.
    mov [es:di], eax
 
    lea eax, [es:di + 0x2000]         ; PDPE points to the beginning of PDE.
    or eax, 3                         ; Present and writable.
    mov [es:di + 0x1000], eax
 
    lea eax, [es:di + 0x3000]         ; PDE points to the beginning of PTE.
    or eax, 3                         ; Present and writable.
    mov [es:di + 0x2000], eax
 
    push di                           ; di pointed to PML4.
    lea di, [di + 0x3000]             ; di points to PTE.
    mov eax, 3                        ; Point at the first page,present,writable

.LoopThroughPageTable:
    mov [es:di], eax                  ; Write a page pointer within PTE[0].
    add eax, 0x1000                   ; Prepare to point to the next page.
    add di, 8                         ; The next page is going to be written 8
    cmp eax, 0x200000                 ; bytes from now.  Unless we have done 512
    jb .LoopThroughPageTable          ; entries already.
    pop di                            ; di points to PML4 again.
    
    mov al, 0xFF                      ; Disable IRQs
    out 0xA1, al                      ; Out 0xFF to 0xA1 and 0x21 to disable
    out 0x21, al                      ; all IRQs.
 
    lidt [triple_fault_idt]           ; Load a zero length IDT so that interrupt
                                      ; cause a triple fault.
    mov eax, 10100000b                ; Enter the long mode. Set the PAE and PGE
    mov cr4, eax                      ; bit. PAE is physical address extension.
                                      ; Long mode requires it.Page-global enable
                                      ; controls whether the page translation
                                      ; is global to all tasks.
    mov edx, edi                      ; Point CR3 at the PML4.  PWT is 0 which
    mov cr3, edx                      ; means that the highest level page table
                                      ; has writeback caching policy. PCD is 0
                                      ; which it means the highest level table
                                      ; is cacheable.
    mov ecx, 0xC0000080               ; Read from the Extended-feature-enable
    rdmsr                             ; model specific register (EFER MSR). 
 
    or eax, 0x00000100                ; Set the Long-mode-enable (LME) bit.
    wrmsr
 
    mov ebx, cr0                      ; Activate long mode by enabling paging
    or ebx,0x80000001                 ; (PG, the 31st bit) and protection (PE, 
    mov cr0, ebx                      ; the 0th bit) simultaneously.
    
    lgdt [gdt_descriptors]
    ; Load CS with 64 bit segment and flush the instruction cache:
    jmp CODE_SEG:.init_long_mode

[bits 64]
.init_long_mode:
	mov ax, DATA_SEG	; Point the segments to the data segment.
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ebp, 0x200000	; Set stack somewhere far away, otherwise its
	mov esp, ebp		; value is from before the protected mode.

	jmp long_mode

%endif  ; SWITCH_TO_64_LONG_MODE_ASM_
