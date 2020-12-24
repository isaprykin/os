#include <stdint.h>

struct registers {
   uint32_t ds;
   uint32_t edi, esi, ebp, esp, ebx, edx, ecx, eax;  // from `pushad`.
   uint32_t interrupt_number;
   uint32_t error_code;
   uint32_t eip, cs, eflags, sp, ss;
};

void isr_handler(const struct registers* registers);