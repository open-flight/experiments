// Pin and timing constants for the fume extractor.
#pragma once
#include <stdint.h>

#define FW_VERSION "0.1.0"

#if defined(ARDUINO_ESP32_DEV)
// Generic ESP32 DevKit (ESP32-WROOM-32, "ESP32 Dev Module"). No Qwiic port: wire a Qwiic
// jumper cable to 3V3, GND, SDA = GPIO21, SCL = GPIO22 (Wire's defaults on this board).
// Strapping pins (0, 2, 5, 12, 15) are avoided.
//
// Fan PWM: GPIO4 (pin "D4"/"4"). Same role and fail-safe as on the Thing Plus.
constexpr int PIN_FAN_PWM = 4;

// Fan tach: GPIO34 (pin "D34"/"34"). Input-only with no internal pull, which is fine:
// the external 10k pull-up to 3V3 does the job. GPIO5 is a strapping pin here.
constexpr int PIN_FAN_TACH = 34;

// No switched Qwiic rail on a DevKit; the OLED and Twist run from 3V3 all the time.
constexpr int PIN_QWIIC_PWR = -1;

#else
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

#endif

constexpr uint32_t PWM_HZ = 25000;   // Intel 4-wire fan spec target
constexpr uint8_t PWM_BITS = 8;
constexpr uint32_t RPM_WINDOW_MS = 1000;
constexpr uint32_t LOOP_MS = 20;
