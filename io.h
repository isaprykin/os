#ifndef IO_H_
#define IO_H_

#include <stdint.h>

constexpr uint8_t PIC_1_CONTROL = 0x20;
constexpr uint8_t PIC_1_DATA = 0x21;
constexpr uint8_t PIC_2_CONTROL = 0xA0;
constexpr uint8_t PIC_2_DATA = 0xA1;

void out8(uint16_t port, uint8_t value);
uint8_t in8(uint16_t port);

#endif  // IO_H_
