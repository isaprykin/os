#include "isr.h"

#include "io.h"

void isr_handler(const Registers* registers) {
  // Send End-Of-Interrupt.
  if (registers->interrupt_number > 31) {
    out8(PIC_1_CONTROL, 0x20);
    if (registers->interrupt_number >= 40) {
      out8(PIC_2_CONTROL, 0x20);
    }
  }
}
