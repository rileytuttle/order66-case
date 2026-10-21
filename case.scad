include <openscad-library-manager/BOSL2/std.scad>
include <openscad-library-manager/BOSL2/screws.scad>

$fn=50;

part = "assembly"; // ["case", "lid", "foot", "key_grid", "assembly"]
assembly_explode = 0; // lifts the lid off the case in the assembly view, or the case out of the lid when nested
assembly_nested = false; // assembly view with the case stored in the lid, lid open side up

key_spacing = 19.05;
corner_radius = 3;

pcb_thickness = 1.6;
rows=6;
cols=12;
mount_screw="M2";
mount_contact_diam=5.5;

// rectangular magnets stood on edge so their big faces point across the wall. the case magnets sit in the case wall
// and the lid magnets sit in the skirt right outside them, so the big faces line up through the skirt
magnet_size = [10, 2, 5]; // [length along wall, thickness across wall, height]
magnet_wall = 1; // material left on each side of the magnet pocket

pcb_size = [228.6, 123];
case_edge_thickness = magnet_size[1] + magnet_wall*2;
case_rounding = 4;
standoff_height = 3; // should be taller than thickest component on the back side
case_bottom_thickness = 3;
case_height = case_bottom_thickness+standoff_height+pcb_thickness+10;
echo(str("case height = ", case_height));
case_pcb_gap = 1;
case_size = [pcb_size[0]+case_edge_thickness*2+case_pcb_gap*2, pcb_size[1]+case_edge_thickness*2+case_pcb_gap*2, case_height];
pcb_to_key_grid=3;

mount_hole_y_offset = 3.65;
mount_screw_head = "flat"; // ["flat", "socket"]
// mount_screw_head = "socket"; // ["flat", "socket"]

usb_cutout_offset = 36.5 + case_pcb_gap + case_edge_thickness;
usb_cutout_size = [15, 7]; // [width, depth down from the top of the case wall]
usb_cutout_rounding = 3;
switch_1_offset = 33.1 + case_pcb_gap + case_edge_thickness;
echo(str("switch 1 offset from right side of case: ", switch_1_offset));
switch_1_width = 13;
switch_1_y_offset = 3;
switch_2_offset = 46.3;
switch_2_width = 6;
switch_1 = true;
switch_2 = false;
magnets=true;
feet=true;

// screw-on tpu feet. the screw goes up through the foot into a nut trapped in the case floor from the inside
foot_screw = "M2";
foot_screw_length = 6;
foot_diam = 15;
foot_dist_from_edge = 25;
foot_head_recess = 1; // how far the screw head sits below the foot's ground face
foot_hole_clearance = 0.4;
foot_head_clearance = 0.6;
foot_nut_clearance = 0.3;
foot_nut_trap_depth = struct_val(nut_info(foot_screw), "thickness") + 0.2;
foot_screw_head_diam = struct_val(screw_info(foot_screw, head="socket"), "head_size");
foot_screw_head_height = struct_val(screw_info(foot_screw, head="socket"), "head_height");
// sized so the screw ends flush with the top of the case floor
foot_height = foot_screw_length - case_bottom_thickness + foot_screw_head_height + foot_head_recess;
echo(str("foot height = ", foot_height, ", case floor under nut = ", case_bottom_thickness - foot_nut_trap_depth));
assert(foot_height - foot_screw_head_height - foot_head_recess >= 2, "foot_screw_length too short for the foot");
assert(case_bottom_thickness - foot_nut_trap_depth >= 1, "case floor too thin under the nut trap");

