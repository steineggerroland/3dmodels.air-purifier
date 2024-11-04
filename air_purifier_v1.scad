include <BOSL2/std.scad>

// Global resolution
$fs = 0.1;  // Don't generate smaller facets than 0.1 mm
$fa = 5;    // Don't generate larger angles than 5 degrees


module hex_louver(hex_width, border_thickness) {
    translate([0,-5,0]) rotate([90,30,0]) {
        cyl(d=hex_width,h=border_thickness+20,$fn=6,circum=true);
    }
}

module hex_louver_cols(start, radius, border_thickness, offset=0, offset_h=0, hex_count, hex_width, h_step_size, rad_step_size) {
    echo(start=start, radius=radius, border_thickness=border_thickness, offset=offset, offset_h=offset_h, hex_count=hex_count, hex_width=hex_width, h_step_size=h_step_size, rad_step_size=rad_step_size)
    for(index=[0:1:hex_count-1]) {
        height=start+offset_h+h_step_size*index;
        for(angle=[0+offset:rad_step_size:355+offset]) {
            translate([-sin(angle) * (radius-border_thickness/2), cos(angle) * (radius-border_thickness/2), height]) {
                rotate([-20, 0, angle]) {
                    hex_louver(hex_width, border_thickness);
                }
            }
        }
    }
}

module hex_louvers(start, end, radius, border_thickness) {
    echo(start=start,end=end,radius=radius,border_thickness=border_thickness);
    hex_count=4;
    h_step_size=(end-start)/hex_count;
    hex_width=(h_step_size)*0.5;
    hex_border_thickness=end-start-3*hex_width;
    optimal_rad_step_size=(2*PI*radius)/(hex_width*6+hex_border_thickness);
    rad_step_size = 360/floor(360/optimal_rad_step_size);
    hex_louver_cols(start=start+hex_width/2, radius=radius, border_thickness=border_thickness, h_step_size=h_step_size, hex_count=hex_count, hex_width=hex_width, rad_step_size=rad_step_size);
    hex_louver_cols(start=start+hex_width/2, radius=radius, border_thickness=border_thickness, offset=rad_step_size/2, offset_h=h_step_size/2, hex_count=hex_count-1, hex_width=hex_width, h_step_size=h_step_size, rad_step_size=rad_step_size);
}

module hollow_cylinder(height, radius, border_thickness) {
    translate([0,0,-border_thickness]) { difference() {
        cylinder(height+border_thickness    , radius, radius, center=false);
        translate([0,0,border_thickness]) {
            cylinder(height-2*border_thickness, radius-2*border_thickness, radius-2*border_thickness, center=false);
        }
        translate([0,0,height-2*border_thickness]) {
            cylinder(30, radius-2*border_thickness, radius-2*border_thickness, center=false);
        }
    }}
}

module cylinder_with_louvers(height, radius, border_thickness, louver_offset) {
    echo(height=height,radius=radius,border_thickness=border_thickness,louver_offset=louver_offset);
    difference() {
        hollow_cylinder(height=height, radius=radius, border_thickness=border_thickness);
        hex_louvers(start=louver_offset, end=height-louver_offset, radius=radius, border_thickness=border_thickness);
    }
}

module line3D(p1, p2, thickness, fn = 24) {
    $fn = fn;

    hull() {
        translate(p1) cylinder(thickness/2,thickness/2,0,$fn=3);
        translate(p2) cylinder(thickness/2,thickness/2,0,$fn=3);
    }
}

module polyline3D(points, thickness, fn) {
    module polyline3D_inner(points, index) {
        if(index < len(points)) {
            line3D(points[index - 1], points[index], thickness, fn);
            polyline3D_inner(points, index + 1);
        }
    }

    polyline3D_inner(points, 1);
}

module spiral(r, start, end, circles, fa, thickness) {
    h = (end-start)/circles;
    points = [
    for(a = [0:fa:360 * circles]) 
        [r * cos(a), r * sin(a), (start + h / (360 / fa) * (a / fa))]
    ];
    polyline3D(points, thickness, fa);
}

