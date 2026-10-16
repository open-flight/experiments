#include <cstdio>
#include <cstdint>
#include "fan_logic.h"
using namespace fan;

static int fails = 0;
static void expect(bool c, const char* what) { printf("  %s %s\n", c ? "ok  " : "FAIL", what); if (!c) fails++; }

static void test_invalid_saved_level() {
  expect(Controller(-1, 0).level() == 5, "saved -1 -> default 5");
  expect(Controller(11, 0).level() == 5, "saved 11 -> default 5");
  expect(Controller(0, 0).level() == 0, "saved 0 stays 0");
  expect(Controller(7, 0).level() == 7, "saved 7 stays 7");
}
static void test_turn_clamps() {
  Controller c(5, 0); c.turn(20, 1); expect(c.level() == 10, "clamps at 10");
  c.turn(-50, 2); expect(c.level() == 0, "clamps at 0");
}
static void test_percent_and_duty() {
  Controller a(0, 0); expect(a.percent() == 0 && a.gateDuty8() == 255, "level 0: 0%, duty 255");
  Controller b(10, 0); expect(b.percent() == 100 && b.gateDuty8() == 0, "level 10: 100%, duty 0");
  Controller m(5, 0); expect(m.percent() == 50 && m.gateDuty8() == 127, "level 5: 50%, duty 127");
}
static void test_click_toggle() {
  Controller a(7, 0); a.click(1); expect(a.level() == 0, "7 click -> 0"); a.click(2); expect(a.level() == 7, "click -> 7");
  Controller b(7, 0); b.turn(-4, 1); expect(b.level() == 3, "turned to 3");
  b.click(2); expect(b.level() == 0, "3 click -> 0"); b.click(3); expect(b.level() == 3, "click -> 3");
  Controller c(0, 0); c.click(1); expect(c.level() == 5, "0 click -> 5");
}
static void test_save_debounce() {
  Controller c(5, 0);
  expect(!c.takeSave(100000), "no change: never saves");
  c.turn(1, 1000);
  expect(!c.takeSave(2999), "not at 2999");
  expect(c.takeSave(3000), "at 3000");
  expect(!c.takeSave(4000), "only once");
  c.turn(1, 5000);
  expect(!c.takeSave(6999), "second: not at 6999");
  expect(c.takeSave(7000), "second: fires");
}
static void test_stall_basic() {
  Controller c(5, 0);
  bool early = false, late = true;
  for (uint32_t t = 0; t < 6000; t += 100) if (c.stalled(0, t)) early = true;
  expect(!early, "not stalled before 6000");
  for (uint32_t t = 6000; t < 7000; t += 100) if (!c.stalled(0, t)) late = false;
  expect(late, "stalled from 6000");
  expect(!c.stalled(500, 7000), "clears when rpm > 0");
}
static void test_stall_off_never() {
  Controller c(0, 0); bool s = false;
  for (uint32_t t = 0; t <= 60000; t += 100) if (c.stalled(0, t)) s = true;
  expect(!s, "off never stalled");
  Controller d(2, 0); s = false;
  for (uint32_t t = 0; t <= 60000; t += 100) if (d.stalled(0, t)) s = true;
  expect(!s, "level 2 never stalled");
}
static void test_stall_spinup_grace() {
  Controller c(0, 0); c.turn(5, 10000);
  bool early = false;
  for (uint32_t t = 10000; t <= 15900; t += 100) if (c.stalled(0, t)) early = true;
  expect(!early, "false through 15900");
  expect(c.stalled(0, 16000), "true at 16000");
}
static void test_dim() {
  Controller c(5, 0);
  expect(!c.dimmed(599999), "not dimmed at 599999");
  expect(c.dimmed(600000), "dimmed at 600000");
  c.turn(0, 600000); expect(!c.dimmed(600001), "turn(0) resets");
  expect(c.dimmed(1200000), "dims again");
  c.click(1200000); expect(!c.dimmed(1200001), "click resets");
}
static void test_colors() {
  expect(colorFor(0) == (Rgb{0, 0, 8}), "level 0 dim blue");
  expect(colorFor(1) == (Rgb{0, 0, 255}), "level 1 blue");
  expect(colorFor(10) == (Rgb{255, 0, 0}), "level 10 red");
  expect(colorFor(5).g > colorFor(5).r, "level 5 greenish");
}
static void test_rpm() {
  expect(rpmFromPulses(60, 1000) == 1800, "60 pulses/s = 1800");
  expect(rpmFromPulses(0, 1000) == 0, "0 pulses");
  expect(rpmFromPulses(5, 0) == 0, "zero window");
}
static void test_millis_wrap() {
  const uint32_t t0 = 0xFFFFF000u;
  Controller c(5, t0);
  bool early = false;
  for (uint32_t k = 0; k < 60; k++) if (c.stalled(0, t0 + k * 100)) early = true;
  expect(!early, "wrap: false for k<60");
  expect(c.stalled(0, t0 + 60 * 100), "wrap: true at k=60");
  expect(!c.dimmed(t0 + 0x2000), "wrap: not dimmed");
}

int main() {
  test_invalid_saved_level(); test_turn_clamps(); test_percent_and_duty(); test_click_toggle();
  test_save_debounce(); test_stall_basic(); test_stall_off_never(); test_stall_spinup_grace();
  test_dim(); test_colors(); test_rpm(); test_millis_wrap();
  printf(fails ? "%d FAILED\n" : "all passed\n", fails);
  return fails ? 1 : 0;
}
