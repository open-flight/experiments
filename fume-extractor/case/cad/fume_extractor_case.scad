// =====================================================================
//  USB-C desk fume extractor - printable case (parametric, OpenSCAD)
//  Parts: shell (fan box + control pod), frame (magnetic filter grille),
//         pod_lid (sloped control face), base (tilt stand, alias "kickstand"), knob
//
//  Export a part:   openscad -D 'part="shell"' -o shell.stl fume_extractor_case.scad
//  part = "assembly" | "exploded" | "poses" | "pod_face" | "shell" | "frame" | "pod_lid" | "base" | "knob"
//  Fit checks (should all be empty):
//         "chk_shell" | "chk_frame" | "chk_pod_lid" | "chk_kickstand" (= base + screws + ballast vs
//         the posed case at 0/15/30) |
//         "chk_shell_frame" | "chk_shell_pod_lid" | "chk_desk" | "chk_ghosts" | "chk_knob"
//  Area helpers (2D, use with --summary area): "area_rear_open" | "area_rear_total" |
//         "area_front_open" | "area_front_total"
//
//  Frame: X = width (left -> right, viewed from the front), Y = depth (0 = shell front
//  face where the filter goes, +Y toward the rear grille), Z = up (0 = desk).
//  Air: in through the front filter -> fan -> out through the rear grille.
// =====================================================================

part = "assembly";
show_components = true;     // ghost parts in assembly/exploded views
view_tilt = 1;              // which tilt the assembly view shows: index into tilts (0, 15, 30 deg)
$fn = 48;

// ---------- print / fit tolerances (PETG, 0.4 nozzle) ----------
clr        = 0.25;   // general part-to-part clearance
insert_d   = 4.0;    // M3 heat-set insert hole (CNC Kitchen style M3x5.7 -> 4.0)
insert_l   = 5.7;
m3_clear   = 3.4;
m3_csk_d   = 6.6;    // countersink for M3 flat head (ISO 10642 head 6.0)
m25_pilot  = 2.1;    // M2.5 self-tapping pilot into PETG
m2_pilot   = 1.8;    // M2 self-tapping pilot into PETG

// ---------- fan: Noctua NF-A12x25 5V PWM ----------
fan        = [120, 25];      // [square, thickness]
fan_hole_s = 105;            // hole spacing
fan_clr    = 0.3;            // pocket clearance per side
fan_gap_f  = 2.0;            // air gap between filter and fan front (room for the M3 button heads)
plenum     = 6.0;            // exhaust gap between fan back and grille (cable exit, insert pads)
grille_d   = 116;            // rear grille circle (fan blade sweep)
rear_hex   = 8.0;            // rear grille hex opening, across corners (= largest opening, <= 8)
rear_rib   = 1.2;
rear_t     = 2.4;            // rear wall / grille thickness

// ---------- filter + frame ----------
filter     = [130, 10];      // [square, thickness] 948DQ-style carbon pad
filter_clr = 0.5;            // recess clearance per side
filter_crush = 1.0;          // recess is this much shallower than the pad: the frame compresses the
                             // pad's edges onto the seal step, so a thin or worn pad still seals
frame_t    = 4.0;
frame_win  = 126;            // grille window (filter edges clamped 2 mm all round)
front_hex  = 14.0;           // frame hex opening, across corners
front_rib  = 1.6;

// ---------- magnets: 6 x 3 mm discs, 4 in the shell + 4 in the frame ----------
mag_d      = 6.0;
mag_t      = 3.0;
mag_fit    = 0.15;           // pocket = magnet + 0.15 (printed holes shrink -> press fit)
mag_depth  = 3.2;
mag_c      = 68.6;           // centre offset from the box centre, X and Z (corners)

// ---------- shell body ----------
W          = 146;            // width  (X)
H          = 146;            // body height (Z), pod sits on top
r_out      = 3.0;            // front-view corner radius
wall       = 2.4;

// ---------- control pod ----------
pod_angle  = 30;             // front face normal points 30 deg above horizontal (toward the user)
pod_lip    = 6.0;            // vertical front strip below the sloped face
pod_L      = 46.0;           // length of the sloped face
lid_t      = 2.4;            // pod lid plate
blk_w      = 8.0;            // insert blocks along both pod side walls
blk_d      = 8.0;
lid_screw_s = [7, pod_L - 6];  // slope positions of the 4 lid screws (2 per side)

// ---------- components (from SparkFun Eagle/KiCad files, via open-gps/case) ----------
// Thing Plus ESP32-S3 (KiCad): 22.86 x 58.42, 2 holes at USB end
tp_w = 22.86;  tp_l = 58.42;
tp_holes = [[2.54, 2.54], [20.32, 2.54]];    // (across, from USB end)
tp_usb_x = 11.43;                            // USB-C centre across board
tp_usb_overhang = 1.5;                       // USB-C shell past board edge
tp_sd_x  = 11.6;                             // microSD card centre (bottom side)
tp_standoff = 2.4;                           // clears the microSD socket under the board

