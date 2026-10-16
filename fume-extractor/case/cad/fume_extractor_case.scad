// =====================================================================
//  USB-C desk fume extractor - printable case (parametric, OpenSCAD)
//  Parts: shell (fan box + control pod), frame (magnetic filter grille),
//         pod_lid (sloped control face), kickstand, knob
//
//  Export a part:   openscad -D 'part="shell"' -o shell.stl fume_extractor_case.scad
//  part = "assembly" | "exploded" | "shell" | "frame" | "pod_lid" | "kickstand" | "knob"
//  Fit checks (should all be empty):
//         "chk_shell" | "chk_frame" | "chk_pod_lid" | "chk_kickstand" |
//         "chk_shell_frame" | "chk_shell_pod_lid" | "chk_desk" | "chk_ghosts"
//  Area helpers (2D, use with --summary area): "area_rear_open" | "area_rear_total" |
//         "area_front_open" | "area_front_total"
//
//  Frame: X = width (left -> right, viewed from the front), Y = depth (0 = shell front
//  face where the filter goes, +Y toward the rear grille), Z = up (0 = desk).
//  Air: in through the front filter -> fan -> out through the rear grille.
// =====================================================================

part = "assembly";
show_components = true;     // ghost parts in assembly/exploded views
kick_view_deg = 15;         // which detent the assembly view shows (0, 15 or 30)
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
fan_hole_d = 4.3;
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
rock_c     = 8.0;            // 45-deg chamfer on the rear-bottom edge: the edge the case tips back on

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

// Qwiic OLED 1.3" (Eagle): body 35.56 x 25.40 + corner ears, holes 30.48 x 31.75
oled_w = 35.56; oled_body_h = 25.40;
oled_holes_dx = 30.48; oled_holes_dy = 31.75;
oled_glass = [34.5, 23.0];
oled_glass_t = 1.6;  // glass + tape; sets boss length (verify with calipers)
oled_window = [32.0, 20.0];

// Qwiic Twist (Eagle): 30.48 x 25.40, holes 25.40 x 20.32; encoder body 12.4x13.4x7.8
tw_w = 30.48; tw_h = 25.40;
tw_holes_dx = 25.40; tw_holes_dy = 20.32;
enc_body = [12.4, 13.4, 7.8];
enc_hole_d = 9.8;    // clears M9 bushing; plain 6 mm shaft passes too
back_keepout = 3.0;  // pins / Qwiic plugs behind the OLED and Twist boards (estimate)

// Protoboard (~50 x 30). Hole positions are an estimate: measure yours.
proto = [50, 30, 1.6];
proto_hole_in = 2.5;
proto_standoff = 3.0;
proto_parts_h = 15;  // tallest part incl. the mated fan plug

// ---------- kickstand ----------
kick_w     = 20;             // knuckle / leg width (X)
kick_slot  = 20.4;           // slot in the shell
kick_L     = 46;             // pivot to foot centre
kick_rf    = 3.5;            // foot radius
kick_arm_t = 4.0;
kick_kink  = [12, 12];       // [length, angle] of the first leg segment (keeps it clear of the slot roof)
piv_dy     = 10;             // pivot axis in front of the rear face
piv_z      = 6;              // pivot axis height
knuckle_r  = 4.4;
bore_d     = 4.3;            // 4 mm shoulder
seat_r     = 6.2;            // concave detent seat in the shell
slot_clear_r = 4.8;
spring_r   = [5.0, 6.0];     // detent spring arc (inner, outer)
spring_a   = [180, 260];     // its angle span, local (0 = toward the foot)
bump_a     = 186;
bump_r     = 0.6;
lug1_t     = 4.6;            // shoulder screw: 4 mm x 25 mm shoulder = lug1 + slot
shoulder_l = 25;
thread_l   = 5;
nut_af     = 5.5; nut_t = 2.4;
head_pocket = 34;            // room to slide the screw in along X
tilts      = [0, 15, 30];

