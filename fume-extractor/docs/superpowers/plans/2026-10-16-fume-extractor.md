# USB-C Desk Fume Extractor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a USB-C powered 120 mm desk fume extractor. A Qwiic Twist dial sets the fan speed, a Qwiic OLED shows it, and it lives in a printed OpenSCAD case. The whole project is open-sourced in `~/code/experiments/fume-extractor`.

**Architecture:** All decision logic lives in one Arduino-free header, `fan_logic.h`: speed levels, click toggle, PWM duty, stall detection, dimming, save debounce and color. It is unit-tested on the host with g++. The `.ino` is thin glue: LEDC PWM, a tach ISR, OLED, Twist and `Preferences`. The case is a single parametric OpenSCAD file with a `part` selector and collision-check targets, following `~/code/open-gps/case`.

**Tech Stack:** Arduino ESP32 core 3.x (`esp32:esp32:sparkfun_esp32s3_thing_plus`), SparkFun Qwiic OLED Arduino Library, SparkFun Qwiic Twist Arduino Library, C++17 host tests, OpenSCAD (`/opt/homebrew/bin/openscad`), arduino-cli (`/opt/homebrew/bin/arduino-cli`).

**Spec:** `fume-extractor/docs/superpowers/specs/2026-10-16-fume-extractor-design.md`

## Global Constraints

- Power is a USB-C wall charger into the Thing Plus USB-C. The fan's 5 V comes from the Thing Plus VUSB pin. No PD, no 12 V, no buck converter.
- Fan: Noctua NF-A12x25 5V PWM. 25 kHz PWM, 0% PWM = 0 rpm, tach gives 2 pulses per revolution.
- The PWM goes through a logic-level N-MOSFET (2N7000) as open-drain, so the gate duty is inverted. Add a 100 kΩ gate pull-down so a reset or unflashed board runs the fan at full speed instead of floating.
- Tach: 10 kΩ pull-up to 3.3 V.
- Qwiic addresses: OLED 0x3D, Twist 0x3F. Drive GPIO45 high at boot to power the Qwiic rail.
- Levels: 0 (Off) to 10, shown as 0–100% in 10% steps.
- Click toggles Off ↔ the last non-zero level.
- Power-on resumes the last saved level. On first boot (nothing saved, or an invalid value) it starts at level 5.
- Stall: if the level is ≥ 3 and RPM = 0 for 3 s (the clock starts after a 3 s spin-up grace), show `FAN?` and blink the Twist red.
- Dim the OLED after 10 min with no dial input. The fan is unaffected.
- Twist color: dim blue (0,0,8) when Off, blue → green → red from level 1 to level 10.
- Case: PETG, about 140 × 140 mm front. 130 × 130 mm filter in a magnetic front frame. Air goes in at the front and out a guarded rear grille. Raised control pod on top. Rear kickstand at 0°, 15° and 30°.
- License: one AGPL-3.0 `LICENSE` at the repo root (copy `~/code/open-gps/LICENSE`).
- Amazon links are plain. The SparkFun wishlist URL is the placeholder `<SPARKFUN_WISHLIST_URL>` until the owner makes it. Use `affiliate_code=rfxlS0eYyY` on SparkFun product links, as open-gps does.

## Review Focus

1. **Dial spun hard past either end.** It should clamp at Off and at 100%, never wrap around. Covered by `test_turn_clamps` in Task 1.
2. **Unplugged a second after changing the speed.** It should come back at the new speed if the save had fired, or the old speed if not, and never at a garbage value. The save is debounced 2 s after the last change to limit flash wear, and invalid saved values fall back to 5. Covered by `test_invalid_saved_level` and `test_save_debounce` in Task 1.
3. **Fan unplugged or jammed.** It should show `FAN?`, but not when Off and not during spin-up from Off. Covered by `test_stall_*` in Task 1.
4. **OLED or Twist cable unplugged.** The fan should keep running at the saved level and the firmware should not hang. Covered by the Task 2 bench check (boot with the OLED cable removed).
5. **`millis()` wraparound after about 49 days.** All timing should use unsigned subtraction. Covered by `test_millis_wrap` in Task 1.

---

### Task 1: Repo scaffold and fan logic (host-tested)

