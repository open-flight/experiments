# ESP32 Hidden SDR

Run a classic ESP32 dev board as a 2.4 GHz spectrum and waterfall viewer. The ESPARGOS team found an undocumented I/Q baseband tap in ESP32 silicon (behind Espressif's `adctrig` in `librftest`). Their [ESP-SDR](https://github.com/ESPARGOS/esp-sdr) firmware captures short I/Q bursts through it, and [ESP-WebSDR](https://github.com/ESPARGOS/esp-web-sdr) turns them into spectra and a waterfall in Chrome over Web Serial.

This folder holds what it took to get that working on a CH340-based ESP32 board on macOS: a firmware config overlay that drops the UART to 230400 baud, a matching patch for the viewer, and a probe script for testing the serial link.

| Path | What's there |
|---|---|
| `firmware/sdkconfig.uart-230400` | ESP-IDF sdkconfig overlay for ESP-SDR: UART at 230400 instead of 2000000 |
| `viewer/esp-web-sdr-230400.patch` | ESP-WebSDR patch: connect at 230400 first, show kBaud in the status label |
| `tools/sdrprobe.py` | Sends the viewer's `SYNC` and `CAPS` commands at one baud rate and prints the replies |

## Why 230400

The stock firmware talks at 2 MBaud. On this board's CH340 (USB ID `1a86:7522`) with the WCH macOS driver, reads from the board fail above 230400:

| Baud | Board to Mac |
|---|---|
| 2000000 | no data |
| 1000000, 921600, 460800 | corrupt |
| 230400 | clean |

Writing to the board is fine at 460800, so flashing is unaffected. macOS's built-in `AppleUSBCHCOM` driver doesn't match PID `0x7522`, so removing the WCH driver leaves the board with no serial port at all. ESP-SDR's runtime `BAUD` command only accepts 1000000 or 2000000, so the rate has to be set at build time.

A board with a CP210x bridge, or an ESP32-S3 on native USB, shouldn't need any of this.

## Setup

Tested with ESP-IDF at `25fe69f` (reports v6.2), ESP-SDR at `b1e6518`, and ESP-WebSDR at `26276a6`.

### 1. ESP-IDF

```bash
git clone --depth 1 https://github.com/espressif/esp-idf.git ~/esp/esp-idf
~/esp/esp-idf/install.sh esp32
```

If the build later complains that cmake must be available, install it and ninja with `python ~/esp/esp-idf/tools/idf_tools.py install cmake ninja`.

### 2. Build and flash ESP-SDR

```bash
git clone --recursive https://github.com/ESPARGOS/esp-sdr.git ~/esp/esp-sdr
```

```bash
cd ~/esp/esp-sdr && . ~/esp/esp-idf/export.sh && idf.py -B build-esp32-230400 -DIDF_TARGET=esp32 -DSDKCONFIG=build-esp32-230400/sdkconfig "-DSDKCONFIG_DEFAULTS=$PWD/sdkconfig.defaults.esp32;$HOME/code/experiments/esp32-sdr/firmware/sdkconfig.uart-230400" -DESP_SDR_STREAMING=OFF -DRING_PROBE=OFF -DSAMPLE_RATE_PROBE=OFF -DFILTER_REGISTER_PROBE=OFF -DS3_RF_PROBE=OFF -DC5_TUNE_PROBE=OFF -DS2_RF_PROBE=OFF build
```

```bash
cd ~/esp/esp-sdr && . ~/esp/esp-idf/export.sh && idf.py -B build-esp32-230400 -p /dev/cu.wchusbserial10 -b 460800 flash
```

Your port name may differ: check `ls /dev/cu.*`.

### 3. Check the link (optional)

```bash
python3 -I ~/code/experiments/esp32-sdr/tools/sdrprobe.py /dev/cu.wchusbserial10 230400
```

A working board prints `SYNC echoed: True` and a `CAPS` line listing commands such as `SPEC`, `GAIN` and `IQ8`.

### 4. Patch and serve the viewer

```bash
git clone https://github.com/ESPARGOS/esp-web-sdr.git ~/esp/esp-web-sdr && git -C ~/esp/esp-web-sdr apply ~/code/experiments/esp32-sdr/viewer/esp-web-sdr-230400.patch
```

```bash
cd ~/esp/esp-web-sdr && python3 -I -m http.server 8766 --bind 127.0.0.1
```

Open http://localhost:8766/ in Chrome or Edge (Web Serial is required), click Connect, and pick the board's port. The status label should read 230.4 kBaud.

## Seeing traffic

- The ESP32 only hears about 2.2 to 2.7 GHz. A laptop or phone on 5 GHz Wi-Fi is invisible to it, so put the device you're testing on a 2.4 GHz network (an iPhone hotspot with Maximize Compatibility turned on works).
- Center at 2442 MHz to cover channels 1 to 13 in one 80 MHz view.
- Use manual gain. AGC readjusts every frame and flattens the difference between a quiet and a busy channel.
- Each burst is about 2048 samples at 80 MS/s, roughly 25 µs, a few times a second. Light traffic mostly falls between bursts, while sustained transfers like a speed test show up clearly.