// Generic 0.96" 128x64 SSD1306 I2C OLED (Hosyond etc.), 4-pin header GND/VCC/SCL/SDA on the top
// edge. Typical listing dimensions -- VERIFY WITH CALIPERS, these modules vary by vendor.
// "Top" = header edge = up the slope. Mounted with 4 M2 x 4 self-tapping screws from behind,
// through the PCB into printed bosses (1.6 mm pilots).
oled_pcb      = [27.3, 27.8, 1.2];   // [W, H, thickness]                        (verify)
oled_hole_in  = 2.0;                 // hole centres from each PCB edge -> 23.3 x 23.8 (verify)
oled_glass    = [26.7, 19.3, 1.5];   // glass panel [W, H, thickness incl. tape] (verify)
oled_glass_top = 4.5;                // glass top edge below the PCB top edge   (verify)
oled_aa       = [21.74, 10.86];      // active (lit) area
oled_aa_top   = 1.6;                 // active area top edge below the glass top edge (verify)
oled_window   = [24.0, 13.0];        // face window = active area + ~1 mm per side
oled_chamfer  = 1.0;                 // outside chamfer around the window
oled_pocket   = 0.6;                 // glass recess into the inside of the face (skin in front of the glass = lid_t - this)
oled_hdr_in   = 1.5;                 // header pin row from the PCB top edge     (verify)
oled_hdr_n    = 4;                   // 0.1" pins
oled_hdr_h    = 2.5;                 // header plastic behind the PCB
oled_hdr_pins = 6.0;                 // pins past the plastic
oled_stub     = 1.2;                 // pin stubs + solder on the glass side (relieved in the face)
oled_dupont   = 15;                  // clearance behind the PCB at the header for Dupont housings
oled_back     = 1.5;                 // SMD parts on the back of the PCB
oled_pilot    = 1.6;                 // M2 self-tapping pilot
oled_boss_d   = 3.6;                 // the bottom bosses sit 0.2 mm from the glass edge: keep <= 3.6

// Bare EC11 rotary encoder with push switch (panel mount, M7 x 0.75 bushing, 6 mm D shaft).
// Body sits in a shallow pocket so the face is enc_face_t at the bushing: bushing 5 mm >=
// face + washer + nut. 3 encoder pins on one edge, 2 switch pins on the other, 2 side legs.
enc_body   = [12.5, 13.5, 6.5];      // [W (legs side to side), D (pin edge to pin edge), H behind the panel]
enc_bush   = [7.0, 5.0];             // threaded bushing [d, length]
enc_hole   = 7.4;                    // panel hole for the M7 bushing
enc_pocket = 0.4;                    // body pocket into the inside of the face
enc_face_t = lid_t - enc_pocket;     // face thickness at the bushing (must be <= 2.5)
enc_shaft_d = 6.0;
enc_flat   = 4.5;                    // D-flat: shaft is 4.5 across the flat
enc_shaft_L = 20;                    // shaft length from the mounting face (generic "L20" = 15 mm past the bushing) (verify)
enc_flat_L = 12;                     // length of the flat, from the shaft tip (verify)
enc_pins_L = 4.0;                    // pins past the body back
enc_wires  = 8.0;                    // soldered wires / heat-shrink behind the pins
enc_washer = [12.0, 0.5];            // [OD, thickness]
enc_nut    = [10.0, 2.0];            // M7 x 0.75 hex nut [across flats, thickness]

// Protoboard (~50 x 30). Hole positions are an estimate: measure yours.
proto = [50, 30, 1.6];
proto_hole_in = 2.5;
proto_standoff = 3.0;
proto_parts_h = 15;  // tallest part incl. the mated fan plug: keep the fan header on the rear half
proto_front_h = 12;  // parts on the front half (under the OLED): resistors, TO-92, wire links

// ---------- tilt base ----------
// The case hangs between two cheeks of a base plate on M3 shoulder screws: one pivot screw and
// one lock screw per side. The cheeks have 3 lock holes, so the case tilts FORWARD (intake aims
// down at the work) by 0, 15 or 30 deg. The plate reaches well forward so the centre of mass
// stays far inside the footprint at every tilt. The knob is ~190 mm up and is pressed toward the
// rear, so the plate also reaches 80 mm behind the case, and a ballast plinth at the front takes
// steel flat bar: with ~575 g of steel a 10 N press along the knob axis can't tip it at 0/15/30 deg.
tilts      = [0, 15, 30];
piv        = [8, 8];         // pivot, in the shell's side walls: body (y, z)
lock_r     = 25;             // lock-screw insert, this far behind the pivot (body)
piv_h      = 15;             // pivot above the plate top (the frame's bottom edge clears the plate at 30 deg)
base_t     = 4;
base_reach = [75, 80];       // plate reach in front of the shell face / behind the rear face
base_r     = 8;
cheek_t    = 5;
cheek_gap  = 1.0;            // cheek to shell side; shoulder length = cheek_t + cheek_gap
cheek_r    = 7;
shoulder   = [4.0, 6, 5];    // ISO 7379 shoulder screw: [shoulder d, shoulder length, M3 thread length]
shoulder_bore = 4.3;
// ballast plinth (front of the plate): open-top pockets for 25 x 12 mm (or 1" x 1/2") steel flat bar.
// One 140 mm bar across the front, two 52 mm bars behind it either side of a finger notch, which
// leaves room to reach under the frame's finger scoop at 0 deg.
bal_bar    = [25.4, 12.7];   // bar section the pockets fit: [width, thickness]
bal_clr    = 0.4;            // pocket clearance per side (width and length) and over the top
bal_len    = [140, 52];      // bar lengths: front pocket, each of the two rear pockets
bal_floor  = 2.0;            // pocket floor
bal_wall   = [2.4, 3.0, 3.2];  // front wall, wall between the rows, rear wall
notch_w    = 30;             // finger notch in the rear row, centred on the scoop