// the lid steps down over the outside of the case. the ledge at the step sits on the case wall
lid_top_thickness = case_bottom_thickness;
lid_key_clearance = 12; // depth above the top of the case wall
lid_skirt_depth = case_height; // the lid wraps down around the outside of the case to its bottom
// the lid magnet pockets open on the inside face of the skirt, so it only needs a wall behind the magnet
lid_skirt_thickness = magnet_size[1] + magnet_wall;
lid_fit_clearance = 0.5; // gap on each side between the case and the skirt
lid_wrap = lid_fit_clearance + lid_skirt_thickness;
lid_height = lid_top_thickness + lid_key_clearance + lid_skirt_depth;
lid_thumb_cutout_width = 40;
lid_thumb_cutout_fillet = 4; // rounds the corners where the cutout meets the open edge of the skirt
lid_usb_cutout_rounding = 3;
lid_magnet_bridge_width = 4; // flat bridge left at the top of the 45 degree magnet pocket ceiling when printing
lid_magnet_clearance = 0.3; // extra length on the lid magnet pockets, the 45 degree ceiling makes them print snug

module feet_positions()
{
    grid_copies(n=[2,2], spacing=[case_size[0]-foot_dist_from_edge*2, case_size[1]-foot_dist_from_edge*2]) children();
}
// places children at each magnet, spun to run along its wall. inset is from the outside of the case wall
// to the magnet center, negative to go outside the case
module magnet_positions(inset)
{
    params = [
        [-(key_spacing*5)/2, case_size[1]/2-inset, 0],
        [-(key_spacing*5)/2, -(case_size[1]/2-inset), 0],
        [key_spacing*5/2, case_size[1]/2-inset, 0],
        [key_spacing*5/2, -(case_size[1]/2-inset), 0],
        [-(case_size[0]/2-inset), 0, 90],
        [case_size[0]/2-inset, 0, 90]
    ];
    for(param=params)
    {
        translate([param[0], param[1]]) zrot(param[2]) children();
    }
}
module case_magnets(inset=case_edge_thickness/2)
{
    attachable() {
        union() {
            magnet_positions(inset) cuboid(magnet_size, anchor=TOP);
        }
        children();
    }
}

// usb cutout profile down from the top of a wall, l thick through it. hangs off its top back edge
module usb_cutout(l)
{
    cuboid([usb_cutout_size[0], l, usb_cutout_size[1]], anchor=TOP+BACK, rounding=usb_cutout_rounding, edges=[BOTTOM+LEFT, BOTTOM+RIGHT])
    for(pos=[[LEFT, 180], [RIGHT, -90]])
    {
        position(TOP+pos[0]) fillet(r=usb_cutout_rounding, l=l, spin=pos[1], orient=FRONT);
    }
}

module case()
{
    diff() {
        cuboid(case_size, teardrop=true, rounding=case_rounding, except=TOP) {
            position(BOTTOM) tag_diff("remove", "rm", "kp") {
                up(case_bottom_thickness) cuboid([pcb_size[0]+case_pcb_gap*2, pcb_size[1]+case_pcb_gap*2, 20], anchor=BOTTOM, rounding=3, except=[TOP,BOTTOM]) {
                    position(BOTTOM) fwd(mount_hole_y_offset) grid_copies(n=[3, 2], spacing=[4*key_spacing, 2*key_spacing]) {
                        tag("rm") cyl(d=mount_contact_diam, standoff_height, anchor=BOTTOM);
                    }
                }
            }
            position(BOTTOM) fwd(mount_hole_y_offset) grid_copies(n=[3, 2], spacing=[4*key_spacing, 2*key_spacing]) {
                screw_hole(mount_screw, l=30, head=mount_screw_head, thread=false, anchor=TOP, orient=DOWN);
            }
            fudge=1;
            position(BACK+LEFT+TOP) tag("remove") right(usb_cutout_offset) back(fudge/2) usb_cutout(case_edge_thickness+fudge);
            if (switch_1) {
            up(case_bottom_thickness+standoff_height+pcb_thickness+switch_1_y_offset) position(BACK+RIGHT+BOTTOM) tag("remove") left(switch_1_offset) back(fudge/2) cuboid([switch_1_width, case_edge_thickness+fudge, 7], anchor=BACK, rounding=3, except=[FRONT,BACK], teardrop=true);
            // for(pos=[[LEFT, 180], [RIGHT, -90]])
            // {
            //     position(TOP+pos[0]) fillet(r=3, l=case_edge_thickness+fudge, spin=pos[1], orient=FRONT);
            // }
            }
            if (switch_2) {
            position(BACK+RIGHT+TOP) tag("remove") left(switch_2_offset) back(fudge/2) cuboid([switch_2_width, case_edge_thickness+fudge, case_height-(case_bottom_thickness+standoff_height+pcb_thickness)], anchor=TOP+BACK, rounding=3, edges=[BOTTOM+LEFT, BOTTOM+RIGHT])
            for(pos=[[LEFT, 180], [RIGHT, -90]])
            {
                position(TOP+pos[0]) fillet(r=3, l=case_edge_thickness+fudge, spin=pos[1], orient=FRONT);
            }
            }
            if (magnets) {
                tag("remove") position(TOP) case_magnets();
            }
            if (feet)
            {
                tag("remove") position(BOTTOM) feet_positions() {
                    down(0.01) cyl(d=struct_val(screw_info(foot_screw), "diameter")+foot_hole_clearance, l=case_bottom_thickness+0.02, anchor=BOTTOM);
                    up(case_bottom_thickness+0.01) nut_trap_inline(foot_nut_trap_depth+0.01, foot_screw, nutwidth=struct_val(nut_info(foot_screw), "width")+foot_nut_clearance, anchor=TOP);
                }
            }
         }
    }
}

