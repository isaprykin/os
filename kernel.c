#include <stdint.h>

struct idt_interrupt_gate {
   uint16_t base_low;  // The lower 16 bits of the address to jump to when this interrupt fires.
   uint16_t segment_selector;  // Segment Selector for destination code segment.
   uint8_t  always_zero;
   // Flags: |P|DPL|DPL|0|D|1|1|1:
   //  -   P: Segment Present flag
   //  - DPL: Descriptor privelege level
   //  -   D: Size of gate: 1 = 32 bits; 0 = 16 bits
   uint8_t  flags;               
   uint16_t base_high;  // The upper 16 bits of the address to jump to.
} __attribute__((packed));

struct idt_descriptor {
   uint16_t limit;
   uint32_t base;
} __attribute__((packed));

extern void isr0();
extern void isr1();
extern void idt_flush(u32int);

struct idt_interrupt_gate idt_entries[2];
struct idt_descriptor idt_descriptor_ptr;

void idt_set_gate(uint8_t num, uint32_t base, uint16_t selector, uint8_t flags) {
   idt_entries[num].base_low = base & 0xFFFF;
   idt_entries[num].base_high = (base >> 16) & 0xFFFF;

   idt_entries[num].segment_selector = selector;
   idt_entries[num].always_zero = 0;
   idt_entries[num].flags = flags;
}

void init_idt() {
   idt_descriptor_ptr.limit = sizeof(struct idt_interrupt_gate) * 2;
   idt_descriptor_ptr.base  = (uint32_t) &idt_entries;  

   // 0x08 bytes is the offset into code segment in GDT that skips over the 
   // null segment.
   // 0x8E is 8 for Present 0 privelege level in |P|DPL|DPL|0 and 
   // E for 80386 32-bit interrupt gate type.
   idt_set_gate(0, (uint32_t)isr0, 0x08, 0x8E);
   idt_set_gate(1, (uint32_t)isr1, 0x08, 0x8E);

   idt_flush((uint32_t) &idt_descriptor_ptr);
}

int kernel_main() {
  init_idt();
  asm volatile ("int $0x1");
  return 0xCAFE;
}
