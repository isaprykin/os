#ifndef ISR_H_
#define ISR_H_

#include <stdint.h>

struct Registers {
   uint32_t ds;
   uint32_t edi, esi, ebp, esp, ebx, edx, ecx, eax;  // from `pushad`.
   uint32_t interrupt_number;
   uint32_t error_code;
   uint32_t eip, cs, eflags, sp, ss;
};

extern "C" void isr_handler(const Registers* registers);

#endif  // ISR_H_