module lid()
{
    fudge = 0.01;
    lid_size = [case_size[0]+lid_wrap*2, case_size[1]+lid_wrap*2, lid_height];
    // modeled open side up for printing. flipped over onto the case, x is mirrored
    diff() {
        cuboid(lid_size, teardrop=true, rounding=case_rounding+lid_wrap, except=TOP) {
            // key pocket, same footprint as the case pocket
            position(BOTTOM) up(lid_top_thickness) tag("remove")
                cuboid([pcb_size[0]+case_pcb_gap*2, pcb_size[1]+case_pcb_gap*2, lid_height-lid_top_thickness+fudge], anchor=BOTTOM, rounding=3, except=[TOP,BOTTOM]);
            // skirt that wraps around the outside of the case. the step at its base is the lip that catches the case wall
            position(TOP) up(fudge) tag("remove")
                cuboid([case_size[0]+lid_fit_clearance*2, case_size[1]+lid_fit_clearance*2, lid_skirt_depth+fudge], anchor=TOP, rounding=case_rounding+lid_fit_clearance, except=[TOP,BOTTOM]);
            if (magnets) {
                // pockets open on the inside face of the skirt, level with the case magnets once the lid is on.
                // the lid prints open side up, so the pocket ceiling steps in at 45 degrees to a short bridge
                tag("remove") position(TOP) down(lid_skirt_depth) magnet_positions(-(lid_fit_clearance + magnet_size[1]/2) + fudge/2) {
                    cuboid([magnet_size[0]+lid_magnet_clearance, magnet_size[1]+fudge, magnet_size[2]], anchor=BOTTOM);
                    up(magnet_size[2]-fudge) prismoid(size1=[magnet_size[0]+lid_magnet_clearance, magnet_size[1]+fudge], size2=[lid_magnet_bridge_width, magnet_size[1]+fudge], h=(magnet_size[0]+lid_magnet_clearance-lid_magnet_bridge_width)/2+fudge, anchor=BOTTOM);
                }
            }
            // thumb notches in the middle of the long sides to get at the case edge and push the lid off
            // half ellipse up from the open edge, with the corners at the edge filleted
            for(side=[FRONT, BACK]) {
                position(side+TOP) fwd(side[1]*lid_wrap/2) force_tag("remove") xrot(90)
                    linear_extrude(lid_wrap+fudge*2, center=true)
                        offset(r=-lid_thumb_cutout_fillet) offset(r=lid_thumb_cutout_fillet) union() {
                            scale([lid_thumb_cutout_width/2, lid_skirt_depth]) circle(r=1, $fn=100);
                            translate([-lid_thumb_cutout_width, 0]) square([lid_thumb_cutout_width*2, lid_thumb_cutout_fillet*2]);
                        }
            }
            // slot in the skirt lined up with the usb cutout in the case wall, open at the edge so the lid goes on with the cable plugged in.
            // the rounded end runs past the top of the case so the corners don't pinch the cutout
            #position(BACK+RIGHT+TOP) up(fudge) back(fudge) left(lid_wrap+usb_cutout_offset) tag("remove")
                cuboid([usb_cutout_size[0]+lid_fit_clearance*2, 3*(lid_wrap+fudge*2), lid_skirt_depth+lid_usb_cutout_rounding+fudge], anchor=TOP+BACK, rounding=lid_usb_cutout_rounding, edges=[BOTTOM+LEFT, BOTTOM+RIGHT]);
            // storage: lid open side up with the keyboard nested in the skirt, case top flush with the open edge.
            // x isn't mirrored that way, so this slot is on the opposite end from the one above and only as deep as the case cutout
            position(BACK+LEFT+TOP) back(fudge) right(lid_wrap+usb_cutout_offset) tag("remove")
                usb_cutout(3*(lid_wrap+fudge*2));
        }
    }
}

