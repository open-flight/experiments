// Bare EC11-style rotary encoder with push switch, wired straight to GPIOs (bench builds
// without a Qwiic Twist). A/B and the switch use internal pull-ups; common pins go to GND.
#pragma once
#include <Arduino.h>
#include "config.h"

namespace plain_encoder {

static volatile int32_t g_steps = 0;
static volatile uint8_t g_state = 0;

// Quadrature transition table: index = (prev << 2) | now, value = -1, 0 or +1.
static const int8_t kTable[16] = {0, -1, 1, 0, 1, 0, 0, -1, -1, 0, 0, 1, 0, 1, -1, 0};

static void IRAM_ATTR onEdge() {
  uint8_t now = (digitalRead(PIN_ENC_A) << 1) | digitalRead(PIN_ENC_B);
  g_steps = g_steps + kTable[(g_state << 2) | now];
  g_state = now;
}

inline bool enabled() { return PIN_ENC_A >= 0 && PIN_ENC_B >= 0; }

inline void begin() {
  if (!enabled()) return;
  pinMode(PIN_ENC_A, INPUT_PULLUP);
  pinMode(PIN_ENC_B, INPUT_PULLUP);
  if (PIN_ENC_SW >= 0) pinMode(PIN_ENC_SW, INPUT_PULLUP);
  g_state = (digitalRead(PIN_ENC_A) << 1) | digitalRead(PIN_ENC_B);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_A), onEdge, CHANGE);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_B), onEdge, CHANGE);
}

// Whole detents turned since the last call (clockwise positive). Leftover partial steps
// carry over, so a slow turn is never lost.
inline int takeDetents() {
  if (!enabled()) return 0;
  noInterrupts();
  int32_t s = g_steps;
  int32_t d = s / ENC_STEPS_PER_DETENT;
  g_steps = s - d * ENC_STEPS_PER_DETENT;
  interrupts();
  return (int)(d * ENC_DIRECTION);
}

// True once per press (falling edge, debounced). Call from loop().
inline bool takeClick(uint32_t nowMs) {
  static bool stable = true, last = true;
  static uint32_t changedMs = 0;
  if (!enabled() || PIN_ENC_SW < 0) return false;
  bool raw = digitalRead(PIN_ENC_SW);
  if (raw != last) { last = raw; changedMs = nowMs; }
  if (raw != stable && nowMs - changedMs >= 25) {
    stable = raw;
    return !stable;  // pressed = low
  }
  return false;
}

}  // namespace plain_encoder