**Files:**
- Create: `README.md` (repo root: one-line intro and a project index with one row for fume-extractor), `LICENSE` (copy of open-gps's AGPL-3.0), `.gitignore` (`test_fan_logic`, `*.dSYM`, `build/`)
- Create: `fume-extractor/firmware/fume_extractor/fan_logic.h`
- Create: `fume-extractor/firmware/test/test_fan_logic.cpp`, `fume-extractor/firmware/test/Makefile`

**Interfaces:**
- Produces (all in `namespace fan`, header-only, no Arduino includes):
  - `constexpr int kMaxLevel = 10; constexpr int kDefaultLevel = 5;`
  - `struct Rgb { uint8_t r, g, b; bool operator==(const Rgb&) const; };`
  - `Rgb colorFor(int level);`
  - `uint32_t rpmFromPulses(uint32_t pulses, uint32_t windowMs);` returns `pulses * 30000 / windowMs` (2 pulses per rev), or 0 if `windowMs == 0`.
  - `class Controller`:
    - `explicit Controller(int savedLevel, uint32_t nowMs);`
    - `void turn(int detents, uint32_t nowMs);`
    - `void click(uint32_t nowMs);`
    - `int level() const; int percent() const;`
    - `uint8_t gateDuty8() const;` returns the inverted 8-bit duty: `255 - (percent()*255 + 50)/100`.
    - `bool stalled(uint32_t rpm, uint32_t nowMs);` call once per RPM update. True when level ≥ 3, at least 3000 ms since spin-up (construction with level > 0, or a 0 → >0 change), and rpm has been 0 on every call for ≥ 3000 ms after that grace.
    - `bool dimmed(uint32_t nowMs) const;` true once 600000 ms have passed since the last input (construction counts as input).
    - `bool takeSave(uint32_t nowMs);` returns true exactly once, when ≥ 2000 ms have passed since the last level change and that change hasn't been saved yet.

- [ ] **Step 1: Write the failing tests** in `test_fan_logic.cpp`, using a tiny `expect(cond, name)` helper that counts failures and has `main` return nonzero on any failure (same style as `open-gps/firmware/test/sim.cpp`):
  - `test_invalid_saved_level`: `Controller(-1,0).level()==5`, `Controller(11,0).level()==5`, `Controller(0,0).level()==0`, `Controller(7,0).level()==7`.
  - `test_turn_clamps`: from 5, `turn(+20)` gives 10; `turn(-50)` gives 0.
  - `test_percent_and_duty`: level 0 gives `percent()==0` and `gateDuty8()==255`. Level 10 gives 100 and 0. Level 5 gives 50 and 127.
  - `test_click_toggle`: start 7, click → 0, click → 7. Start 7, `turn(-4)` to 3, click → 0, click → 3. `Controller(0,0)` click → 5.
  - `test_save_debounce`: after `turn(+1, 1000)`, `takeSave(2999)` is false, `takeSave(3000)` is true, and `takeSave(4000)` is false. After another turn, it fires again 2 s later. With no change since construction, `takeSave` is never true.
  - `test_stall_basic`: level 5 from construction at t=0, which counts as spin-up. Call `stalled(0, t)` every 100 ms: false for t < 6000 (3 s grace plus 3 s at zero), true at t ≥ 6000. It goes false as soon as rpm > 0.
  - `test_stall_off_never`: level 0 with rpm 0 for 60 s is never stalled. Level 2 (20%) is never stalled either.
  - `test_stall_spinup_grace`: Off → `turn(+5, 10000)`. Call `stalled(0, t)` every 100 ms: false through 15900, true at 16000.
  - `test_dim`: not dimmed at 599999, dimmed at 600000; `turn(0, t)` or `click` resets it.
  - `test_colors`: `colorFor(0)=={0,0,8}`, `colorFor(1)=={0,0,255}`, `colorFor(10)=={255,0,0}`; `colorFor(5).g > colorFor(5).r`.
  - `test_rpm`: `rpmFromPulses(60, 1000)==1800`, `rpmFromPulses(0,1000)==0`, `rpmFromPulses(5,0)==0`.
  - `test_millis_wrap`: construct at `t0 = 0xFFFFF000` with level 5; calling `stalled(0, t0 + k*100)` (uint32 arithmetic) is false for k < 60 and true at k = 60, which is after the wrap; `dimmed(t0 + 0x2000)` is false.

  The Makefile copies open-gps's: `$(SAN)` (ubsan only on Darwin), `g++ -std=c++17 -O0 -g -Wall -Wextra -I../fume_extractor -o test_fan_logic test_fan_logic.cpp && ./test_fan_logic`.

- [ ] **Step 2: Run** `make -C fume-extractor/firmware/test`. Expected: compile error, `fan_logic.h` not found.

- [ ] **Step 3: Implement `fan_logic.h`.** Track `lastInputMs_`, `lastChangeMs_`, `dirty_`, `lastOn_`, `onSinceMs_` (set when the level goes from 0 to >0) and `zeroSinceMs_`. Color: for level 1–10, `t=(level-1)/9`. Blue→green over t∈[0,0.5], green→red over [0.5,1], linear per channel. `turn(0, now)` counts as input but not as a change.

- [ ] **Step 4: Run** `make -C fume-extractor/firmware/test`. Expected: every line `ok`, exit 0.

- [ ] **Step 5: Commit** `git add README.md LICENSE .gitignore fume-extractor/firmware && git commit -m "fume-extractor: fan logic with host tests"`

### Task 2: Firmware glue and bench wiring

**Files:**
- Create: `fume-extractor/firmware/fume_extractor/config.h` (pin and timing constants), `fume-extractor/firmware/fume_extractor/fume_extractor.ino`
- Create: `fume-extractor/docs/wiring.md` (ASCII wiring diagram of the protoboard)

**Interfaces:**
- Consumes: everything in `fan::` from Task 1.
- `config.h` defines `PIN_FAN_PWM`, `PIN_FAN_TACH`, `PIN_QWIIC_PWR = 45`, `PWM_HZ = 25000`, `PWM_BITS = 8`, `RPM_WINDOW_MS = 1000`, and `FW_VERSION "0.1.0"`. Choose PWM and tach from free GPIOs on the Thing Plus ESP32-S3 header (check SparkFun's pinout; avoid strapping pins 0/3/45/46). Put the reason for each choice in a comment.

- [ ] **Step 1: Write `wiring.md`.** Cover:
  - VUSB → fan pin 2 (+5 V).
  - GND → fan pin 1.
  - Fan pin 3 (tach) → `PIN_FAN_TACH`, with a 10 kΩ pull-up to 3V3.
  - Fan pin 4 (PWM) → 2N7000 drain. Source → GND. Gate → `PIN_FAN_PWM` through 100 Ω, with 100 kΩ gate→GND.
  - Qwiic chain: Thing Plus → OLED → Twist.

- [ ] **Step 2: Implement `fume_extractor.ino`.**
  - `setup()`: drive `PIN_QWIIC_PWR` high, delay 50 ms, `Wire.begin()`.
  - Start each Qwiic device with `begin()`, but continue if either is missing.
  - Read the saved level with `Preferences` namespace `"fume"`, key `"level"`, default -1.
  - Construct `fan::Controller`.
  - Start the PWM with `ledcAttach(PIN_FAN_PWM, PWM_HZ, PWM_BITS)` and write `gateDuty8()`.
  - Attach the tach ISR on `FALLING`, counting into a `volatile uint32_t`.
  - Print `oled=%d twist=%d level=%d` to Serial at 115200.
  - `loop()`, every 20 ms:
    - Read `twist.getDiff()` and `twist.isClicked()` and feed them to the controller.
    - On a level change, write the duty and color.
    - Every `RPM_WINDOW_MS`, snapshot the pulse count with interrupts off and compute RPM.
    - Call `stalled()`; while stalled, blink the Twist red at 2 Hz.
    - If `takeSave()` returns true, write the level to Preferences.
    - Redraw the OLED: the percentage centered in the largest font (`OFF` at level 0), `#### rpm` small at the bottom, and `FAN?` replacing the RPM when stalled.
    - When `dimmed()`, only redraw on change; also lower the contrast if the library exposes it, otherwise blank to just the small percentage.

- [ ] **Step 3: Compile.** Run:
  ```bash
  arduino-cli lib install "SparkFun Qwiic OLED Arduino Library" "SparkFun Qwiic Twist Arduino Library"
  arduino-cli compile --fqbn esp32:esp32:sparkfun_esp32s3_thing_plus fume-extractor/firmware/fume_extractor
  ```
  Expected: `Sketch uses …`, exit 0. Re-run `make -C fume-extractor/firmware/test`; it should still pass.

- [ ] **Step 4: Bench check (owner, with hardware).** Flash it and confirm each of these:
  - Serial shows `oled=1 twist=1`.
  - The dial steps 0–100%.
  - Click toggles Off and the previous speed.
  - RPM is about 1900 at 100% and 0 at Off.
  - Pulling the fan's tach wire at 50% shows `FAN?` within 6 s.
  - Unplugging and replugging restores the speed.
  - Booting with the OLED cable removed still spins the fan at the saved speed.

- [ ] **Step 5: Commit** `git add fume-extractor/firmware fume-extractor/docs/wiring.md && git commit -m "fume-extractor: firmware and wiring"`

### Task 3: Case (OpenSCAD)

**Files:**
- Create: `fume-extractor/case/cad/fume_extractor_case.scad`, `fume-extractor/case/stl/*.stl`, `fume-extractor/case/README.md`

**Interfaces:**
- `part` values: `shell`, `frame`, `pod_lid`, `kickstand`, `knob`, `assembly`, `exploded`, plus check targets `chk_shell`, `chk_frame`, `chk_pod_lid`, `chk_kickstand`, `chk_shell_frame`, `chk_shell_pod_lid`.
- Ghost components (for checks and the assembly view):
  - Fan: 120 × 120 × 25, hole spacing 105, 4.3 mm holes.
  - Filter: 130 × 130 × 10.
  - Thing Plus ESP32-S3, Qwiic OLED 1.3", Qwiic Twist: take outlines, holes and connector positions from SparkFun's Eagle/KiCad files on GitHub, the same way open-gps did. Reuse the dimensions in `~/code/open-gps/case/cad/shot_tracker_case.scad` where they match.
  - Protoboard: 50 × 30 × 1.6.
  - Magnets: 6 × 3 mm, 4 pockets in the shell and 4 in the frame, 0.15 mm press fit.
  - M3 heat-set inserts.

- [ ] **Step 1: Model the parts**, all sizes as top-of-file parameters.
  - **Shell:**
    - About 140 × 140 front, holding the fan with a 130 × 130 filter recess in front.
    - Rear finger-guard grille with openings ≤ 8 mm and ≥ 60% open area.
    - Fan screw holes and magnet pockets.
    - A cable channel from the fan header up into the pod.
    - The pod on top: about 140 × 40, front face angled 30° up toward the user. It holds the OLED window, the Twist shaft hole, the Thing Plus and the protoboard. The USB-C opening is on the pod's right side.
  - **Pod lid:** held with M3 screws into heat-set inserts.
  - **Frame:** front grille holding the filter (≥ 70% open area), with magnet pockets.
  - **Kickstand:** pivots on an M3 shoulder screw through the rear-bottom of the shell, with detents at 0°, 15° and 30°.
  - **Knob:** for the Twist shaft. Copy the open-gps knob's shaft fit.

- [ ] **Step 2: Verify** every check target is empty:
  ```bash
  for p in chk_shell chk_frame chk_pod_lid chk_kickstand chk_shell_frame chk_shell_pod_lid; do openscad -D "part=\"$p\"" -o /tmp/$p.stl fume-extractor/case/cad/fume_extractor_case.scad 2>&1 | grep -E "empty|Volumes|WARNING"; done
  ```
  Expected: each one reports an empty top-level object (or zero volume), with no WARNING lines.

- [ ] **Step 3: Export** each printable part to `case/stl/<part>.stl` in print orientation. Render `assembly` and `exploded` to `case/render_assembly.png` and `case/render_exploded.png` with `--imgsize=1200,900`. Open the PNGs and confirm the pod angle, grille and kickstand look right.

- [ ] **Step 4: Write `case/README.md`** in open-gps's case README format: size, layout, files, re-export command, print settings (PETG, 0.2 mm, 3 walls, no supports except the pod overhang if needed), and a hardware list (exact M3 lengths, insert count, magnet count).

- [ ] **Step 5: Commit** `git add fume-extractor/case && git commit -m "fume-extractor: printable case"`

### Task 4: Project README and BOM

**Files:**
- Create: `fume-extractor/README.md`

- [ ] **Step 1: Write the README**, matching open-gps's README structure. Include:
  - What it is (one paragraph) and the assembly render.
  - The `<SPARKFUN_WISHLIST_URL>` callout.
  - A BOM table split into SparkFun (affiliate product links) and Amazon (plain links: Noctua NF-A12x25 5V PWM, 130 mm carbon filter multipack, 2N7000, protoboard, 4-pin fan header, resistors, M3 inserts and screws, 6 × 3 mm magnets).
  - A link to `docs/wiring.md`, the firmware build and flash commands from Task 2, and the case print notes.
  - Usage: turn, click, and what `FAN?` means.
  - The spec's acceptance test, word for word.
  - "Not in v0.1" (the spec's non-goals).

- [ ] **Step 2: Check** that every relative link in the README resolves with `grep -o '](\([^)h][^)]*\))' fume-extractor/README.md`, and test each path. Expected: all exist.

- [ ] **Step 3: Commit** `git add fume-extractor/README.md README.md && git commit -m "fume-extractor: README and BOM"`