module foot()
{
    // print with the flat case side down. the screw head counterbore faces up
    diff() {
        cyl(d=foot_diam, l=foot_height, anchor=BOTTOM, rounding2=1.5) {
            tag("remove") cyl(d=struct_val(screw_info(foot_screw), "diameter")+foot_hole_clearance, l=foot_height+0.02);
            tag("remove") position(TOP) up(0.01) cyl(d=foot_screw_head_diam+foot_head_clearance, l=foot_screw_head_height+foot_head_recess+0.01, anchor=TOP);
        }
    }
}

module key_grid()
{
    fwd(mount_hole_y_offset)
    fwd(key_spacing/2)
    diff()
    cuboid([key_spacing*12, key_spacing*5, 2], rounding=2, except=[TOP,BOTTOM]) {
        tag("remove") grid_copies(n=[12,5], spacing = [key_spacing, key_spacing]) cuboid([14, 14, 2.5]);
        // for(pos=[[0, [BACK+LEFT, BACK+RIGHT]], [10, [BACK+LEFT]], [11, [BACK+RIGHT]]])
        // {
        //     position(BACK+LEFT) right(key_spacing*pos[0]) cuboid([key_spacing, key_spacing, 2], anchor=FRONT+LEFT, rounding=2, edges=pos[1]) tag("remove") cuboid([14, 14, 2.5]);
        // }
        back(key_spacing/2) {
        grid_copies(n=[3,2], spacing=[4*key_spacing, 2*key_spacing]) {
            position(BOTTOM) cyl(d=5, l=pcb_to_key_grid, anchor=TOP);
            position(TOP) screw_hole(mount_screw, l=10, thread=false, anchor=TOP) position(TOP)
            nut_trap_inline(2, anchor=TOP, spin=0);
        }
        move_copies([[-key_spacing*5, -2*key_spacing],
                     [-key_spacing*5, key_spacing],
                     [key_spacing*5,key_spacing],
                     [key_spacing*5,-2*key_spacing],
                     [0, -2*key_spacing]
                     ]) position(BOTTOM) cyl(d=5, l=pcb_to_key_grid, anchor=TOP);
        }
    }
}

if (part == "case") case();
else if (part == "lid") lid();
else if (part == "foot") foot();
else if (part == "key_grid") key_grid();
else if (part == "assembly" && assembly_nested) {
    // case top flush with the open edge of the lid, case bottom resting on the ledge
    up(lid_height/2 - case_height/2 + assembly_explode) {
        case();
        down(case_height/2) feet_positions() yrot(180) color("dimgray") foot();
    }
    color("lightblue", 0.5) lid();
}
else if (part == "assembly") {
    case();
    // ledge of the flipped lid resting on top of the case wall
    up(case_height/2 + lid_height/2 - lid_skirt_depth + assembly_explode) yrot(180) color("lightblue", 0.5) lid();
    down(case_height/2) feet_positions() yrot(180) color("dimgray") foot();
}
