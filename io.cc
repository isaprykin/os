#include "io.h"

void out8(uint16_t port, uint8_t value) {
  asm volatile("outb %1, %0" : : "dN"(port), "a"(value));
}

uint8_t in8(uint16_t port) {
  uint8_t value;
  asm volatile("inb %1, %0" : "=a"(value) : "dN"(port));
  return value;
}
