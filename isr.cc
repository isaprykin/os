#include "isr.h"

void isr_handler(const Registers* registers) {
    int a __attribute__((unused)) = registers->interrupt_number;
}
