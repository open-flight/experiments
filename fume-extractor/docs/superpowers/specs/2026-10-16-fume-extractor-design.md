# USB-C Desk Fume Extractor: Design

Date: 2026-10-16
Status: approved 2026-10-16

Owner approved without answering three open questions, so these defaults stand until changed:
- If the 5 V fan fails the acceptance test after filter tweaks, stop and ask the owner before changing the fan or power design.
- Amazon links are plain (no affiliate tag).
- One AGPL-3.0 LICENSE at the repo root covers every project.

## Intent

A small desk fume extractor that pulls solder smoke away from the work. It sits directly behind a helping-hands setup during long sessions on small boards. It's the same box format as the $30–40 Amazon units (YIHUA 948DQ and similar): a square fan with a replaceable carbon filter on the front. The differences are that it runs from a USB-C wall charger instead of mains, and it has a dial for fan speed with a small screen showing the current speed.

It's the first project in a new open-source repo, `~/code/experiments`, that will hold a collection of small builds. Someone else should be able to build it from the README, BOM and STL files alone.

The parts list leans on SparkFun Qwiic parts on purpose. The owner is a SparkFun affiliate, and the build should look like a natural sibling of `open-gps` (the golf shot tracker), which uses the same board, screen and dial.

## Goals

- Pulls visible solder smoke away from the work at hobby distances (a few inches from the joint).
- Dial changes fan speed; screen shows the current speed.
- Powered by any USB-C wall charger. No PD negotiation and no 12 V.
- Compact 3D-printed case that tilts toward the work.
- Uses the standard 130 mm carbon filter pads sold as replacements for the commercial units, so filters are cheap and easy to find.
- No soldering for the Qwiic parts. The only hand-wiring is the fan, on a small protoboard.
- Easy for others to reproduce: SparkFun wishlist (affiliate link) plus Amazon links for everything else.

## Non-goals (v1)

- Battery power.
- Wi-Fi, Bluetooth, app control, or remote control.
- Work lighting.
- Custom PCB. The plan is to hand-wire v1 on a protoboard and do a PCB later once it works.
- Air-quality sensing or auto-on.

## Anti-goals

- Being louder or weaker than the $35 commercial units it replaces.
- Needing a special charger, a PD trigger, or anything besides an ordinary USB-C wall charger and cable.
- A case that makes changing the filter fiddly.
- Mains voltage anywhere in the build.

## Decided

### Electronics

| Qty | Part | Source | Notes |
|---|---|---|---|
| 1 | SparkFun Thing Plus ESP32-S3 | SparkFun | Same board as open-gps. USB-C power input; one Qwiic port. |
| 1 | SparkFun Qwiic OLED 1.3" 128×64 | SparkFun | Address 0x3D. Same as open-gps. |
| 1 | SparkFun Qwiic Twist RGB rotary encoder | SparkFun | Address 0x3F. Same as open-gps. |
| 1 | SparkFun Qwiic Cable Kit | SparkFun | |
| 1 | Noctua NF-A12x25 5V PWM (120 mm, 4-pin) | Amazon | 5 V rated, 0.35 A max, 1900 rpm max, 0 rpm at 0% PWM, ~56 CFM. Roughly matches the 12 V version's airflow. |
| 1 set | 130 × 130 mm activated-carbon filter pads (948DQ-style replacements) | Amazon | Standard size. Buy a multi-pack. |
| 1 | Small protoboard, 4-pin fan header, 2N7000 (or similar logic-level N-MOSFET), 10 kΩ resistors, hookup wire | Amazon | For the fan's PWM and tach lines. |
| — | M3 heat-set inserts and screws, magnets for the filter frame | Amazon | Exact sizes come from the case design. |

**Power:** USB-C wall charger → Thing Plus USB-C. The fan's 5 V comes from the Thing Plus's VUSB pin. Total draw is under 0.6 A, so any charger rated 5 V / 1 A or more works.