// ---------- derived ----------
cx = W/2; cz = H/2;                       // fan / filter centre (front view)
D        = filter[1] + fan_gap_f + fan[1] + plenum + rear_t;
fan_y0   = filter[1] + fan_gap_f;
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
oled_cx = 80;  oled_cs = 24;
tw_cx   = 118; tw_cs   = 26.7;
lid_screws = [for (x=[wall + blk_w/2, W - wall - blk_w/2], s=lid_screw_s) [x, s]];

// kickstand
y_p  = D - piv_dy;  z_p = piv_z;
y_E  = D - rock_c;                           // rock edge
kx0  = cx - kick_w/2;
sx0  = cx - kick_slot/2;  sx1 = cx + kick_slot/2;
function leg_phi(th) = let(a = y_p - y_E)
    th + acos((z_p*cos(th) - a*sin(th) - kick_rf)/kick_L);
phis = [for (t = tilts) leg_phi(t)];
// first leg segment touches the slot roof at the rear face when it rises this steeply:
function roof_z(b) = z_p + piv_dy*tan(b) + (kick_arm_t/2)/cos(b);
stop_b = [for (b=[0:0.1:40]) if (roof_z(b) <= z_p + slot_clear_r) b];
stop_phi = 90 + max(stop_b) + kick_kink[1];

echo(str("OUTER SIZE (mm): ", W, " x ", D, " x ", Ht, "  (W x D x H; frame adds ", frame_t, " in front)"));
echo(str("fan y ", fan_y0, "..", fan_y1, "  rear wall y ", rear_in, "..", D, "  pod top z ", Ht));
echo(str("kickstand leg angles (deg from straight down) for tilt 0/15/30: ", phis,
         "  roof stop at ", stop_phi));

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
// local leg angle -> 2D direction (0 = straight toward the foot, i.e. down)
function dir2(a) = [sin(a), -cos(a)];
module sector2(r0, r1, a0, a1) difference() {
    polygon(concat([[0, 0]], [for (a=[a0:(a1-a0)/24:a1]) r1*dir2(a)]));
    circle(r=r0);
}

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
    side_extrude(-1, W + 1) polygon([[0, 0], [y_E, 0], [D, rock_c], [D, Ht], [run, Ht], [0, z0]]);
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
module kick_slot_cut() {
    // knuckle clearance + detent seat (forward / down sector) + opening to the rear and bottom
    translate([sx0, y_p, z_p]) rotate([90, 0, 90]) linear_extrude(kick_slot) {
        circle(r=slot_clear_r);
        sector2(0, seat_r, 250, 382);
        translate([0, -z_p - 1]) square([piv_dy + 1, z_p + 1 + slot_clear_r]);
    }
}
module kick_notches() for (ph = phis)
    translate([sx0 - 0.01, y_p, z_p]) rotate([90, 0, 90]) linear_extrude(kick_slot + 0.02)
        translate(5.9*dir2(ph + bump_a)) circle(r=0.75, $fn=24);

