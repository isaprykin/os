#include "isr.h"

void isr_handler(const struct registers* registers) {
    int a = registers->interrupt_number;
}