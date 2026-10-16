// Pin and timing constants for the fume extractor.
#pragma once
#include <stdint.h>

#define FW_VERSION "0.1.0"

// SparkFun Thing Plus ESP32-S3 header. Arduino-core names (GPIOn) differ from the
// ESP32 GPIO numbers, so both are noted. Strapping pins (0, 3, 45, 46) are avoided,
// as are I2C (8/9), USB (19/20), UART0 (43/44) and flash/PSRAM pins (26-37).
//
// Pad names below use raw ESP32 IO numbers, which SparkFun's hardware overview says is how
// the PTH pads are labeled ("pad 4" = IO4). The Arduino aliases GPIO0..GPIO6 in
// pins_arduino.h are a different scheme (GPIO3 = IO5, GPIO4 = IO4) and are not used here.
//
// Fan PWM: IO4 (pad "4"). Plain GPIO with no boot-time function or
// default pull. It drives the 2N7000 gate (inverted: gate high pulls the fan PWM line
// low), and the 100k gate pulldown keeps the fan at full speed (fail-safe) until
// setup() runs.
constexpr int PIN_FAN_PWM = 4;

// Fan tach: IO5 (pad "5"; Arduino alias GPIO3, not to be confused with IO3, a strapping
// pin). Plain GPIO, adjacent to the PWM pin on the header, and any pin can take a
// GPIO interrupt. External 10k pull-up to 3V3 (the fan tach is open-collector).
constexpr int PIN_FAN_TACH = 5;

// Drives the regulator that powers the Qwiic rail (OLED + Twist). GPIO45 is a strapping
// pin but is the board's fixed Qwiic enable (Q_EN), so it is forced by the hardware.
constexpr int PIN_QWIIC_PWR = 45;

constexpr uint32_t PWM_HZ = 25000;   // Intel 4-wire fan spec target
constexpr uint8_t PWM_BITS = 8;
constexpr uint32_t RPM_WINDOW_MS = 1000;
constexpr uint32_t LOOP_MS = 20;