module shell() {
    difference() {
        union() {
            difference() {
                outer();
                translate([cx - rec/2, -1, cz - rec/2]) cube([rec, filter[1] + 1, rec]);      // filter recess
                translate([pk0, filter[1] - 0.01, pk0]) cube([pk, rear_in - filter[1] + 0.01, pk]); // fan pocket + plenum
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
        // kickstand: slot, detent notches, screw pocket, shoulder-screw holes, nut trap
        kick_slot_cut();
        kick_notches();
        translate([sx0 - lug1_t - head_pocket, y_p - 6, -1]) cube([head_pocket, D - y_p + 7, z_p + 6]);
        translate([sx0 - lug1_t - 1, y_p, z_p]) xcyl(bore_d, lug1_t + 2);
        translate([sx1 - 0.5, y_p, z_p]) xcyl(m3_clear, thread_l + 3);
        translate([sx1 + 1.6, y_p, z_p]) hull() {
            xcyl_hex(nut_af + 0.3, nut_t + 0.3);
            translate([0, 0, -z_p - 2]) xcyl_hex(nut_af + 0.3, nut_t + 0.3);
        }
    }
}
module xcyl_hex(af, h) rotate([0, 90, 0]) cylinder(r=af/(2*cos(30)), h=h, $fn=6);
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
                // Twist bosses (board screws on from behind; encoder body touches the lid)
                for (sx=[-1,1], sy=[-1,1])
                    translate([tw_cx + sx*tw_holes_dx/2, tw_cs + sy*tw_holes_dy/2, -lid_t - enc_body[2]])
                        cylinder(d=5.0, h=enc_body[2] + 0.01);
                // OLED bosses at the ear holes (glass presses on the lid)
                for (sx=[-1,1], sy=[-1,1])
                    translate([oled_cx + sx*oled_holes_dx/2, oled_cs + sy*oled_holes_dy/2, -lid_t - oled_glass_t])
                        cylinder(d=4.8, h=oled_glass_t + 0.01);
                // OLED glass locating frame
                translate([oled_cx, oled_cs, -lid_t - 1.0]) linear_extrude(1.01) difference() {
                    square([oled_glass[0] + 2*clr + 2.4, oled_glass[1] + 2*clr + 2.4], center=true);
                    square([oled_glass[0] + 2*clr, oled_glass[1] + 2*clr], center=true);
                    square([oled_glass[0] + 10, 12], center=true);     // gaps for the flex tail + ears
                }
            }
        }
        slope_frame() {
            for (sx=[-1,1], sy=[-1,1]) {
                translate([tw_cx + sx*tw_holes_dx/2, tw_cs + sy*tw_holes_dy/2, -lid_t - enc_body[2] - 1])
                    cylinder(d=m25_pilot, h=enc_body[2] + 1 + lid_t - 0.6);
                translate([oled_cx + sx*oled_holes_dx/2, oled_cs + sy*oled_holes_dy/2, -lid_t - oled_glass_t - 1])
                    cylinder(d=m25_pilot, h=oled_glass_t + 1 + lid_t - 0.6);
            }
            // OLED window with an outside chamfer
            translate([oled_cx, oled_cs, -lid_t - 0.01]) hull() {
                linear_extrude(0.01) square(oled_window, center=true);
                translate([0, 0, lid_t + 0.02]) linear_extrude(0.01)
                    square([oled_window[0] + 2*lid_t, oled_window[1] + 2*lid_t], center=true);
            }
            // encoder shaft / bushing
            translate([tw_cx, tw_cs, -lid_t - 1]) cylinder(d=enc_hole_d, h=lid_t + 2);
            // lid screws (countersunk M3)
            for (p = lid_screws) translate([p[0], p[1], -lid_t - 1]) {
                cylinder(d=m3_clear, h=lid_t + 2);
                translate([0, 0, 1 + lid_t - (m3_csk_d - m3_clear)/2]) cylinder(d1=m3_clear, d2=m3_csk_d, h=(m3_csk_d - m3_clear)/2 + 0.01);
            }
        }
    }
}

// =====================================================================
// KICKSTAND - pivots on a 4 mm x 25 mm M3 shoulder screw in the rear-bottom slot.
// A spring arc on the knuckle clicks a bump into 3 notches in the shell's seat.
// =====================================================================
kick_K = kick_kink[0]*dir2(-kick_kink[1]);
module kick2d() {
    difference() {
        union() {
            circle(r=knuckle_r);
            hull() { circle(d=kick_arm_t); translate(kick_K) circle(d=kick_arm_t); }
            hull() { translate(kick_K) circle(d=kick_arm_t); translate([0, -kick_L]) circle(r=kick_rf); }
            sector2(spring_r[0], spring_r[1], spring_a[0], spring_a[1]);
            sector2(knuckle_r - 0.5, spring_r[1], spring_a[1] - 10, spring_a[1]);   // spring root
            translate(spring_r[1]*dir2(bump_a)) circle(r=bump_r, $fn=24);
        }
        circle(d=bore_d);
    }
}
module kickstand_flat() linear_extrude(kick_w) kick2d();        // print orientation (on its side)
module kickstand_at(phi) translate([kx0, y_p, z_p]) rotate([phi, 0, 0]) rotate([90, 0, 90]) kickstand_flat();