// ---------- derived ----------
cx = W/2; cz = H/2;                       // fan / filter centre (front view)
rec_d    = filter[1] - filter_crush;         // filter recess depth
D        = rec_d + fan_gap_f + fan[1] + plenum + rear_t;
fan_y0   = rec_d + fan_gap_f;
fan_y1   = fan_y0 + fan[1];
rear_in  = D - rear_t;
pk       = fan[0] + 2*fan_clr;           // fan pocket
pk0      = cz - pk/2; pk1 = cz + pk/2;
rec      = filter[0] + 2*filter_clr;     // filter recess
z0       = H + pod_lip;                  // bottom of the slope
pod_h    = pod_lip + pod_L*cos(pod_angle);
Ht       = H + pod_h;                    // overall height
run      = pod_L*sin(pod_angle);

// fan holes (front view x, z)
fan_holes = [for (sx=[-1,1], sz=[-1,1]) [cx + sx*fan_hole_s/2, cz + sz*fan_hole_s/2]];
mags      = [for (sx=[-1,1], sz=[-1,1]) [cx + sx*mag_c, cz + sz*mag_c]];

// pod floor layout
tp_xe   = W - wall - 0.3 - tp_usb_overhang;  // Thing Plus USB-end edge (USB-C face 0.3 inside the right wall)
tp_y0   = D - wall - 1 - tp_w;
z_tp    = H + tp_standoff;
usb_y   = tp_y0 + tp_usb_x;
usb_z   = z_tp + 1.6 + 1.6;
proto_x0 = 11; proto_y0 = 12;
z_pb    = H + proto_standoff;
proto_holes = [for (hx=[proto_hole_in, proto[0]-proto_hole_in], hy=[proto_hole_in, proto[1]-proto_hole_in])
               [proto_x0 + hx, proto_y0 + hy]];
cable_slot = [64, 12];                       // [x0, width] fan cable / plug pass-through into the pod

// pod lid layout (slope coords: x, s up the slope)
// The OLED window and the knob are a balanced pair: both at the middle of the slope (face_cs),
// pair_dx either side of the pod's centre line.
pair_dx = 22;  face_cs = pod_L/2;
win_cx  = cx - pair_dx; win_cs = face_cs;       // window centre = active-area centre
enc_cx  = cx + pair_dx; enc_cs = face_cs;       // encoder / knob axis
oled_top  = win_cs + oled_glass_top + oled_aa_top + oled_aa[1]/2;   // PCB top (header) edge, s
oled_s0   = oled_top - oled_pcb[1];                                  // PCB bottom edge, s
glass_s1  = oled_top - oled_glass_top;  glass_s0 = glass_s1 - oled_glass[1];
n_glass   = -(lid_t - oled_pocket);             // glass front face (n)
n_pcb_f   = n_glass - oled_glass[2];            // PCB front face
n_pcb_b   = n_pcb_f - oled_pcb[2];              // PCB back face
oled_holes = [for (sx=[-1,1], s=[oled_top - oled_hole_in, oled_s0 + oled_hole_in])
              [win_cx + sx*(oled_pcb[0]/2 - oled_hole_in), s]];
hdr_s     = oled_top - oled_hdr_in;
n_enc     = -enc_face_t;                        // encoder mounting face (n)
lid_screws = [for (x=[wall + blk_w/2, W - wall - blk_w/2], s=lid_screw_s) [x, s]];

// tilt base
piv_zw   = base_t + piv_h;                    // pivot height above the desk
lock_pt  = [piv[0] + lock_r, piv[1]];         // body (y, z)
lock_holes = [for (t = tilts) [piv[0] + lock_r*cos(t), piv_zw + lock_r*sin(t)]];   // world (y, z), in the cheeks
base_y0  = -base_reach[0];  base_y1 = D + base_reach[1];
cheek_x  = [-cheek_gap - cheek_t, W + cheek_gap];
bal_pw   = bal_bar[0] + 2*bal_clr;            // pocket width (along Y)
plinth_h = bal_floor + bal_bar[1] + bal_clr;  // plinth top above the desk
bal_py   = [base_y0 + bal_wall[0], base_y0 + bal_wall[0] + bal_pw + bal_wall[1]];   // pocket front edges (y)
plinth_y1 = bal_py[1] + bal_pw + bal_wall[2];  // plinth rear face (y)
bal_rx   = notch_w/2 + bal_wall[1] + bal_len[1]/2 + bal_clr;   // rear pockets' centre offset from cx
// place the case (and anything in its body frame) at tilt th, forward-positive
module pose(th) translate([0, piv[0], piv_zw]) rotate([th, 0, 0]) translate([0, -piv[0], -piv[1]]) children();

echo(str("OUTER SIZE (mm): ", W, " x ", D, " x ", Ht, "  (W x D x H; frame adds ", frame_t, " in front)"));
echo(str("fan y ", fan_y0, "..", fan_y1, "  rear wall y ", rear_in, "..", D, "  pod top z ", Ht));
echo(str("base: ", W + 2*(cheek_gap + cheek_t), " x ", base_y1 - base_y0, " mm; pivot ", piv_zw,
         " above desk; lock holes (y, z) ", lock_holes));
echo(str("ballast plinth: y ", base_y0, "..", plinth_y1, ", ", plinth_h, " mm tall; pockets ",
         bal_len[0] + 2*bal_clr, " and 2 x ", bal_len[1] + 2*bal_clr, " long, ", bal_pw, " wide"));

// =====================================================================
// helpers
// =====================================================================
module rrect2(w, h, r) { offset(r) square([w-2*r, h-2*r], center=true); }
// 2D shape in the front view (x, z) extruded along Y from y0 to y1
module front_extrude(y0, y1) translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
// 2D shape in the side view (y, z) extruded along X from x0 to x1
module side_extrude(x0, x1) translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0) children();
// slope frame of the pod face: (x, s up the slope, n outward normal); origin at the slope's bottom edge
module slope_frame()
    multmatrix([[1, 0, 0, 0],
                [0, sin(pod_angle), -cos(pod_angle), 0],
                [0, cos(pod_angle),  sin(pod_angle), z0],
                [0, 0, 0, 1]]) children();