**Fan control:**
- PWM: 25 kHz from an ESP32-S3 LEDC channel. It drives the fan's PWM input through the N-MOSFET as an open-drain output, which is how Intel's 4-pin spec expects it. The output is inverted, so the firmware flips the duty.
- Tach: open-collector, pulled up to 3.3 V with 10 kΩ, read on an interrupt pin. Two pulses per revolution.

**Qwiic chain:** Thing Plus → OLED → Twist. As in open-gps, the Thing Plus's Qwiic rail is switched by GPIO45, so the firmware drives it high at boot.

### Behavior

- Turn the dial to change fan speed. The screen shows the current speed large, in the middle.
- Speed is set in steps from Off to 100%.
- Both the screen and the Twist's RGB light reflect the current speed.

### Case

- Box format, about 140 × 140 mm square, with a 120 mm fan and a 130 mm filter on the front.
- Air comes in through the filter on the front (facing the work) and leaves through a guarded grille on the back.
- Tilts toward the work.
- OpenSCAD, one parametric `.scad` file with a `part` selector and pre-exported STLs, following the same conventions as `open-gps/case`.

### Firmware

- Arduino on ESP32 core 3.x, with the same SparkFun libraries open-gps uses (Qwiic OLED, Qwiic Twist).

### Repo

```
experiments/
  README.md                  # index of projects
  LICENSE
  fume-extractor/
    README.md                # what it is, BOM, wishlist link, build steps
    docs/superpowers/specs/  # this document
    case/cad/fume_extractor_case.scad
    case/stl/
    firmware/fume_extractor/
```

## My calls (check these)

These are choices I made that the owner hasn't confirmed. Each is easy to change.

- **Speed steps:** Off, then 10% to 100% in 10% steps. The screen shows the percentage large and the measured RPM small underneath.
- **Click:** Pressing the dial toggles Off ↔ the last non-zero speed.
- **Power-on:** Starts at the last-used speed, saved to flash. This way, plugging it in is enough to turn it on.
- **Twist color:** Fades from blue (low) to green to red (high), and stays dim when Off.
- **Fan-stall warning:** If the PWM is above 20% and the tach reads 0 for 3 seconds, the screen shows "FAN?" and the Twist blinks red.
- **Screen burn-in:** After 10 minutes with no dial input, the OLED dims (the fan keeps running).
- **Controls placement:** The OLED and dial sit on the top face, angled toward the user, in a small raised pod. This keeps them away from the airflow and visible over the helping hands.
- **Filter retention:** A front frame holds the filter and is attached with four small magnets, so the filter can be changed without tools.
- **Tilt:** Rear kickstand with three detent positions (0°, 15°, 30°).
- **Print material:** PETG, because it sits near a hot iron.
- **License:** AGPL-3.0, matching open-gps.
- **Acceptance test:** Put a thin smoke source (a hot iron touching flux, or rosin core solder) 15 cm in front of the filter at 100%. The plume should bend into the filter and not rise past it. If it fails, try 3 filter pads instead of 2 and then test again with 1 pad, before changing the fan.
- **Wishlist and links:** The README uses placeholders (`<SPARKFUN_WISHLIST_URL>`, `<AMAZON_URL_…>`) until the owner creates the SparkFun wishlist and picks the Amazon listings.
- **Doc location:** Specs live inside each project folder (`<project>/docs/...`) rather than at the repo root, since the repo will hold many unrelated projects.

## Left to the builder

- The exact case geometry: wall thickness, fan screw bosses, cable routing, grille pattern, kickstand mechanism, magnet pocket sizes.
- Pin choices on the Thing Plus for PWM and tach.
- The protoboard layout and how it mounts in the case.
- Firmware structure and screen layout details beyond "speed big, RPM small."
- Specific Amazon listings (prefer well-reviewed, Prime-eligible).
- Checking that the Thing Plus's VUSB path can supply the fan's 0.35 A. If it can't, add a separate USB-C power breakout that feeds the fan and the Thing Plus, and note it in the BOM.