// =====================================================================
// KNOB - copied from open-gps (6 mm shaft, +0.15 bore, 3 crush ribs, light pipe)
// =====================================================================
knob_d = 18; knob_h = 12; shaft_d = 6.0; bore_depth = 10;
module knob() {
    difference() {
        union() {
            cylinder(d=knob_d, h=knob_h - 1);
            translate([0,0,knob_h-1]) cylinder(d1=knob_d, d2=knob_d-2, h=1);
            for (a=[0:15:359]) rotate(a) translate([knob_d/2, 0, 0]) cylinder(d=1.2, h=knob_h - 1, $fn=12);
        }
        translate([0,0,-0.01]) cylinder(d=shaft_d + 0.15, h=bore_depth);
        translate([0,0,-0.01]) cylinder(d1=shaft_d + 1, d2=shaft_d + 0.15, h=0.6);
        translate([0,0,bore_depth - 0.1]) cylinder(d=3, h=knob_h);        // light pipe to the top
    }
    // crush ribs
    for (a=[0:120:359]) rotate(a) translate([shaft_d/2 + 0.08, 0, 0]) cylinder(d=0.6, h=bore_depth - 1, $fn=8);
}

// =====================================================================
// ghost components for fit checks
// =====================================================================
module comp_fan() {
    color([0.40, 0.28, 0.20], 0.9) translate([cx - fan[0]/2, fan_y0, cz - fan[0]/2]) cube([fan[0], fan[1], fan[0]]);
}
module comp_filter() color([0.13, 0.13, 0.13], 0.85) translate([cx - filter[0]/2, 0, cz - filter[0]/2]) cube([filter[0], filter[1], filter[0]]);
module comp_mags_shell() color("silver") for (m = mags) translate([m[0], mag_depth - mag_t, m[1]]) ycyl(mag_d, mag_t);
module comp_mags_frame() color("silver") for (m = mags) translate([m[0], -mag_depth, m[1]]) ycyl(mag_d, mag_t);
module comp_inserts() color("gold") {
    for (h = fan_holes) translate([h[0], fan_y1, h[1]]) ycyl(insert_d - 0.02, insert_l);
    for (p = lid_screws) slope_frame() translate([p[0], p[1], -lid_t - insert_l]) cylinder(d=insert_d - 0.02, h=insert_l);
}
module comp_pivot() color([0.6, 0.6, 0.6]) {
    translate([sx0 - lug1_t - 3, y_p, z_p]) xcyl(7, 3);                       // head
    translate([sx0 - lug1_t, y_p, z_p]) xcyl(4.0, shoulder_l);                // 4 mm shoulder
    translate([sx0 - lug1_t + shoulder_l, y_p, z_p]) xcyl(3.0, thread_l);     // M3 thread
    translate([sx1 + 1.6 + 0.15, y_p, z_p]) xcyl_hex(nut_af, nut_t);          // nut
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
        translate([2, 2, proto[2]]) cube([proto[0] - 4, proto[1] - 4, proto_parts_h]);   // parts + fan plug
        translate([5, 5, -1.5]) cube([proto[0] - 10, proto[1] - 10, 1.5]);             // solder joints
    }
}
module comp_lid() slope_frame() {
    // OLED: glass on the lid, board behind it
    color("black") translate([oled_cx - oled_glass[0]/2, oled_cs - oled_glass[1]/2, -lid_t - oled_glass_t])
        cube([oled_glass[0], oled_glass[1], oled_glass_t]);
    color("red", 0.9) translate([0, 0, -lid_t - oled_glass_t - 1.6]) {
        translate([oled_cx - oled_w/2, oled_cs - oled_body_h/2, 0]) cube([oled_w, oled_body_h, 1.6]);
        for (sx=[-1,1], sy=[-1,1]) translate([oled_cx + sx*oled_holes_dx/2, oled_cs + sy*oled_holes_dy/2, 0])
            cylinder(d=5.08, h=1.6);
        translate([oled_cx - oled_w/2 + 2, oled_cs - oled_body_h/2 + 2, -back_keepout])
            cube([oled_w - 4, oled_body_h - 4, back_keepout]);
    }
    // Twist: encoder body against the lid, board behind
    color("dimgray") translate([tw_cx - enc_body[0]/2, tw_cs - enc_body[1]/2, -lid_t - enc_body[2]]) cube(enc_body);
    color("white", 0.6) translate([tw_cx, tw_cs, -lid_t - enc_body[2]]) cylinder(d=6, h=enc_body[2] + 10);
    color("red", 0.9) translate([tw_cx - tw_w/2, tw_cs - tw_h/2, -lid_t - enc_body[2] - 1.6]) {
        cube([tw_w, tw_h, 1.6]);
        translate([3, 3, -back_keepout]) cube([tw_w - 6, tw_h - 6, back_keepout]);
    }
}
module components() {
    comp_fan(); comp_filter(); comp_mags_shell(); comp_mags_frame(); comp_inserts(); comp_pivot();
    comp_floor(); comp_lid();
}
// everything below the desk (offset 0.05 so the touching faces don't count), case tilted back by th
module below_desk(th) translate([0, y_E, 0]) rotate([th, 0, 0]) translate([-500, -500, -1000.05]) cube(1000);

