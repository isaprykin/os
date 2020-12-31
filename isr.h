#ifndef ISR_H_
#define ISR_H_

#include <stdint.h>

struct Registers {
   uint64_t ds;
   uint64_t rdi, rsi, rbp, rsp, rbx, rdx, rcx, rax;
   uint64_t interrupt_number;
   uint64_t error_code;
   uint64_t rip, cs, eflags, sp, ss;
};

extern "C" void isr_handler(const Registers* registers);

#endif  // ISR_H_
