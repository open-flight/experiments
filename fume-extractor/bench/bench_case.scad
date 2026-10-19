// Fume extractor bench rig: a quick, support-free print for testing the fan, filter,
// ESP32 DevKit and a bare EC11 encoder before the full case.
//   part = "stand"  : base that holds the 120 mm fan upright with the 130 mm filter in front
//   part = "box"    : open-top control box for the DevKit, encoder in the front wall
//   part = "both"   : both, laid out for one print (fits a 220 x 220 bed)

part = "both";
$fn = 48;

// Fan and filter
fan_w = 120.0;   fan_d = 25.0;
filt_w = 130.0;  filt_d = 10.0;
clr = 0.6;       // slot clearance

// Stand
wall = 3.0;
base_t = 3.0;
pocket_h = 14.0;           // how deep the fan and filter sit
rib_h = 6.0;               // low rib between filter and fan, so it doesn't block airflow
foot_back = 30.0;          // extra base behind the fan, against tipping backward
foot_front = 25.0;         // extra base in front of the filter

// Control box (fits 30- and 38-pin DevKits: ~51-55 x 28 mm)
board_l = 56.0;  board_w = 29.0;
box_wall = 2.0;
box_h = 30.0;              // outer height, open top
enc_hole = 7.4;            // EC11 M7 bushing
enc_z = 17.0;              // encoder shaft height above the floor
usb_w = 14.0;  usb_h = 9.0;
cable_w = 10.0; cable_h = 6.0;

stand_w = filt_w + clr + 2 * wall;
stand_d = foot_front + wall + filt_d + clr + 2 + fan_d + clr + wall + foot_back;

module stand() {
  y_filt = foot_front + wall;
  y_fan = y_filt + filt_d + clr + 2;
  difference() {
    union() {
      cube([stand_w, stand_d, base_t]);
      // pocket block, from the filter's front wall to the fan's back wall
      translate([0, foot_front, 0])
        cube([stand_w, wall + filt_d + clr + 2 + fan_d + clr + wall, base_t + pocket_h]);
    }
    // filter pocket (full width of the pad)
    translate([wall, y_filt, base_t]) cube([filt_w + clr, filt_d + clr, pocket_h + 1]);
    // fan pocket (centred)
    translate([(stand_w - fan_w - clr) / 2, y_fan, base_t]) cube([fan_w + clr, fan_d + clr, pocket_h + 1]);
    // lower the rib between them
    translate([wall, y_filt + filt_d + clr - 0.01, base_t + rib_h]) cube([filt_w + clr, 2.02, pocket_h]);
    // cable notch at the back-right for the fan lead
    translate([stand_w - wall - 25, y_fan + fan_d + clr - 1, base_t + 4]) cube([15, wall + 2, pocket_h]);
    // lighten the feet
    for (y = [6, stand_d - foot_back + 6])
      translate([15, y, -1]) cube([stand_w - 30, (y < 20 ? foot_front : foot_back) - 12, base_t + 2]);
  }
}

module box() {
  ox = board_l + 2 * box_wall + 4;   // 4 mm slack for the encoder body and wires
  oy = board_w + 2 * box_wall + 14;  // room for the 12 mm encoder body behind the front wall
  difference() {
    cube([ox, oy, box_h]);
    translate([box_wall, box_wall, box_wall]) cube([ox - 2 * box_wall, oy - 2 * box_wall, box_h]);
    // encoder hole through the front wall (y = 0), centred
    translate([ox / 2, -1, enc_z]) rotate([-90, 0, 0]) cylinder(d = enc_hole, h = box_wall + 2);
    // USB opening at the left end, at board height (board sits on its header pins)
    translate([-1, box_wall + 14 + (board_w - usb_w) / 2, box_wall + 9]) cube([box_wall + 2, usb_w, usb_h]);
    // fan cable / USB-for-fan slot at the right end, open to the top
    translate([ox - box_wall - 1, oy / 2 - cable_w / 2, box_h - cable_h - 8]) cube([box_wall + 2, cable_w, cable_h + 9]);
  }
}

if (part == "stand") stand();
else if (part == "box") box();
else { stand(); translate([0, stand_d + 8, 0]) box(); }
