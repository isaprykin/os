#include <stdint.h>

struct IDTInterruptGate {
   // The lower 16 bits of the address to jump to when this interrupt fires.
   uint16_t base_low;
   uint16_t segment_selector;  // Segment Selector for destination code segment
   uint8_t  always_zero;
   // Flags: |P|DPL|DPL|0|D|1|1|1:
   //  -   P: Segment Present flag
   //  - DPL: Descriptor privelege level
   //  -   D: Size of gate: 1 = 32 bits; 0 = 16 bits
   uint8_t  flags;               
   uint16_t base_high;  // The upper 16 bits of the address to jump to.
} __attribute__((packed));

struct IDTDescriptor {
   uint16_t limit;
   uint32_t base;
} __attribute__((packed));

extern "C" void isr0();
extern "C" void isr1();
extern "C" void isr2();
extern "C" void isr3();
extern "C" void isr4();
extern "C" void isr5();
extern "C" void isr6();
extern "C" void isr7();
extern "C" void isr8();
extern "C" void isr9();
extern "C" void isr10();
extern "C" void isr11();
extern "C" void isr12();
extern "C" void isr13();
extern "C" void isr14();
extern "C" void isr15();
extern "C" void isr16();
extern "C" void isr17();
extern "C" void isr18();
extern "C" void isr19();
extern "C" void isr20();
extern "C" void isr21();
extern "C" void isr22();
extern "C" void isr23();
extern "C" void isr24();
extern "C" void isr25();
extern "C" void isr26();
extern "C" void isr27();
extern "C" void isr28();
extern "C" void isr29();
extern "C" void isr30();
extern "C" void isr31();
extern "C" void idt_flush(uint32_t);

IDTInterruptGate idt_entries[32];
IDTDescriptor idt_descriptor_ptr;

void idt_set_gate(uint8_t num, uint32_t base, uint16_t selector,
                  uint8_t flags) {
   idt_entries[num].base_low = base & 0xFFFF;
   idt_entries[num].base_high = (base >> 16) & 0xFFFF;

   idt_entries[num].segment_selector = selector;
   idt_entries[num].always_zero = 0;
   idt_entries[num].flags = flags;
}

void init_idt() {
   idt_descriptor_ptr.limit = sizeof(idt_entries);
   idt_descriptor_ptr.base  = (uint32_t) &idt_entries;  

   // 0x08 bytes is the offset into code segment in GDT that skips over the
   // null segment.
   // 0x8E is 8 for Present 0 privelege level in |P|DPL|DPL|0 and 
   // E for 80386 32-bit interrupt gate type.
   idt_set_gate( 0, (uint32_t)isr0 , 0x08, 0x8E);
   idt_set_gate( 1, (uint32_t)isr1 , 0x08, 0x8E);
   idt_set_gate( 2, (uint32_t)isr2 , 0x08, 0x8E);
   idt_set_gate( 3, (uint32_t)isr3 , 0x08, 0x8E);
   idt_set_gate( 4, (uint32_t)isr4 , 0x08, 0x8E);
   idt_set_gate( 5, (uint32_t)isr5 , 0x08, 0x8E);
   idt_set_gate( 6, (uint32_t)isr6 , 0x08, 0x8E);
   idt_set_gate( 7, (uint32_t)isr7 , 0x08, 0x8E);
   idt_set_gate( 8, (uint32_t)isr8 , 0x08, 0x8E);
   idt_set_gate( 9, (uint32_t)isr9 , 0x08, 0x8E);
   idt_set_gate(10, (uint32_t)isr10, 0x08, 0x8E);
   idt_set_gate(11, (uint32_t)isr11, 0x08, 0x8E);
   idt_set_gate(12, (uint32_t)isr12, 0x08, 0x8E);
   idt_set_gate(13, (uint32_t)isr13, 0x08, 0x8E);
   idt_set_gate(14, (uint32_t)isr14, 0x08, 0x8E);
   idt_set_gate(15, (uint32_t)isr15, 0x08, 0x8E);
   idt_set_gate(16, (uint32_t)isr16, 0x08, 0x8E);
   idt_set_gate(17, (uint32_t)isr17, 0x08, 0x8E);
   idt_set_gate(18, (uint32_t)isr18, 0x08, 0x8E);
   idt_set_gate(19, (uint32_t)isr19, 0x08, 0x8E);
   idt_set_gate(20, (uint32_t)isr20, 0x08, 0x8E);
   idt_set_gate(21, (uint32_t)isr21, 0x08, 0x8E);
   idt_set_gate(22, (uint32_t)isr22, 0x08, 0x8E);
   idt_set_gate(23, (uint32_t)isr23, 0x08, 0x8E);
   idt_set_gate(24, (uint32_t)isr24, 0x08, 0x8E);
   idt_set_gate(25, (uint32_t)isr25, 0x08, 0x8E);
   idt_set_gate(26, (uint32_t)isr26, 0x08, 0x8E);
   idt_set_gate(27, (uint32_t)isr27, 0x08, 0x8E);
   idt_set_gate(28, (uint32_t)isr28, 0x08, 0x8E);
   idt_set_gate(29, (uint32_t)isr29, 0x08, 0x8E);
   idt_set_gate(30, (uint32_t)isr30, 0x08, 0x8E);
   idt_set_gate(31, (uint32_t)isr31, 0x08, 0x8E);

   idt_flush((uint32_t) &idt_descriptor_ptr);
}

int kernel_main() {
  init_idt();
  asm volatile ("int $0x1f");
  return 0xCAFE;
}
