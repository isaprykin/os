#include <stdint.h>

struct IDTInterruptGate {
  // The lower 16 bits of the address to jump to when this interrupt fires.
  uint16_t base_low;
  uint16_t segment_selector;  // Segment Selector for destination code segment
  uint8_t always_zero;
  // Flags: |P|DPL|DPL|0|D|1|1|1:
  //  -   P: Segment Present flag
  //  - DPL: Descriptor privelege level
  //  -   D: Size of gate: 1 = 32 bits; 0 = 16 bits
  uint8_t flags;
  uint16_t base_middle;
  uint32_t base_high;
  uint32_t another_zero;
} __attribute__((packed));

struct IDTDescriptor {
  uint16_t limit;
  uint64_t base;
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
extern "C" void idt_flush(uint64_t);

IDTInterruptGate idt_entries[32];
IDTDescriptor idt_descriptor_ptr;

void idt_set_gate(uint8_t num, uint64_t base, uint16_t selector,
                  uint8_t flags) {
  idt_entries[num].base_low = base & 0xFFFF;
  idt_entries[num].base_middle = (base >> 16) & 0xFFFF;
  idt_entries[num].base_high = (base >> 32) & 0xFFFFFFFF;

  idt_entries[num].segment_selector = selector;
  idt_entries[num].another_zero = idt_entries[num].always_zero = 0;
  idt_entries[num].flags = flags;
}

void init_idt() {
  idt_descriptor_ptr.limit = sizeof(idt_entries);
  idt_descriptor_ptr.base = (uint64_t)&idt_entries;

  // 0x08 bytes is the offset into code segment in GDT that skips over the
  // null segment.
  // 0x8E is 8 for Present 0 privelege level in |P|DPL|DPL|0 and
  // E for 80386 32-bit interrupt gate type.
  idt_set_gate(0, (uint64_t)isr0, 0x08, 0x8E);
  idt_set_gate(1, (uint64_t)isr1, 0x08, 0x8E);
  idt_set_gate(2, (uint64_t)isr2, 0x08, 0x8E);
  idt_set_gate(3, (uint64_t)isr3, 0x08, 0x8E);
  idt_set_gate(4, (uint64_t)isr4, 0x08, 0x8E);
  idt_set_gate(5, (uint64_t)isr5, 0x08, 0x8E);
  idt_set_gate(6, (uint64_t)isr6, 0x08, 0x8E);
  idt_set_gate(7, (uint64_t)isr7, 0x08, 0x8E);
  idt_set_gate(8, (uint64_t)isr8, 0x08, 0x8E);
  idt_set_gate(9, (uint64_t)isr9, 0x08, 0x8E);
  idt_set_gate(10, (uint64_t)isr10, 0x08, 0x8E);
  idt_set_gate(11, (uint64_t)isr11, 0x08, 0x8E);
  idt_set_gate(12, (uint64_t)isr12, 0x08, 0x8E);
  idt_set_gate(13, (uint64_t)isr13, 0x08, 0x8E);
  idt_set_gate(14, (uint64_t)isr14, 0x08, 0x8E);
  idt_set_gate(15, (uint64_t)isr15, 0x08, 0x8E);
  idt_set_gate(16, (uint64_t)isr16, 0x08, 0x8E);
  idt_set_gate(17, (uint64_t)isr17, 0x08, 0x8E);
  idt_set_gate(18, (uint64_t)isr18, 0x08, 0x8E);
  idt_set_gate(19, (uint64_t)isr19, 0x08, 0x8E);
  idt_set_gate(20, (uint64_t)isr20, 0x08, 0x8E);
  idt_set_gate(21, (uint64_t)isr21, 0x08, 0x8E);
  idt_set_gate(22, (uint64_t)isr22, 0x08, 0x8E);
  idt_set_gate(23, (uint64_t)isr23, 0x08, 0x8E);
  idt_set_gate(24, (uint64_t)isr24, 0x08, 0x8E);
  idt_set_gate(25, (uint64_t)isr25, 0x08, 0x8E);
  idt_set_gate(26, (uint64_t)isr26, 0x08, 0x8E);
  idt_set_gate(27, (uint64_t)isr27, 0x08, 0x8E);
  idt_set_gate(28, (uint64_t)isr28, 0x08, 0x8E);
  idt_set_gate(29, (uint64_t)isr29, 0x08, 0x8E);
  idt_set_gate(30, (uint64_t)isr30, 0x08, 0x8E);
  idt_set_gate(31, (uint64_t)isr31, 0x08, 0x8E);

  idt_flush((uint64_t)&idt_descriptor_ptr);
}

struct SegmentDescriptor {
  uint16_t segment_limit_low;
  uint16_t base_address_low;
  uint8_t base_address_middle;
  uint8_t type_0 : 1;  // 8th bit.
  uint8_t type_1 : 1;
  uint8_t type_2 : 1;
  uint8_t type_3 : 1;
  uint8_t s : 1;
  uint8_t descriptor_privilege_level : 2;
  uint8_t present : 1;
  uint8_t segment_limit_high : 4;
  uint8_t available_to_software : 1;
  uint8_t long_attribute : 1;
  uint8_t default_operand_size : 1;
  uint8_t granularity : 1;
  uint8_t base_address_high;
} __attribute__((packed));

struct SystemSegmentDescriptor : public SegmentDescriptor {
  uint32_t base_address_high_extended;
  uint32_t reserved_zero = 0;
} __attribute__((packed));

SegmentDescriptor CreateCodeSegment(uint8_t default_operand_size,
                                    uint8_t long_attribute, uint8_t present,
                                    uint8_t descriptor_privilege_level,
                                    uint8_t conforming) {
  SegmentDescriptor descriptor{};
  descriptor.type_2 = conforming;
  descriptor.type_3 = 1;  // Ex bit set for "executable code".
  descriptor.s = 1;       // S bit set for "code or data".
  descriptor.descriptor_privilege_level = descriptor_privilege_level;
  descriptor.present = present;
  descriptor.long_attribute = long_attribute;
  descriptor.default_operand_size = default_operand_size;
  return descriptor;
}

SegmentDescriptor CreateDataSegment(uint8_t present) {
  SegmentDescriptor descriptor{};
  descriptor.type_1 = 1;  // RW bit for writable.  AMD manual suggests that this
  // is ignored in long-mode, yet bochs fails with "load_seg_reg(SS): not
  // writable data segment".  There are suggestions online that it's not so
  // clear.  I set it to be safe.
  descriptor.type_3 = 0;  // Ex bit unset for "non-executable data".
  descriptor.s = 1;       // S bit set for "code or data".
  descriptor.present = present;
  return descriptor;
}

SegmentDescriptor CreateNullSegment() { return SegmentDescriptor(); }

struct TaskStateSegment {
  uint32_t reserved_0;
  uint64_t privilege_stack[3];
  uint64_t reserved_1;
  uint64_t interrupt_stack_table[7];
  uint64_t reserved_2;
  uint16_t reserved_3;
  uint16_t iomap_base;
};

SystemSegmentDescriptor CreateTaskStateSegment(
    const TaskStateSegment& task_state_segment) {
  SystemSegmentDescriptor desciptor{};
  desciptor.segment_limit_low = sizeof(TaskStateSegment) - 1;
  // TODO: assert that segment_limit_low >= 67h and fits.
  desciptor.type_0 = 1;  // The type bits are hard coded for an available TSS.
  desciptor.type_1 = 0;
  desciptor.type_2 = 0;
  desciptor.type_3 = 1;
  desciptor.s = 0;  // Hard coded for TSS.
  desciptor.descriptor_privilege_level = 0;
  desciptor.present = 1;
  desciptor.available_to_software = 0;
  desciptor.granularity = 0;  // Segment limit is in terms of bytes.

  auto task_state_pointer = reinterpret_cast<uintptr_t>(&task_state_segment);
  desciptor.base_address_low = task_state_pointer & 0xFFFF;
  desciptor.base_address_middle = (task_state_pointer >> 16) & 0xFF;
  desciptor.base_address_high = (task_state_pointer >> 24) & 0xFF;
  desciptor.base_address_high_extended =
      (task_state_pointer >> 32) & 0xFFFFFFFF;

  return desciptor;
}

struct DescriptorTablePointer {
  uint16_t limit;
  const void* base_address;

