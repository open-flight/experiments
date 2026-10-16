# Wiring

SparkFun Thing Plus ESP32-S3, Noctua NF-A12x25 5V PWM fan (4-pin), 2N7000 low-side
PWM inverter, Qwiic OLED 1.3" and Qwiic Twist.

Fan connector pins: 1 = GND, 2 = +5 V, 3 = tach, 4 = PWM.

```
 USB-C ──► Thing Plus ESP32-S3
           VUSB ───────────────────────────────► Fan pin 2 (+5 V)
           GND  ─────────┬─────────────────────► Fan pin 1 (GND)
                         │
           3V3 ──[10k]───┬──────────────────────► (pull-up node)
           GPIO5 (silk "GPIO3") ◄────────────────┘ ──── Fan pin 3 (tach)

           GPIO4 (silk "4") ──[100R]──┬── 2N7000 gate
                                      └──[100k]── GND
                      2N7000 drain ───────────────► Fan pin 4 (PWM)
                      2N7000 source ──────────────► GND

           Qwiic ──► OLED ──► Twist   (chain; GPIO45 powers the Qwiic rail)
```

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
- [ ] Unplugging and replugging the tach restores the speed readout.
- [ ] Booting with the OLED cable removed still spins the fan at the saved speed.