module external_thread(r, start, end, pitch) {
    thickness = 2;
    // to have a nice fading at start and end, do one extra circle in the spiral, start/end a half pitch earlier/later and cut the overlap
    groove_count = ((end-start)/pitch) + 1;
    spiral_start = start - pitch/2;
    spiral_end = end + pitch/2;
    intersection() {
        spiral(r, spiral_start, spiral_end, groove_count, $fa, thickness);
        translate([0,0,start]) {
            cylinder(end-start,r+2*thickness,r+2*thickness);
        }
    }
}

module square_fan_mount(diameter, thickness) {
    width=diameter+6;
    height=diameter+6;
    cube(width, thickness, height);
}

module filter_base(params) {
    if (params[0]=="ring_mount") {
        difference() {
            cyl(d=params[1],h=params[3]);
            translate([0,0,-10]) cyl(d=params[2],h=params[3] + 50);
        }
    }
}


filter_diameter = 120;
filter_height = 120;
filter_base_param = ["ring_mount", 70, 44, 2];

fan_size=140;
fan_mount="square_fan_mount";

height=120;
diameter=max(sqrt(2)*(fan_size+6), filter_diameter*1.1);
border_thickness=1.2;

thread_height=height*0.23;
module air_purifier_base() {
    union() {
        cylinder_with_louvers(height=height, radius=diameter/2, border_thickness=border_thickness, louver_offset=height/5);
        external_thread(diameter/2, height-thread_height, height, 2.5);
        translate([0,0,border_thickness]) filter_base(filter_base_param);
    }
}



fan_hole_d = 132;
fan_mount_hole_distance = 125;
filter_attach_d_outer = 91;
filter_attach_d_inner = 88;
filter_attach_thickness = filter_attach_d_outer-filter_attach_d_inner;
module fan_to_filter_funnel() {
    hull() {
        cylinder(h=0.1,d=fan_hole_d);
        translate([0,0,(fan_hole_d-filter_attach_d_inner)]) cylinder(h=0.1,d=filter_attach_d_inner);
    }
}

top_thickness=2.5; //must be greater than the border_thickness
translate([0,0,1.5*height]) rotate([180,0,0]) {
    
    
translate([0,0,-top_thickness]) difference() {
    resize([210,0,0],[true,true,false]) union() {
        difference() {
            cylinder(h=thread_height+top_thickness, d=diameter+top_thickness);
            translate([0,0,top_thickness]) cylinder(h=thread_height+20,d=diameter);
        }
        external_thread(diameter/2, top_thickness, thread_height+top_thickness, 2.5);
    }
    
    translate([0,0,0]) cylinder(h=top_thickness,d1=fan_hole_d,d2=fan_hole_d-filter_attach_thickness);
    
    translate([fan_mount_hole_distance/2,fan_mount_hole_distance/2,0]) cylinder(h=top_thickness+4,d=4,center=true);
    translate([fan_mount_hole_distance/2,-fan_mount_hole_distance/2,0]) cylinder(h=top_thickness+4,d=4,center=true);
    translate([-fan_mount_hole_distance/2,fan_mount_hole_distance/2,0]) cylinder(h=top_thickness+4,d=4,center=true);
    translate([-fan_mount_hole_distance/2,-fan_mount_hole_distance/2,0]) cylinder(h=top_thickness+4,d=4,center=true);
}

translate([0,0,-top_thickness]) tube(h=0.66*thread_height,od1=fan_hole_d+filter_attach_thickness,od2=filter_attach_d_outer,wall=filter_attach_thickness*0.7,anchor=[0,0,-1]);
translate([0,0,0.66*thread_height-top_thickness]) tube(h=0.04*thread_height+top_thickness,od=filter_attach_d_outer-0.3*filter_attach_thickness,id=filter_attach_d_inner+0.3*filter_attach_thickness,anchor=[0,0,-1]);

}

air_purifier_base();