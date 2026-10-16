# Wiring

SparkFun Thing Plus ESP32-S3, Noctua NF-A12x25 5V PWM fan (4-pin), 2N7000 low-side
PWM inverter, Qwiic OLED 1.3" and Qwiic Twist.

Fan connector pins: 1 = GND, 2 = +5 V, 3 = tach, 4 = PWM.

```
 USB-C ──► Thing Plus ESP32-S3

   VUSB ──────────────────────────────────► Fan pin 2 (+5 V)
   GND  ──────────────────────────────────► Fan pin 1 (GND)

   3V3 ───[10k]───┬─────────────────────────► Fan pin 3 (tach)
                  └──────────────────────────► pad "5" (IO5)

   pad "4" (IO4) ──[100R]──┬── 2N7000 gate
                           └──[100k]── GND
   2N7000 drain  ────────────────────────► Fan pin 4 (PWM)
   2N7000 source ────────────────────────► GND

   Qwiic ──► OLED ──► Twist   (chain; IO45 powers the Qwiic rail)
```

Pad naming: pads are named by raw ESP32 IO number (SparkFun's hardware overview says the
PTH pads are labeled that way). Arduino's `GPIO3`/`GPIO4` aliases are a different scheme
(GPIO3 = IO5) and are not used. Silkscreen text and header position (left/right, Nth from
top) could not be confirmed from SparkFun's docs here; check the board or the graphical
datasheet for the pads marked 4 and 5 before soldering.

Notes:
- The 2N7000 inverts: gate high pulls fan PWM low. The firmware compensates
  (`gateDuty8()`), so 100% = gate duty 0.
- The fan's PWM pin is pulled up internally, so a floating gate means full speed
  (fail-safe).
- Tach is open-collector, 2 pulses per revolution, hence the 10 kΩ pull-up to 3V3.
- Pin choices are explained in `firmware/fume_extractor/config.h`.

## Bench check

Flash the sketch and confirm each item:

- [ ] Serial (115200) shows `oled=1 twist=1`.
- [ ] The dial steps the fan 0-100% in 10% steps.
- [ ] Click toggles Off and back to the previous speed.
- [ ] RPM is about 1900 at 100% and 0 at Off.
- [ ] Pulling the fan's tach wire at 50% shows `FAN?` within 6 s (Twist blinks red).
- [ ] Replugging the tach wire clears `FAN?` and restores the RPM readout.
- [ ] Unplugging and replugging USB power restores the saved speed.
- [ ] Booting with the OLED cable removed still spins the fan at the saved speed.