module slope_inverse()
    multmatrix([[1, 0, 0, 0],
                [0,  sin(pod_angle), cos(pod_angle), -z0*cos(pod_angle)],
                [0, -cos(pod_angle), sin(pod_angle), -z0*sin(pod_angle)],
                [0, 0, 0, 1]]) children();
module ycyl(d, h) rotate([-90, 0, 0]) cylinder(d=d, h=h);      // cylinder along +Y
module xcyl(d, h) rotate([0, 90, 0]) cylinder(d=d, h=h);       // cylinder along +X

// hex lattice of openings (flat-top hexes, across-corners = ac) clipped by children()
module hex_grille2d(ac, rib, cxy, span) {
    R = ac/2;
    pitch = 2*R*cos(30) + rib;
    px = pitch*cos(30);
    n = ceil(span/pitch) + 1;
    intersection() {
        children();
        for (i=[-n:n], j=[-n:n])
            translate([cxy[0] + i*px, cxy[1] + j*pitch + (abs(i)%2)*pitch/2]) circle(r=R, $fn=6);
    }
}
module rear_open2d()  hex_grille2d(rear_hex, rear_rib, [cx, cz], grille_d/2) translate([cx, cz]) circle(d=grille_d, $fn=128);
module front_open2d() hex_grille2d(front_hex, front_rib, [cx, cz], frame_win/2) translate([cx, cz]) square(frame_win, center=true);

// =====================================================================
// SHELL - fan box + control pod in one piece (prints rear-down)
// =====================================================================
module outer() intersection() {
    front_extrude(0, D) translate([W/2, Ht/2]) rrect2(W, Ht, r_out);
    side_extrude(-1, W + 1) polygon([[0, 0], [D, 0], [D, Ht], [run, Ht], [0, z0]]);
}
module lid_band() slope_frame() translate([-1, 0, -lid_t]) cube([W + 2, 200, 60]);
module pod_cavity() intersection() {
    translate([wall, wall, H]) cube([W - 2*wall, D - 2*wall, Ht - wall - H]);
    slope_frame() translate([-1, -60, -100]) cube([W + 2, 300, 100 - lid_t + 0.5]);
}
module insert_block() slope_frame() hull() {
    translate([wall - 0.5, 0, -lid_t - blk_d - 0.75*blk_w]) cube([0.5, pod_L + 3, blk_d + 0.75*blk_w]);
    translate([wall + blk_w - 0.01, 0, -lid_t - blk_d]) cube([0.01, pod_L + 3, blk_d]);
}
module shell() {
    difference() {
        union() {
            difference() {
                outer();
                translate([cx - rec/2, -1, cz - rec/2]) cube([rec, rec_d + 1, rec]);          // filter recess
                translate([pk0, rec_d - 0.01, pk0]) cube([pk, rear_in - rec_d + 0.01, pk]);   // fan pocket + plenum
                pod_cavity();
                lid_band();
            }
            // fan insert pads in the plenum, hulled into the pocket corners
            for (h = fan_holes) hull() {
                translate([h[0], fan_y1, h[1]]) ycyl(10, rear_in - fan_y1 + 0.01);
                translate([h[0] < cx ? pk0 : pk1 - 1, fan_y1, h[1] < cz ? pk0 : pk1 - 1]) cube([1, rear_in - fan_y1 + 0.01, 1]);
            }
            // insert blocks along the pod side walls (45-deg-ish underside for rear-down printing)
            intersection() {
                union() { insert_block(); translate([W, 0, 0]) mirror([1, 0, 0]) insert_block(); }
                difference() { outer(); lid_band(); }
                translate([-1, -1, H]) cube([W + 2, D + 2, pod_h]);
            }
            // Thing Plus standoffs (USB end) + far-end rest
            tp_frame() {
                for (h = tp_holes) translate([h[0], h[1], -tp_standoff - 0.5]) cylinder(d=5, h=tp_standoff + 0.5);
                translate([tp_w/2 - 5, tp_l - 4, -tp_standoff - 0.5]) cube([10, 3, tp_standoff + 0.5]);
            }
            // protoboard standoffs
            for (p = proto_holes) translate([p[0], p[1], H - 0.5]) cylinder(d=4.5, h=proto_standoff + 0.5);
        }
        // rear finger-guard grille
        front_extrude(rear_in - 1, D + 1) rear_open2d();
        // fan inserts
        for (h = fan_holes) translate([h[0], fan_y1 - 0.01, h[1]]) ycyl(insert_d, insert_l + 0.5);
        // magnet pockets (front face corners)
        for (m = mags) translate([m[0], -0.01, m[1]]) ycyl(mag_d + mag_fit, mag_depth + 0.01);
        // finger scoop under the frame's bottom edge
        translate([cx - 12, -0.01, -0.01]) cube([24, 3, 4]);
        // fan cable channel: plenum -> pod floor (behind the fan, so pod air can't reach the intake)
        translate([cable_slot[0], fan_y1 - 0.5, pk1 - 1]) cube([cable_slot[1], rear_in - fan_y1 + 0.5, H - pk1 + 1.5]);
        // pod lid inserts
        for (p = lid_screws) slope_frame() translate([p[0], p[1], -lid_t - insert_l - 0.5]) cylinder(d=insert_d, h=insert_l + 0.51);
        // pilots
        tp_frame() for (h = tp_holes) translate([h[0], h[1], -tp_standoff]) cylinder(d=m25_pilot, h=10);
        for (p = proto_holes) translate([p[0], p[1], H]) cylinder(d=m2_pilot, h=10);
        // right side: USB-C + microSD
        translate([W - wall - 1, usb_y, usb_z]) rotate([0, 90, 0]) linear_extrude(wall + 2) rrect2(7.0, 12.6, 2.2);
        translate([W - wall - 1, tp_y0 + tp_sd_x, z_tp - 0.7]) rotate([0, 90, 0]) linear_extrude(wall + 2) rrect2(2.6, 12.4, 0.6);
        // tilt-base inserts: pivot + lock, both side walls
        // (the pivot hole stops at insert_l: it sits 7.5 mm from the filter recess, leaving 1.8 mm)
        for (p = [[piv, insert_l], [lock_pt, insert_l + 0.5]]) {
            translate([-0.01, p[0][0], p[0][1]]) xcyl(insert_d, p[1] + 0.01);
            translate([W + 0.01, p[0][0], p[0][1]]) rotate([0, 0, 180]) xcyl(insert_d, p[1] + 0.01);
        }
    }
}
module tp_frame() multmatrix([[0, -1, 0, tp_xe], [1, 0, 0, tp_y0], [0, 0, 1, z_tp], [0, 0, 0, 1]]) children();

