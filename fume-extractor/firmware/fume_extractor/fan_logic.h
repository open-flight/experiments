// Pure fan control logic: no Arduino includes, so the sketch and host tests share it.
#pragma once
#include <cstdint>

namespace fan {

constexpr int kMaxLevel = 10;
constexpr int kDefaultLevel = 5;

struct Rgb {
  uint8_t r, g, b;
  bool operator==(const Rgb& o) const { return r == o.r && g == o.g && b == o.b; }
};

inline Rgb colorFor(int level) {
  if (level <= 0) return {0, 0, 8};
  if (level > kMaxLevel) level = kMaxLevel;
  float t = (level - 1) / 9.0f;
  float r = 0, g = 0, b = 0;
  if (t <= 0.5f) { float u = t / 0.5f; g = 255 * u; b = 255 * (1 - u); }          // blue -> green
  else { float u = (t - 0.5f) / 0.5f; r = 255 * u; g = 255 * (1 - u); }            // green -> red
  return {(uint8_t)(r + 0.5f), (uint8_t)(g + 0.5f), (uint8_t)(b + 0.5f)};
}

// Tach gives 2 pulses per revolution.
inline uint32_t rpmFromPulses(uint32_t pulses, uint32_t windowMs) {
  return windowMs == 0 ? 0 : pulses * 30000u / windowMs;
}

class Controller {
 public:
  explicit Controller(int savedLevel, uint32_t nowMs) {
    level_ = (savedLevel < 0 || savedLevel > kMaxLevel) ? kDefaultLevel : savedLevel;
    if (level_ > 0) lastNonZero_ = level_;
    lastInputMs_ = lastChangeMs_ = nowMs;
    lastOn_ = level_ > 0;
    onSinceMs_ = nowMs;
  }

  void turn(int detents, uint32_t nowMs) {
    lastInputMs_ = nowMs;
    int next = level_ + detents;
    if (next < 0) next = 0;
    if (next > kMaxLevel) next = kMaxLevel;
    setLevel(next, nowMs);
  }

  void click(uint32_t nowMs) {
    lastInputMs_ = nowMs;
    setLevel(level_ > 0 ? 0 : lastNonZero_, nowMs);
  }

  int level() const { return level_; }
  int percent() const { return level_ * 10; }
  uint8_t gateDuty8() const { return (uint8_t)(255 - (percent() * 255 + 50) / 100); }

  // Call once per RPM update.
  bool stalled(uint32_t rpm, uint32_t nowMs) {
    if (level_ < 3 || rpm > 0) { zeroActive_ = false; return false; }
    if (nowMs - onSinceMs_ < 3000) return false;
    if (!zeroActive_) { zeroActive_ = true; zeroSinceMs_ = nowMs; }
    return nowMs - zeroSinceMs_ >= 3000;
  }

  bool dimmed(uint32_t nowMs) const { return nowMs - lastInputMs_ >= 600000; }

  bool takeSave(uint32_t nowMs) {
    if (!dirty_ || nowMs - lastChangeMs_ < 2000) return false;
    dirty_ = false;
    return true;
  }

 private:
  void setLevel(int next, uint32_t nowMs) {
    if (next == level_) return;
    level_ = next;
    lastChangeMs_ = nowMs;
    dirty_ = true;
    if (level_ > 0) lastNonZero_ = level_;
    bool on = level_ > 0;
    if (on && !lastOn_) onSinceMs_ = nowMs;
    lastOn_ = on;
  }

  int level_ = kDefaultLevel;
  int lastNonZero_ = kDefaultLevel;
  uint32_t lastInputMs_ = 0, lastChangeMs_ = 0, onSinceMs_ = 0, zeroSinceMs_ = 0;
  bool dirty_ = false, lastOn_ = false, zeroActive_ = false;
};

}  // namespace fan
