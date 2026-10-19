// USB-C desk fume extractor: Noctua 5V PWM fan, Qwiic Twist dial, Qwiic OLED readout.
#include <Arduino.h>
#include <Wire.h>
#include <Preferences.h>
#include <SparkFun_Qwiic_OLED.h>
#include <res/qw_fnt_5x7.h>
#include <res/qw_fnt_8x16.h>
#include <res/qw_fnt_31x48.h>
#include <res/qw_fnt_largenum.h>
#include <SparkFun_Qwiic_Twist_Arduino_Library.h>
#include "config.h"
#include "fan_logic.h"
#include "plain_encoder.h"

static Qwiic1in3OLED oled;
static TWIST twist;
static Preferences prefs;
static fan::Controller* ctl = nullptr;

static bool oledOk = false, twistOk = false;
static volatile uint32_t tachPulses = 0;

static void IRAM_ATTR onTach() { tachPulses = tachPulses + 1; }

// Off writes the full-scale value (1 << PWM_BITS), not 255: on an 8-bit channel 255 still leaves
// 1/256 low time. (arduino-esp32 3.x already rounds 255 up to full scale; this doesn't rely on it.)
static_assert(PWM_BITS == 8, "gateDuty8() is an 8-bit duty");
static void applyFan() {
  uint32_t duty = ctl->level() == 0 ? (1u << PWM_BITS) : ctl->gateDuty8();
  ledcWrite(PIN_FAN_PWM, duty);
}

static void setTwist(fan::Rgb c) { if (twistOk) twist.setColor(c.r, c.g, c.b); }

static void centered(int y, const char* s) {
  int w = (int)oled.getStringWidth(s);
  oled.text((oled.getWidth() - w) / 2, y, s);
}

static void draw(uint32_t rpm, bool stall, bool dim) {
  oled.erase();
  char buf[16];
  if (dim) {
    // Burn-in protection (Qwiic1in3OLED exposes no contrast control): small percentage only.
    oled.setFont(QW_FONT_5X7);
    if (ctl->level() == 0) snprintf(buf, sizeof buf, "OFF");
    else snprintf(buf, sizeof buf, "%d%%", ctl->percent());
    centered(28, buf);
    if (stall) centered(40, "FAN?");   // a stall must stay visible while dimmed
  } else {
    if (ctl->level() == 0) {
      oled.setFont(QW_FONT_31X48);   // letters only
      centered(2, "OFF");
    } else {
      // LARGENUM has digits only, so draw the number large and '%' small beside it.
      oled.setFont(QW_FONT_LARGENUM);
      snprintf(buf, sizeof buf, "%d", ctl->percent());
      int w = (int)oled.getStringWidth(buf);
      int total = w + 10;
      int x = (oled.getWidth() - total) / 2;
      oled.text(x, 2, buf);
      oled.setFont(QW_FONT_8X16);
      oled.text(x + w + 2, 34, "%");
    }
    oled.setFont(QW_FONT_5X7);
    if (stall) snprintf(buf, sizeof buf, "FAN?");
    else snprintf(buf, sizeof buf, "%lu rpm", (unsigned long)rpm);
    centered(oled.getHeight() - 8, buf);
  }
  oled.display();
}

void setup() {
  Serial.begin(115200);
  if (PIN_QWIIC_PWR >= 0) {
    pinMode(PIN_QWIIC_PWR, OUTPUT);
    digitalWrite(PIN_QWIIC_PWR, HIGH);
  }
  delay(50);
  Wire.begin();

  // SparkFun 1.3" Qwiic OLED is 0x3D; generic 0.96" SSD1306 128x64 modules are usually 0x3C.
  oledOk = oled.begin(Wire, 0x3D) || oled.begin(Wire, 0x3C);
  twistOk = twist.begin(Wire);
  if (twistOk) { twist.getDiff(true); twist.isClicked(); }

  prefs.begin("fume", false);
  int saved = prefs.getInt("level", -1);
  static fan::Controller c(saved, millis());
  ctl = &c;

  ledcAttach(PIN_FAN_PWM, PWM_HZ, PWM_BITS);
  applyFan();
  pinMode(PIN_FAN_TACH, INPUT);   // external 10k pull-up to 3V3
  attachInterrupt(digitalPinToInterrupt(PIN_FAN_TACH), onTach, FALLING);
  plain_encoder::begin();

  setTwist(fan::colorFor(ctl->level()));
  Serial.printf("fume-extractor %s\n", FW_VERSION);
  Serial.printf("oled=%d twist=%d encoder=%d level=%d\n", oledOk, twistOk,
                plain_encoder::enabled(), ctl->level());
}

void loop() {
  static uint32_t lastTick = 0, lastRpmMs = millis();
  static uint32_t rpm = 0;
  static bool stall = false, lastDim = false, lastStall = false, first = true;
  static uint32_t lastRpmShown = 0;
  static bool lastBlink = false;

  uint32_t now = millis();
  if (now - lastTick < LOOP_MS) return;
  lastTick = now;

  bool changed = false;
  int d = plain_encoder::takeDetents();
  bool clicked = plain_encoder::takeClick(now);
  if (twistOk) {
    d += twist.getDiff(true);
    clicked = twist.isClicked() || clicked;
  }
  int before = ctl->level();
  if (d != 0) ctl->turn(d, now);
  if (clicked) ctl->click(now);
  if (ctl->level() != before) {
    changed = true;
    applyFan();
    setTwist(fan::colorFor(ctl->level()));
    Serial.printf("level=%d (%d%%)\n", ctl->level(), ctl->percent());
  }

  if (now - lastRpmMs >= RPM_WINDOW_MS) {
    noInterrupts();
    uint32_t p = tachPulses;
    tachPulses = 0;
    interrupts();
    rpm = fan::rpmFromPulses(p, now - lastRpmMs);
    lastRpmMs = now;
    stall = ctl->stalled(rpm, now);
    if (now / 1000 % 5 == 0) Serial.printf("rpm=%lu%s\n", (unsigned long)rpm, stall ? " FAN?" : "");
    if (!stall && lastStall) setTwist(fan::colorFor(ctl->level()));
  }

  if (stall) {  // 2 Hz red blink
    bool on = (now / 250) % 2 == 0;
    if (on != lastBlink || !lastStall) {
      lastBlink = on;
      if (on) setTwist({255, 0, 0}); else setTwist({0, 0, 0});
    }
  }

  if (ctl->takeSave(now)) prefs.putInt("level", ctl->level());

  if (oledOk) {
    bool dim = ctl->dimmed(now);
    bool need = first || changed || dim != lastDim || stall != lastStall ||
                (!dim && rpm != lastRpmShown);
    if (need) {
      draw(rpm, stall, dim);
      lastRpmShown = rpm;
    }
    lastDim = dim;
  }
  lastStall = stall;
  first = false;
}