// =====================================================================
// FRAME - magnetic filter grille (modelled in assembly position, y = -frame_t..0)
// =====================================================================
module frame() {
    difference() {
        front_extrude(-frame_t, 0) difference() {
            translate([cx, cz]) rrect2(W, H, r_out);
            front_open2d();
        }
        for (m = mags) translate([m[0], -mag_depth, m[1]]) ycyl(mag_d + mag_fit, mag_depth + 0.01);
    }
}

// =====================================================================
// POD LID - sloped control face (modelled in assembly position)
// =====================================================================
module pod_lid() {
    difference() {
        union() {
            intersection() { outer(); lid_band(); slope_frame() translate([-1, 0, -lid_t]) cube([W + 2, 200, lid_t]); }
            slope_frame() {
                // OLED bosses: from the lid's inside face back to the PCB's front face (the glass
                // sits in its pocket, so the PCB lands on the bosses)
                for (h = oled_holes) translate([h[0], h[1], n_pcb_f])
                    cylinder(d=oled_boss_d, h=-lid_t - n_pcb_f + 0.01);
            }
        }
        slope_frame() {
            // OLED: M2 pilots (stop 0.6 mm short of the face), glass pocket, header solder relief
            for (h = oled_holes) translate([h[0], h[1], n_pcb_f - 1]) cylinder(d=oled_pilot, h=-0.6 - n_pcb_f + 1);
            translate([win_cx - oled_glass[0]/2 - clr, glass_s0 - clr, -lid_t - 0.01])
                cube([oled_glass[0] + 2*clr, oled_glass[1] + 2*clr, oled_pocket + 0.01]);
            translate([win_cx - oled_hdr_n*2.54/2 - 0.75, hdr_s - 1.5, -lid_t - 0.01])
                cube([oled_hdr_n*2.54 + 1.5, 3.0, oled_pocket + 0.01]);
            // OLED window over the active area (not the glass centre), with an outside chamfer
            translate([win_cx, win_cs, 0]) hull() {
                translate([0, 0, n_glass - 0.01]) linear_extrude(max(0.01, -n_glass - oled_chamfer + 0.01))
                    square(oled_window, center=true);
                translate([0, 0, 0.01]) linear_extrude(0.01)
                    square([oled_window[0] + 2*oled_chamfer + 0.02, oled_window[1] + 2*oled_chamfer + 0.02], center=true);
            }
            // EC11: body pocket (thins the face to enc_face_t) + bushing hole
            translate([enc_cx - enc_body[0]/2 - clr, enc_cs - enc_body[1]/2 - clr, -lid_t - 0.01])
                cube([enc_body[0] + 2*clr, enc_body[1] + 2*clr, enc_pocket + 0.01]);
            translate([enc_cx, enc_cs, -lid_t - 1]) cylinder(d=enc_hole, h=lid_t + 2);
            // lid screws (countersunk M3)
            for (p = lid_screws) translate([p[0], p[1], -lid_t - 1]) {
                cylinder(d=m3_clear, h=lid_t + 2);
                translate([0, 0, 1 + lid_t - (m3_csk_d - m3_clear)/2]) cylinder(d1=m3_clear, d2=m3_csk_d, h=(m3_csk_d - m3_clear)/2 + 0.01);
            }
        }
    }
}

