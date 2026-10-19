# USB-C Desk Fume Extractor

A small desk fume extractor that pulls solder smoke away from the work. It's the same box format as the $30-40 mains-powered units (YIHUA 948DQ and similar), with a square fan and a replaceable 130 mm carbon filter on the front. This one runs from an ordinary USB-C wall charger, and it has a dial for fan speed and a small screen showing the current speed. It uses a Noctua NF-A12x25 5V PWM fan driven by a SparkFun Thing Plus ESP32-S3, in a 3D-printed PETG case that tilts forward toward the work.

![Assembly, tilted forward 15 degrees on its base](case/render_assembly.png)

> [!TIP]
> **A one-click SparkFun wishlist is coming soon.** For now, use the individual SparkFun links in the [Bill of materials](#bill-of-materials) below.
> <sub>The SparkFun and Amazon links are referral links, so buying through them supports the project at no extra cost to you.</sub>

- **Firmware:** Arduino (ESP32-S3). 25 kHz PWM, tach read-back, stall warning, dial and OLED UI.
- **Enclosure:** parametric OpenSCAD, prints in PETG without supports. See [case/README.md](case/README.md).
- **Host tests:** the fan logic runs on your computer (`make -C firmware/test`), no hardware needed.

| Path | What's there | More detail |
|---|---|---|
| `firmware/fume_extractor/` | Arduino sketch (`fume_extractor.ino`, `fan_logic.h`, `config.h`) | [Build](#firmware-build-and-flash) |
| `firmware/test/` | Host tests (`make -C firmware/test`) | [Build](#firmware-build-and-flash) |
| `case/cad/fume_extractor_case.scad` | Case source (all parameters at the top) | [case/README.md](case/README.md) |
| `case/stl/` | Pre-exported printable parts | [case/README.md](case/README.md) |
| `docs/wiring.md` | Wiring diagram, pin choices, bench check | [docs/wiring.md](docs/wiring.md) |
| `docs/superpowers/specs/` | Design spec | [spec](docs/superpowers/specs/2026-10-16-fume-extractor-design.md) |

---

## Bill of materials

Power is any USB-C wall charger rated 5 V / 1 A or more, plus a USB-C cable. Total draw is under 0.6 A. No PD negotiation and no 12 V.

The cable needs a **slim USB-C plug body**. The opening in the case's side wall is 12.6 x 7 mm, and the plug has to reach about 2.7 mm into the wall to seat in the Thing Plus's socket, so bulky overmoulded plugs won't go in far enough.

### SparkFun

| Qty | Part | Notes |
|---|---|---|
| 1 | [SparkFun Thing Plus ESP32-S3](https://www.sparkfun.com/sparkfun-thing-plus-esp32-s3.html?affiliate_code=rfxlS0eYyY) | Main board. USB-C power input, one Qwiic port. |
| 1 | [SparkFun Qwiic OLED 1.3" 128x64](https://www.sparkfun.com/sparkfun-qwiic-oled-1-3in-128x64.html?affiliate_code=rfxlS0eYyY) | Address 0x3D |
| 1 | [SparkFun Qwiic Twist RGB rotary encoder](https://www.sparkfun.com/sparkfun-qwiic-twist-rgb-rotary-encoder-breakout.html?affiliate_code=rfxlS0eYyY) | Address 0x3F |
| 1 | [SparkFun Qwiic Cable Kit](https://www.sparkfun.com/sparkfun-qwiic-cable-kit.html?affiliate_code=rfxlS0eYyY) | |

### Amazon

These are search links, not fixed product pages, so you can pick a well-reviewed, Prime-eligible listing. Check the model number and size against the notes.

| Qty | Part | Notes |
|---|---|---|
| 1 | [Noctua NF-A12x25 5V PWM fan](https://www.amazon.com/s?k=Noctua+NF-A12x25+5V+PWM&tag=colemangolfs-20) | Must be the **5V** version. The 12 V one will not work here. 120 x 120 x 25 mm, 4-pin. |
| 1 | [130 x 130 mm carbon filter pads, multipack](https://www.amazon.com/s?k=130x130mm+activated+carbon+filter+948DQ+replacement&tag=colemangolfs-20) | 948DQ-style replacements, 10 mm thick. Buy a multipack. |
| 1 | [2N7000 N-MOSFET](https://www.amazon.com/s?k=2N7000+TO-92+MOSFET&tag=colemangolfs-20) | TO-92. Its gate threshold can be as high as 3 V, so with the ESP32's 3.3 V drive some parts won't switch fully. A true logic-level part is the safer choice: **AO3400** or **BSS138** (both SOT-23, so solder it to a SOT-23 adapter, and wire it by pin name: G, D, S). |
| 1 | [Protoboard, about 50 x 30 mm](https://www.amazon.com/s?k=mini+protoboard+solderable+PCB+kit&tag=colemangolfs-20) | The case expects 50 x 30 mm with holes 2.5 mm in |
| 1 | [4-pin fan header](https://www.amazon.com/s?k=4+pin+PWM+fan+header+connector+2.54mm&tag=colemangolfs-20) | 2.54 mm pitch |
| 1 set | [Resistors: 10 k, 100 k, 100 ohm](https://www.amazon.com/s?k=resistor+assortment+kit+1%2F4W&tag=colemangolfs-20) | 1/4 W assortment is fine |
| 12 | [M3 heat-set inserts](https://www.amazon.com/s?k=M3+heat+set+inserts+brass+assortment&tag=colemangolfs-20) | 4.0 mm hole, 5.7 mm long or shorter |
| 1 set | [M3 screws](https://www.amazon.com/s?k=M3+screw+assortment+button+head+flat+head+ISO+7380&tag=colemangolfs-20) | 4 x M3x30 button head, 4 x M3x8 flat head |
| 4 | [M3 shoulder screws](https://www.amazon.com/s?k=M3+shoulder+screw+4mm+shoulder+6mm&tag=colemangolfs-20) | 4 mm shoulder x 6 mm, M3 thread 5 mm or shorter |
| 8 | [6 x 3 mm disc magnets](https://www.amazon.com/s?k=6x3mm+neodymium+disc+magnets+N52&tag=colemangolfs-20) | Check polarity before gluing |
| 1 set | [Small M2 and M2.5 screws](https://www.amazon.com/s?k=M2+M2.5+pan+head+screw+assortment&tag=colemangolfs-20) | M2.5 x 4, x 5, x 8 and M2 x 5 |
| 1 | [Hookup wire](https://www.amazon.com/s?k=22awg+silicone+hookup+wire+kit&tag=colemangolfs-20) | |
| 1 | Steel flat bar, 25 x 12 mm (or 1" x 1/2"), about 250 mm | Base ballast, about 575 g. Cut one 140 mm and two 52 mm pieces. Any hardware store. **Needed** so a press on the dial doesn't tip the case backward. |

The full case hardware list (with where each screw goes) is in [case/README.md](case/README.md#hardware). Optional: rubber feet for the base plate and 3 mm foam tape around the fan.

---

## Build

1. **Print** the case. Settings and orientation are in [case/README.md](case/README.md#printing-petg). The STLs are in `case/stl/`.
2. **Wire** the protoboard and the Qwiic chain with [docs/wiring.md](docs/wiring.md). Qwiic chain: Thing Plus, OLED, Twist.
3. **Flash** the firmware (below) and run the bench check in [docs/wiring.md](docs/wiring.md#bench-check) **before** closing the case.
4. **Assemble** following [the assembly order](case/README.md#assembly-order).

### Firmware build and flash

Install the toolchain:

```bash
brew install arduino-cli   # macOS; see arduino-cli docs for Linux and Windows
arduino-cli config add board_manager.additional_urls https://espressif.github.io/arduino-esp32/package_esp32_index.json
arduino-cli core update-index
arduino-cli core install esp32:esp32
arduino-cli lib install "SparkFun Qwiic OLED Arduino Library" "SparkFun Qwiic Twist Arduino Library"
```

Run the host tests, then build and flash from the repository root:

```bash
make -C fume-extractor/firmware/test
FQBN="esp32:esp32:sparkfun_esp32s3_thing_plus:CDCOnBoot=cdc"
arduino-cli compile --fqbn "$FQBN" fume-extractor/firmware/fume_extractor
arduino-cli board list                    # find the port, e.g. /dev/cu.usbmodem101
arduino-cli compile --upload -p /dev/cu.usbmodem101 --fqbn "$FQBN" fume-extractor/firmware/fume_extractor
arduino-cli monitor -p /dev/cu.usbmodem101 -c baudrate=115200
```

`CDCOnBoot=cdc` is needed for serial output over the USB-C port. The monitor should show `oled=1 twist=1`.

**Troubleshooting:**
- **`bad CPU type in executable` on Apple Silicon.** arduino-cli's bundled `ctags` is x86-only. Either install Rosetta (`softwareupdate --install-rosetta`), or build a native copy once and point the compiler at it:
  ```bash
  git clone --depth 1 https://github.com/arduino/ctags.git ~/src/arduino-ctags
  (cd ~/src/arduino-ctags && ./configure && make CFLAGS="-O2 -w -include dirent.h")
  arduino-cli compile --build-property "tools.ctags.path=$HOME/src/arduino-ctags" --fqbn "$FQBN" fume-extractor/firmware/fume_extractor
  ```
- **No port appears.** Use a USB-C data cable, or hold BOOT, tap RESET, and release BOOT before uploading.

### Using a generic ESP32 DevKit instead

For a quick bench test with a DevKit and a bare EC11 encoder (no OLED, no Twist) and a simple print, see [bench/README.md](bench/README.md).

A classic ESP32 DevKit ("ESP32 Dev Module", ESP32-WROOM-32) works too; the firmware picks its pins automatically when built for that board. Differences from the Thing Plus:

| | Thing Plus ESP32-S3 | ESP32 DevKit |
|---|---|---|
| FQBN | `esp32:esp32:sparkfun_esp32s3_thing_plus:CDCOnBoot=cdc` | `esp32:esp32:esp32` |
| Fan PWM | pad 4 (IO4) | GPIO4 |
| Fan tach | pad 5 (IO5) | GPIO34 (input-only; the 10 kΩ pull-up is required) |
| Qwiic | Qwiic port | [Qwiic female jumper cable](https://www.sparkfun.com/flexible-qwiic-cable-female-jumper-4-pin.html?affiliate_code=rfxlS0eYyY): 3V3, GND, SDA → GPIO21, SCL → GPIO22 |
| Fan 5 V | VUSB | `5V`/`VIN` pin (USB 5 V, usually through a diode, so about 4.7 V; the fan starts at 4 V) |

Many DevKits use a WCH CH340 USB chip. If the board shows up in `system_profiler SPUSBDataType` but no `/dev/cu.wchusbserial*` port appears, install WCH's CH34x macOS driver and allow it in System Settings → Privacy & Security. The case is sized for the Thing Plus, so a DevKit build is for bench testing.

---

## Using it

- **Turn** the dial to change speed: Off, then 10% to 100% in 10% steps. The screen shows the speed large, with the measured RPM small underneath. The dial's light fades from blue (low) through green to red (high), and stays dim when Off.
- **Click** to toggle between Off and the last non-zero speed.
- On power-up it starts at the last-used speed, so plugging it in is enough to turn it on.
- After 10 minutes with no dial input the screen dims. The fan keeps running.
- **`FAN?`** appears on the screen (also when it's dimmed), and the dial blinks red, when the PWM is above 20% and the tach reads 0 for 3 seconds. It means the fan is stalled, unplugged, or the tach wire has come loose. Check the fan cable and the fan's path for obstruction.

- **Changing the filter:** tilt the case to 0° first. At 30° the frame's bottom edge is only about 2 mm above the base, too little to get a finger into the scoop under it. Peel the frame off from that scoop, not from the middle or top (see [case/README.md](case/README.md#known-limitations--next-steps)).

## Safety

- The case is PETG, which softens at about 80 °C, and the carbon pads can smoulder if a hot iron touches them.
- Never rest the iron on the frame or the filter.
- Keep the iron's stand between the iron and the unit, or off to the side.
- Unplug the unit when you walk away from the bench.
- Replace any filter pad that is scorched.

## Acceptance test

Put a thin smoke source (a hot iron touching flux, or rosin core solder) 15 cm in front of the filter at 100%. The plume should bend into the filter and not rise past it. If it fails, try 3 filter pads instead of 2 and then test again with 1 pad, before changing the fan.

## Not in v0.1

- Battery power.
- Wi-Fi, Bluetooth, app control, or remote control.
- Work lighting.
- Custom PCB. The plan is to hand-wire v1 on a protoboard and do a PCB later once it works.
- Air-quality sensing or auto-on.

## License

AGPL-3.0; see [LICENSE](../LICENSE). It covers the firmware, the case CAD and STLs, and the documentation.