  template <class DescriptorTable>
  static DescriptorTablePointer Point(const DescriptorTable& descriptor_table) {
    return {.limit = sizeof(descriptor_table) - 1,
            .base_address = &descriptor_table};
  }
} __attribute__((aligned(4))) __attribute__((packed));

struct GlobalDescriptorTable {
  GlobalDescriptorTable(SegmentDescriptor code, SegmentDescriptor data,
                        SegmentDescriptor null,
                        SystemSegmentDescriptor task_state)
      : null_segment(null),
        code_segment(code),
        data_segment(data),
        task_state_segment(task_state) {}

  SegmentDescriptor null_segment;
  SegmentDescriptor code_segment;
  SegmentDescriptor data_segment;
  SystemSegmentDescriptor task_state_segment;

  void Flush(const DescriptorTablePointer& descriptor_table_pointer) {
    auto task_state_segment_offset =
        reinterpret_cast<uintptr_t>(&task_state_segment) -
        reinterpret_cast<uintptr_t>(&null_segment);
    asm volatile(
        "xchgw %%bx, %%bx\n\tlgdt %[descriptor_table_pointer]\n\t"
        "pushq %[code_segment]\n\t"
        "leaq new_cs_register(%%rip), %%rax\n\t"
        "pushq %%rax\n\t"
        "lretq\n\t"
        "new_cs_register:\n\t"
        "movq %[data_segment], %%rax\n\t"
        "movq %%rax, %%ds\n\t"
        "movq %%rax, %%ss\n\t"
        "movq %%rax, %%es\n\t"
        "movq %%rax, %%fs\n\t"
        "movq %%rax, %%gs\n\t"
        "movq %[task_state_segment], %%rax\n\t"
        "ltr %%ax\n\t"
        : /* No outputs */
        : [ descriptor_table_pointer ] "m"(descriptor_table_pointer),
          [ code_segment ] "r"((&code_segment - &null_segment) *
                               sizeof(SegmentDescriptor)),
          [ data_segment ] "r"((&data_segment - &null_segment) *
                               sizeof(SegmentDescriptor)),
          [ task_state_segment ] "r"(task_state_segment_offset)
        : "memory");
  }
} __attribute__((aligned(4))) __attribute__((packed));

int kernel_main() {
  TaskStateSegment task_state_segment;
  GlobalDescriptorTable gdt(
      CreateCodeSegment(/* default_operand_size = */ 0,
                        /* long_attribute = */ 1, /* present = */ 1,
                        /* descriptor_privilege_level = */ 0,
                        /* conforming = */ 0),
      CreateDataSegment(/* present = */ 1), CreateNullSegment(),
      CreateTaskStateSegment(task_state_segment));
  auto gdt_pointer = DescriptorTablePointer::Point(gdt);
  gdt.Flush(gdt_pointer);
  init_idt();
  return 0xCAFE;
}