// =====================================================================
// BASE - tilt stand (prints flat). Plate + two cheeks with a pivot hole and 3 lock holes.
// =====================================================================
module base() {
    difference() {
        union() {
            linear_extrude(base_t) translate([W/2, (base_y0 + base_y1)/2])
                rrect2(W + 2*(cheek_gap + cheek_t), base_y1 - base_y0, base_r);
            for (x0 = cheek_x) side_extrude(x0, x0 + cheek_t) hull() {
                translate([piv[0] - cheek_r - 4, 0]) square([lock_r + 2*cheek_r + 8, base_t]);
                translate([piv[0], piv_zw]) circle(r=cheek_r);
                for (h = lock_holes) translate(h) circle(r=cheek_r);
            }
            // ballast plinth across the front of the plate
            intersection() {
                linear_extrude(plinth_h) translate([W/2, (base_y0 + base_y1)/2])
                    rrect2(W + 2*(cheek_gap + cheek_t), base_y1 - base_y0, base_r);
                translate([-50, base_y0 - 1, 0]) cube([W + 100, plinth_y1 - base_y0 + 1, plinth_h]);
            }
        }
        for (x0 = cheek_x, h = concat([[piv[0], piv_zw]], lock_holes))
            translate([x0 - 1, h[0], h[1]]) xcyl(shoulder_bore, cheek_t + 2);
        // ballast pockets (open top) and the finger notch
        translate([cx - bal_len[0]/2 - bal_clr, bal_py[0], bal_floor]) cube([bal_len[0] + 2*bal_clr, bal_pw, plinth_h]);
        for (sx = [-1, 1]) translate([cx + sx*bal_rx - bal_len[1]/2 - bal_clr, bal_py[1], bal_floor])
            cube([bal_len[1] + 2*bal_clr, bal_pw, plinth_h]);
        translate([cx - notch_w/2, bal_py[1], base_t]) cube([notch_w, plinth_y1 - bal_py[1] + 1, plinth_h]);
    }
}
// steel ballast bars (ghosts)
module comp_ballast() color([0.35, 0.35, 0.38]) {
    translate([cx - bal_len[0]/2, bal_py[0] + bal_clr, bal_floor]) cube([bal_len[0], bal_bar[0], bal_bar[1]]);
    for (sx = [-1, 1]) translate([cx + sx*bal_rx - bal_len[1]/2, bal_py[1] + bal_clr, bal_floor])
        cube([bal_len[1], bal_bar[0], bal_bar[1]]);
}
// shoulder screws for tilt i: pivot + lock, both sides (world frame)
module comp_screws(i) color([0.6, 0.6, 0.6]) for (h = [[piv[0], piv_zw], lock_holes[i]]) {
    for (m = [0, 1]) translate([m*W, 0, 0]) mirror([m, 0, 0]) translate([0, h[0], h[1]]) {
        translate([-shoulder[1] - 3, 0, 0]) xcyl(7, 3);                     // head
        translate([-shoulder[1], 0, 0]) xcyl(shoulder[0], shoulder[1]);     // 4 mm shoulder
        xcyl(3.0, shoulder[2]);                                             // M3 thread, into the insert
    }
}

// =====================================================================
// KNOB - for the EC11's 6 mm D shaft: +0.15 round bore, 3 crush ribs on the round side, and a
// D-flat at 4.5 mm over the part of the bore the shaft's flat reaches. Press it on until the
// shaft bottoms in the bore: that leaves knob_gap above the nut for the push switch's travel.
// =====================================================================
knob_d = 18; knob_gap = 1.0; knob_top = 3.0; shaft_d = enc_shaft_d;
knob_z0    = enc_washer[1] + enc_nut[1] + knob_gap;   // knob bottom above the face (n)
shaft_tip  = n_enc + enc_shaft_L;                      // shaft tip above the face (n)
bore_depth = shaft_tip - knob_z0;
knob_h     = bore_depth + knob_top;
flat_zone  = min(bore_depth - 0.6, enc_flat_L - 0.5); // D part of the bore, measured down from its bottom
echo(str("EC11: face ", enc_face_t, " at the bushing, bushing spare thread ",
         enc_bush[1] - enc_face_t - enc_washer[1] - enc_nut[1], "; shaft ", shaft_tip - enc_washer[1] - enc_nut[1],
         " past face+nut; knob bore ", bore_depth, " (D for the top ", flat_zone, "), knob ", knob_h, " tall"));
module knob() {
    difference() {
        union() {
            cylinder(d=knob_d, h=knob_h - 1);
            translate([0,0,knob_h-1]) cylinder(d1=knob_d, d2=knob_d-2, h=1);
            for (a=[0:15:359]) rotate(a) translate([knob_d/2, 0, 0]) cylinder(d=1.2, h=knob_h - 1, $fn=12);
        }
        translate([0,0,-0.01]) cylinder(d=shaft_d + 0.15, h=bore_depth + 0.01);
        translate([0,0,-0.01]) cylinder(d1=shaft_d + 1, d2=shaft_d + 0.15, h=0.6);
    }
    // D-flat (the shaft's flat faces +x)
    translate([0, 0, bore_depth - flat_zone]) intersection() {
        cylinder(d=shaft_d + 0.2, h=flat_zone);
        translate([enc_flat - shaft_d/2, -shaft_d, 0]) cube([shaft_d, 2*shaft_d, flat_zone]);
    }
    // crush ribs, on the round side only
    for (a=[120:60:240]) rotate(a) translate([shaft_d/2 + 0.08, 0, 0]) cylinder(d=0.6, h=bore_depth - 1, $fn=8);
}
module knob_placed() slope_frame() translate([enc_cx, enc_cs, knob_z0]) knob();