// =====================================================================
// part selection
// =====================================================================
if (part == "shell") translate([0, 0, D]) rotate([-90, 0, 0]) shell();                     // rear-down
else if (part == "frame") translate([0, H, frame_t]) rotate([90, 0, 0]) frame();           // face-down
else if (part == "pod_lid") translate([0, pod_L + 2, 0]) rotate([180, 0, 0]) slope_inverse() pod_lid();  // face-down
else if (part == "kickstand") translate([knuckle_r + 2, kick_L + kick_rf + 1, 0]) kickstand_flat();     // on its side
else if (part == "knob") knob();
else if (part == "chk_shell") intersection() { shell(); components(); }
else if (part == "chk_frame") intersection() { frame(); components(); }
else if (part == "chk_pod_lid") intersection() { pod_lid(); components(); }
else if (part == "chk_kickstand") intersection() {
    union() { for (ph = phis) kickstand_at(ph); }
    union() { shell(); components(); }
}
else if (part == "chk_shell_frame") intersection() { shell(); frame(); }
else if (part == "chk_shell_pod_lid") intersection() { shell(); pod_lid(); }
else if (part == "chk_desk") for (i = [0:2]) intersection() {
    union() { shell(); kickstand_at(phis[i]); }
    below_desk(tilts[i]);
}
else if (part == "chk_ghosts") intersection() { union() { comp_fan(); comp_floor(); } comp_lid(); }
else if (part == "area_rear_open") rear_open2d();
else if (part == "area_rear_total") translate([cx, cz]) circle(d=grille_d, $fn=128);
else if (part == "area_front_open") front_open2d();
else if (part == "area_front_total") translate([cx, cz]) square(frame_win, center=true);
else if (part == "exploded") {
    color([0.36, 0.45, 0.52]) render() shell();
    if (show_components) { comp_floor(); comp_inserts(); comp_mags_shell(); comp_pivot(); }
    translate([0, -45, 0]) { if (show_components) comp_fan(); }
    translate([0, -95, 0]) { if (show_components) comp_filter(); }
    translate([0, -130, 0]) { color([0.85, 0.85, 0.85]) render() frame(); if (show_components) comp_mags_frame(); }
    slope_frame() translate([0, 0, 45]) slope_inverse() {
        color([0.93, 0.93, 0.93]) render() pod_lid(); if (show_components) comp_lid();
        slope_frame() translate([tw_cx, tw_cs, 25]) color("white", 0.8) knob();
    }
    translate([0, 40, -10]) color([0.79, 0.71, 0.35]) render() kickstand_at(phis[1]);
} else if (part == "assembly") {
    // standing on the desk, tilted back to the chosen detent about the rock edge
    translate([0, y_E, 0]) rotate([-kick_view_deg, 0, 0]) translate([0, -y_E, 0]) {
        color([0.36, 0.45, 0.52]) render() shell();
        color([0.85, 0.85, 0.85]) render() frame();
        color([0.93, 0.93, 0.93]) render() pod_lid();
        if (show_components) components();
        slope_frame() translate([tw_cx, tw_cs, 1]) color("white", 0.8) knob();
        color([0.79, 0.71, 0.35]) render() kickstand_at(leg_phi(kick_view_deg));
    }
    color([0.55, 0.42, 0.30], 0.35) translate([-20, -60, -2]) cube([W + 40, D + 140, 2]);   // desk
}