// =====================================================================
// ghost components for fit checks
// =====================================================================
module comp_fan() {
    color([0.40, 0.28, 0.20], 0.9) translate([cx - fan[0]/2, fan_y0, cz - fan[0]/2]) cube([fan[0], fan[1], fan[0]]);
}
// filter shown compressed to the recess depth (it is filter[1] thick when free)
module comp_filter() color([0.13, 0.13, 0.13], 0.85) translate([cx - filter[0]/2, 0, cz - filter[0]/2]) cube([filter[0], rec_d, filter[0]]);
module comp_mags_shell() color("silver") for (m = mags) translate([m[0], mag_depth - mag_t, m[1]]) ycyl(mag_d, mag_t);
module comp_mags_frame() color("silver") for (m = mags) translate([m[0], -mag_depth, m[1]]) ycyl(mag_d, mag_t);
module comp_inserts() color("gold") {
    for (h = fan_holes) translate([h[0], fan_y1, h[1]]) ycyl(insert_d - 0.02, insert_l);
    for (p = lid_screws) slope_frame() translate([p[0], p[1], -lid_t - insert_l]) cylinder(d=insert_d - 0.02, h=insert_l);
    for (p = [piv, lock_pt]) {
        translate([0, p[0], p[1]]) xcyl(insert_d - 0.02, insert_l);
        translate([W, p[0], p[1]]) rotate([0, 0, 180]) xcyl(insert_d - 0.02, insert_l);
    }
}
module comp_floor() {
    color("red", 0.9) tp_frame() {
        cube([tp_w, tp_l, 1.6]);
        translate([tp_w/2 - 7.7, tp_l - 20.4, 1.6]) cube([15.4, 20.4, 2.4]);           // ESP32 module
        translate([tp_usb_x - 4.5, -tp_usb_overhang, 1.6]) cube([9, 7.5, 3.2]);       // USB-C
        translate([tp_sd_x - 5.5, -4.2, -1.4]) cube([11, 15, 1.4]);                   // microSD card
    }
    color("green", 0.9) translate([proto_x0, proto_y0, z_pb]) {
        cube(proto);
        translate([2, 2, proto[2]]) cube([proto[0] - 4, proto[1]/2 - 2, proto_front_h]);              // front half: low parts
        translate([2, proto[1]/2, proto[2]]) cube([proto[0] - 4, proto[1]/2 - 2, proto_parts_h]);     // rear half: fan header + plug
        translate([5, 5, -1.5]) cube([proto[0] - 10, proto[1] - 10, 1.5]);             // solder joints
    }
}
// 0.96" SSD1306 module: glass in the face's pocket, PCB on the bosses, header + Dupont plugs behind
module comp_oled() slope_frame() {
    color("black") translate([win_cx - oled_glass[0]/2, glass_s0, n_pcb_f]) cube(oled_glass);
    // active area, drawn just proud of the glass so it shows through the window
    color([0.35, 0.75, 1.0]) translate([win_cx - oled_aa[0]/2, win_cs - oled_aa[1]/2, n_glass - 0.2])
        cube([oled_aa[0], oled_aa[1], 0.21]);
    color([0.1, 0.25, 0.65]) difference() {
        translate([win_cx - oled_pcb[0]/2, oled_s0, n_pcb_b]) cube(oled_pcb);
        for (h = oled_holes) translate([h[0], h[1], n_pcb_b - 1]) cylinder(d=2.0, h=oled_pcb[2] + 2);
    }
    // flex tail wrapped round the bottom edge
    color([0.8, 0.5, 0.1]) translate([win_cx - 6, oled_s0 - 0.6, n_pcb_b - 0.3]) {
        cube([12, 0.6, oled_pcb[2] + 0.6]);
        translate([0, 0, oled_pcb[2] + 0.3]) cube([12, glass_s0 - oled_s0 + 0.6, 0.3]);
    }
    // SMD parts on the back, clear of the header strip
    color([0.2, 0.2, 0.2]) translate([win_cx - oled_pcb[0]/2 + 2, oled_s0 + 2, n_pcb_b - oled_back])
        cube([oled_pcb[0] - 4, hdr_s - 2.5 - oled_s0 - 2, oled_back]);
    // header: solder stubs in front, plastic + pins behind, then the Dupont housings' keep-out
    for (i = [0:oled_hdr_n - 1]) translate([win_cx + (i - (oled_hdr_n - 1)/2)*2.54, hdr_s, 0]) {
        color("silver") translate([-0.5, -0.5, n_pcb_f]) cube([1, 1, oled_stub]);
        color("gold") translate([-0.32, -0.32, n_pcb_b - oled_hdr_h - oled_hdr_pins]) cube([0.64, 0.64, oled_hdr_h + oled_hdr_pins]);
    }
    color("black") translate([win_cx - oled_hdr_n*2.54/2, hdr_s - 1.27, n_pcb_b - oled_hdr_h]) cube([oled_hdr_n*2.54, 2.54, oled_hdr_h]);
    color("orange", 0.35) translate([win_cx - oled_hdr_n*2.54/2 - 1, hdr_s - 2, n_pcb_b - oled_dupont])
        cube([oled_hdr_n*2.54 + 2, 4, oled_dupont - oled_hdr_h]);
}
// EC11: body in its pocket, bushing through the face, washer + nut outside, D shaft
module comp_enc(shaft=true) slope_frame() translate([enc_cx, enc_cs, 0]) {
    color([0.75, 0.75, 0.78]) translate([-enc_body[0]/2, -enc_body[1]/2, n_enc - enc_body[2]]) cube(enc_body);
    color("silver") translate([0, 0, n_enc]) cylinder(d=enc_bush[0], h=enc_bush[1]);
    if (shaft) color("white", 0.8) translate([0, 0, n_enc]) linear_extrude(enc_shaft_L) intersection() {
        circle(d=enc_shaft_d);
        translate([enc_flat - enc_shaft_d/2 - enc_shaft_d, -enc_shaft_d/2]) square(enc_shaft_d);
    }
    color("silver") {
        cylinder(d=enc_washer[0], h=enc_washer[1]);
        translate([0, 0, enc_washer[1]]) difference() {
            cylinder(d=enc_nut[0]/cos(30), h=enc_nut[1], $fn=6);
            translate([0, 0, -1]) cylinder(d=enc_bush[0], h=enc_nut[1] + 2);
        }
    }
    zb = n_enc - enc_body[2];
    // pins: 3 (A, C, B) on the top edge, 2 (switch) on the bottom edge; side legs
    color("gold") {
        for (x = [-2.5, 0, 2.5]) translate([x - 0.4, enc_body[1]/2 - 1.5, zb - enc_pins_L]) cube([0.8, 0.4, enc_pins_L]);
        for (x = [-2.5, 2.5])    translate([x - 0.4, -enc_body[1]/2 + 1.1, zb - enc_pins_L]) cube([0.8, 0.4, enc_pins_L]);
        for (sx = [-1, 1]) translate([sx*(enc_body[0]/2 - 0.5) - 0.5, -1.2, zb - 3]) cube([1, 2.4, 3]);
    }
    color("orange", 0.35) translate([-enc_body[0]/2, -enc_body[1]/2, zb - enc_pins_L - enc_wires])
        cube([enc_body[0], enc_body[1], enc_wires]);
}
module comp_lid() { comp_oled(); comp_enc(); }
module components() {
    comp_fan(); comp_filter(); comp_mags_shell(); comp_mags_frame(); comp_inserts();
    comp_floor(); comp_lid();
}
module case_body() { shell(); frame(); pod_lid(); }
module assembled(i, ghosts=true) {
    pose(tilts[i]) {
        color([0.36, 0.45, 0.52]) render() shell();
        color([0.85, 0.85, 0.85]) render() frame();
        color([0.93, 0.93, 0.93]) render() pod_lid();
        if (ghosts) components();
        color("white", 0.8) knob_placed();
    }
    color([0.79, 0.71, 0.35]) render() base();
    if (ghosts) comp_ballast();
    comp_screws(i);
}

// =====================================================================
// part selection
// =====================================================================
if (part == "shell") translate([0, 0, D]) rotate([-90, 0, 0]) shell();                     // rear-down
else if (part == "frame") translate([0, H, frame_t]) rotate([90, 0, 0]) frame();           // face-down
else if (part == "pod_lid") translate([0, pod_L + 2, 0]) rotate([180, 0, 0]) slope_inverse() pod_lid();  // face-down
else if (part == "base" || part == "kickstand") translate([cheek_gap + cheek_t, -base_y0, 0]) base();   // flat
else if (part == "knob") knob();
else if (part == "chk_shell") intersection() { shell(); components(); }
else if (part == "chk_frame") intersection() { frame(); components(); }
else if (part == "chk_pod_lid") intersection() { pod_lid(); components(); }
else if (part == "chk_kickstand" || part == "chk_base") for (i = [0:2]) {
    intersection() { base(); union() { pose(tilts[i]) { case_body(); components(); } comp_screws(i); } }
    intersection() { comp_screws(i); pose(tilts[i]) case_body(); }
    intersection() { comp_ballast(); union() { base(); pose(tilts[i]) { case_body(); components(); } } }
}
else if (part == "chk_shell_frame") intersection() { shell(); frame(); }
else if (part == "chk_shell_pod_lid") intersection() { shell(); pod_lid(); }
else if (part == "chk_desk") for (i = [0:2]) intersection() {      // nothing below the desk at any tilt
    union() { base(); pose(tilts[i]) case_body(); }
    translate([-500, -500, -1000.05]) cube(1000);
}
else if (part == "chk_ghosts") {     // floor boards vs face parts, and OLED vs encoder
    intersection() { union() { comp_fan(); comp_floor(); } comp_lid(); }
    intersection() { comp_oled(); comp_enc(); }
}
else if (part == "chk_knob")         // knob vs everything except the shaft it grips
    intersection() { knob_placed(); union() { case_body(); comp_oled(); comp_enc(shaft=false); } }
else if (part == "pod_face") {       // close-up of the control face
    color([0.36, 0.45, 0.52]) render() shell();
    color([0.93, 0.93, 0.93]) render() pod_lid();
    comp_lid();
    color("white", 0.9) knob_placed();
}
else if (part == "area_rear_open") rear_open2d();
else if (part == "area_rear_total") translate([cx, cz]) circle(d=grille_d, $fn=128);
else if (part == "area_front_open") front_open2d();
else if (part == "area_front_total") translate([cx, cz]) square(frame_win, center=true);
else if (part == "exploded") {
    color([0.36, 0.45, 0.52]) render() shell();
    if (show_components) { comp_floor(); comp_inserts(); comp_mags_shell(); }
    translate([0, -45, 0]) { if (show_components) comp_fan(); }
    translate([0, -95, 0]) { if (show_components) comp_filter(); }
    translate([0, -130, 0]) { color([0.85, 0.85, 0.85]) render() frame(); if (show_components) comp_mags_frame(); }
    slope_frame() translate([0, 0, 45]) slope_inverse() {
        color([0.93, 0.93, 0.93]) render() pod_lid(); if (show_components) comp_lid();
        slope_frame() translate([0, 0, 25]) slope_inverse() color("white", 0.8) knob_placed();
    }
    translate([0, 0, -60]) { color([0.79, 0.71, 0.35]) render() base(); if (show_components) translate([0, 0, 25]) comp_ballast(); }
} else if (part == "assembly") {
    assembled(view_tilt, show_components);
    color([0.55, 0.42, 0.30], 0.35) translate([-40, base_y0 - 30, -2]) cube([W + 80, base_y1 - base_y0 + 60, 2]);   // desk
} else if (part == "poses") {      // 0 / 15 / 30 deg side by side, for the side-view render
    for (i = [0:2]) translate([0, i*230, 0]) assembled(i, false);
}
