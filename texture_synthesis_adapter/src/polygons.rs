use crate::ffi::LayoutWallPolygon;
use lsun_res_parser::{Line, Point};
use polyfit_rs::polyfit_rs::polyfit;

/// Convert line coordinates between image and geo space, and vice versa.
fn convert_lines_coords_image_geo(lines: &Vec<Line>, height: i32) -> Vec<Line> {
    lines
        .iter()
        .map(|(p1, p2)| {
            let p1: Point = (p1.0, height - 1 - p1.1);
            let p2: Point = (p2.0, height - 1 - p2.1);
            (p1, p2)
        })
        .collect()
}

fn convert_line_coords_image_geo(line: Line, height: i32) -> Line {
    let (p1, p2) = line;
    let p1: Point = (p1.0, height - 1 - p1.1);
    let p2: Point = (p2.0, height - 1 - p2.1);
    (p1, p2)
}

#[derive(Clone, Copy, Debug)]
struct LineSlopeInterceptForm {
    pub slope: f32,
    pub intercept: f32,
}

fn compute_line_params(line: Line) -> LineSlopeInterceptForm {
    let padding: f64 = if line.0 .0 == line.1 .0 { 0.00001 } else { 0. };
    let line_monomials = polyfit(
        &[line.0 .0 as f64, line.1 .0 as f64 + padding],
        &[line.0 .1 as f64, line.1 .1 as f64 + padding],
        1,
    )
    .unwrap();

    LineSlopeInterceptForm {
        slope: line_monomials[1] as f32,
        intercept: line_monomials[0] as f32,
    }
}

fn compute_line_intercept_at_point(slope: f32, point: (f32, f32)) -> f32 {
    // y = ax + b => b = y - ax
    point.1 - slope * point.0
}

fn compute_lines_intersection_point(
    slope1: f32,
    intercept1: f32,
    slope2: f32,
    intercept2: f32,
) -> (f32, f32) {
    // Given two lines 'y = a1 * x + b2 and 'y = a2 * x + b2', finds point of intersection (x, y).
    //
    // a2 * x + b2 = a1 * x + b1
    // a2 * x - a1 * x = b1 - b2
    // (a2 - a1) * x = b1 - b2
    // x = (b1 - b2) / (a2 - a1)

    // Computations might overflow, so calculate using 64-bit precision
    let slope1 = slope1 as f64;
    let slope2 = slope2 as f64;
    let intercept1 = intercept1 as f64;
    let intercept2 = intercept2 as f64;

    let x = (intercept1 - intercept2) / (slope2 - slope1);
    let y = slope1 * x + intercept1; // or y = slope2 * x + intercept2, doesn't matter
    (x as f32, y as f32)
}

#[derive(Clone, Debug)]
pub struct WallPolygon {
    pub top_left: Point,
    pub top_right: Point,
    pub bottom_right: Point,
    pub bottom_left: Point,
}

impl From<LayoutWallPolygon> for WallPolygon {
    fn from(polygon: LayoutWallPolygon) -> Self {
        Self {
            top_left: polygon.top_left.to_point(),
            top_right: polygon.top_right.to_point(),
            bottom_right: polygon.bottom_right.to_point(),
            bottom_left: polygon.bottom_left.to_point(),
        }
    }
}

impl WallPolygon {
    pub fn lines(&self) -> [Line; 4] {
        [
            (self.top_left, self.top_right),
            (self.top_right, self.bottom_right),
            (self.bottom_right, self.bottom_left),
            (self.bottom_left, self.top_left),
        ]
    }
}

pub fn compute_wall_polygons(
    lines: &Vec<Line>,
    image_width: i32,
    image_height: i32,
    room_type: u8,
) -> Vec<WallPolygon> {
    match room_type {
        0 => compute_wall_polygons_for_room_type_0(lines, image_height).to_vec(),
        1 => compute_wall_polygons_for_room_type_1(lines, image_height).to_vec(),
        2 => compute_wall_polygons_for_room_type_2(lines, image_height).to_vec(),
        3 => compute_wall_polygons_for_room_type_3(lines, image_height).to_vec(),
        4 => compute_wall_polygons_for_room_type_4(lines, image_height).to_vec(),
        5 => compute_wall_polygons_for_room_type_5(lines, image_height).to_vec(),
        6 => vec![compute_wall_polygon_for_room_type_6(
            lines,
            image_width,
            image_height,
        )],
        7 => compute_wall_polygons_for_room_type_7(lines, image_height).to_vec(),
        8 => vec![compute_wall_polygon_for_room_type_8(lines, image_height)],
        9 => vec![compute_wall_polygon_for_room_type_9(lines, image_height)],
        10 => compute_wall_polygons_for_room_type_10(lines, image_height).to_vec(),

        _ => {
            // TODO: better return Result with error
            panic!("Unknown room type: {room_type}")
        }
    }
}

fn compute_wall_polygons_for_room_type_0(lines: &Vec<Line>, image_height: i32) -> [WallPolygon; 3] {
    let lines_geo = convert_lines_coords_image_geo(&lines, image_height);

    let line_center_left = lines_geo[4];
    let line_params = compute_line_params(line_center_left);

    let line_left_border_slope = line_params.slope;
    let corner_point = if line_left_border_slope >= 0. {
        (0f32, 511f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_border_intercept =
        compute_line_intercept_at_point(line_left_border_slope, corner_point);

    // Left top, needs to be extended to intersect with left border line
    let line_left_top = lines_geo[0];
    let line_params = compute_line_params(line_left_top);
    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_params.slope,
        line_params.intercept,
    );
    let line_left_top = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_left_top.0,
    );

    // Left botton, needs to be extended to intersect with left border line
    let line_left_bottom = lines_geo[1];
    let line_params = compute_line_params(line_left_bottom);
    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_params.slope,
        line_params.intercept,
    );
    let line_left_bottom = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_left_bottom.0,
    );

    let line_center_right = lines_geo[6];

    // Right border
    let line_params = compute_line_params(line_center_right);
    let line_right_border_slope = line_params.slope;
    let corner_point = if line_right_border_slope >= 0. {
        (511f32, 0f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_border_intercept =
        compute_line_intercept_at_point(line_right_border_slope, corner_point);

    // Right top
    let line_right_top = lines_geo[3];
    let line_params = compute_line_params(line_right_top);
    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_params.slope,
        line_params.intercept,
    );
    let line_right_top = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_right_top.0,
    );

    let line_right_bottom = lines_geo[2];
    let line_params = compute_line_params(line_right_bottom);
    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_params.slope,
        line_params.intercept,
    );
    let line_right_bottom = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_right_bottom.0,
    );

    let left_wall_polygon = WallPolygon {
        top_left: line_left_top.0,
        top_right: line_center_left.0,
        bottom_right: line_center_left.1,
        bottom_left: line_left_bottom.0,
    };

    let center_wall_polygon = WallPolygon {
        top_left: line_center_left.0,
        top_right: line_center_right.1,
        bottom_right: line_center_right.0,
        bottom_left: line_center_left.1,
    };

    let right_wall_polygon = WallPolygon {
        top_left: line_center_right.1,
        top_right: line_right_top.0,
        bottom_right: line_right_bottom.0,
        bottom_left: line_center_right.0,
    };

    [left_wall_polygon, center_wall_polygon, right_wall_polygon]
}

fn compute_wall_polygons_for_room_type_1(lines: &Vec<Line>, image_height: i32) -> [WallPolygon; 3] {
    let lines_geo = convert_lines_coords_image_geo(&lines, image_height);

    // Top left
    let line_center_left = lines_geo[0];
    let line_params = compute_line_params(line_center_left);
    let line_center_left_slope = line_params.slope;
    let line_center_left_theta = line_center_left_slope.atan();

    let line_left_bottom = lines_geo[1];
    let line_params = compute_line_params(line_left_bottom);
    let line_left_bottom_slope = line_params.slope;
    let line_left_bottom_intercept = line_params.intercept;
    let line_left_bottom_theta = line_left_bottom_slope.atan();

    let line_left_top_theta = 2. * line_center_left_theta - line_left_bottom_theta;
    let line_left_top_slope = line_left_top_theta.tan();
    let corner_point = if line_left_top_slope >= 0. {
        (0f32, 511f32)
    } else {
        (line_center_left.1 .0 as f32, line_center_left.1 .1 as f32)
    };
    let line_left_top_intercept =
        compute_line_intercept_at_point(line_left_top_slope, corner_point);

    // Left border
    let line_left_border_slope = line_center_left_slope;
    let corner_point = if line_left_border_slope >= 0. {
        (0f32, 511f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_border_intercept =
        compute_line_intercept_at_point(line_left_border_slope, corner_point);

    // Right top
    let line_center_right = lines_geo[3];
    let line_params = compute_line_params(line_center_right);
    let line_center_right_slope = line_params.slope;
    let line_center_right_theta = line_center_right_slope.atan();

    let line_right_bottom = lines_geo[4];
    let line_params = compute_line_params(line_right_bottom);
    let line_right_bottom_slope = line_params.slope;
    let line_right_bottom_intercept = line_params.intercept;
    let line_right_bottom_theta = line_right_bottom_slope.atan();

    let line_right_top_theta = 2. * line_center_right_theta - line_right_bottom_theta;
    let line_right_top_slope = line_right_top_theta.tan();
    let corner_point = if line_right_top_slope >= 0. {
        (line_center_right.1 .0 as f32, line_center_right.1 .1 as f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_top_intercept =
        compute_line_intercept_at_point(line_right_top_slope, corner_point);

    // Right border
    let line_right_border_slope = line_center_right_slope;
    let corner_point = if line_left_border_slope >= 0. {
        (511f32, 0f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_border_intercept =
        compute_line_intercept_at_point(line_right_border_slope, corner_point);

    // Left polygon
    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_left_top_slope,
        line_left_top_intercept,
    );
    let line_left_top = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_center_left.1,
    );
    let line_left_top = convert_line_coords_image_geo(line_left_top, image_height);

    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_left_bottom_slope,
        line_left_bottom_intercept,
    );
    let line_left_bottom = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_center_left.0,
    );
    let line_left_bottom = convert_line_coords_image_geo(line_left_bottom, image_height);

    let left_wall_polygon = WallPolygon {
        top_left: line_left_top.0,
        top_right: line_left_top.1,
        bottom_right: line_left_bottom.1,
        bottom_left: line_left_bottom.0,
    };

    // Right polygon
    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_right_top_slope,
        line_right_top_intercept,
    );
    let line_right_top = (
        line_center_right.1,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );
    let line_right_top = convert_line_coords_image_geo(line_right_top, image_height);

    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_right_bottom_slope,
        line_right_bottom_intercept,
    );
    let line_right_bottom = (
        line_center_right.0,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );
    let line_right_bottom = convert_line_coords_image_geo(line_right_bottom, image_height);

    let right_wall_polygon = WallPolygon {
        top_left: line_right_top.0,
        top_right: line_right_top.1,
        bottom_right: line_right_bottom.1,
        bottom_left: line_right_bottom.0,
    };

    // Center polygon
    let line_center_left = convert_line_coords_image_geo(line_center_left, image_height);
    let line_center_right = convert_line_coords_image_geo(line_center_right, image_height);

    let center_wall_polygon = WallPolygon {
        top_left: line_center_left.1,
        top_right: line_center_right.1,
        bottom_right: line_center_right.0,
        bottom_left: line_center_left.0,
    };

    [left_wall_polygon, center_wall_polygon, right_wall_polygon]
}

fn compute_wall_polygons_for_room_type_2(lines: &Vec<Line>, image_height: i32) -> [WallPolygon; 3] {
    let lines_geo = convert_lines_coords_image_geo(&lines, image_height);

    let line_left_top = lines_geo[0];
    let line_center_left = lines_geo[1];
    let line_right_top = lines_geo[3];
    let line_center_right = lines_geo[4];

    // Bottom left
    let line_params = compute_line_params(line_left_top);
    let line_left_top_slope = line_params.slope;
    let line_left_top_intercept = line_params.intercept;
    let line_left_top_theta = line_left_top_slope.atan();

    let line_params = compute_line_params(line_center_left);
    let line_center_left_slope = line_params.slope;
    let line_center_left_theta = line_center_left_slope.atan();

    let line_left_bottom_theta = 2. * line_center_left_theta - line_left_top_theta;
    let line_left_bottom_slope = line_left_bottom_theta.tan();

    let corner_point = if line_left_bottom_slope >= 0. {
        (line_center_left.1 .0 as f32, line_center_left.1 .1 as f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_bottom_intercept =
        compute_line_intercept_at_point(line_left_bottom_slope, corner_point);

    // Left border
    let line_left_border_slope = line_center_left_slope;
    let corner_point = if line_left_border_slope >= 0. {
        (0f32, 511f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_border_intercept =
        compute_line_intercept_at_point(line_left_border_slope, corner_point);

    // Right bottom
    let line_params = compute_line_params(line_right_top);
    let line_right_top_slope = line_params.slope;
    let line_right_top_intercept = line_params.intercept;
    let line_right_top_theta = line_right_top_slope.atan();

    let line_params = compute_line_params(line_center_right);
    let line_center_right_slope = line_params.slope;
    let line_center_right_theta = line_center_right_slope.atan();

    let line_right_bottom_theta = 2. * line_center_right_theta - line_right_top_theta;
    let line_right_bottom_slope = line_right_bottom_theta.tan();

    let corner_point = if line_right_bottom_slope >= 0. {
        (511f32, 0f32)
    } else {
        (line_center_right.1 .0 as f32, line_center_right.1 .1 as f32)
    };
    let line_right_bottom_intercept =
        compute_line_intercept_at_point(line_right_bottom_slope, corner_point);

    // Right border
    let line_right_border_slope = line_center_right_slope;
    let corner_point = if line_right_border_slope >= 0. {
        (511f32, 0f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_border_intercept =
        compute_line_intercept_at_point(line_right_border_slope, corner_point);

    // Left polygon
    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_left_top_slope,
        line_left_top_intercept,
    );
    let line_left_top = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_center_left.0,
    );
    let line_left_top = convert_line_coords_image_geo(line_left_top, image_height);

    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_left_bottom_slope,
        line_left_bottom_intercept,
    );
    let line_left_bottom = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_center_left.1,
    );
    let line_left_bottom = convert_line_coords_image_geo(line_left_bottom, image_height);

    let left_wall_polygon = WallPolygon {
        top_left: line_left_top.0,
        top_right: line_left_top.1,
        bottom_right: line_left_bottom.1,
        bottom_left: line_left_bottom.0,
    };

    // Right polygon
    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_right_top_slope,
        line_right_top_intercept,
    );
    let line_right_top = (
        line_center_right.0,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );
    let line_right_top = convert_line_coords_image_geo(line_right_top, image_height);

    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_right_bottom_slope,
        line_right_bottom_intercept,
    );
    let line_right_bottom = (
        line_center_right.1,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );
    let line_right_bottom = convert_line_coords_image_geo(line_right_bottom, image_height);

    let right_wall_polygon = WallPolygon {
        top_left: line_right_top.0,
        top_right: line_right_top.1,
        bottom_right: line_right_bottom.1,
        bottom_left: line_right_bottom.0,
    };

    // Center polygon
    let line_center_left = convert_line_coords_image_geo(line_center_left, image_height);
    let line_center_right = convert_line_coords_image_geo(line_center_right, image_height);

    let center_wall_polygon = WallPolygon {
        top_left: line_center_left.0,
        top_right: line_center_right.0,
        bottom_right: line_center_right.1,
        bottom_left: line_center_left.1,
    };

    [left_wall_polygon, center_wall_polygon, right_wall_polygon]
}

fn compute_wall_polygons_for_room_type_3(lines: &Vec<Line>, image_height: i32) -> [WallPolygon; 2] {
    let lines_geo = convert_lines_coords_image_geo(&lines, image_height);

    let line_left_top = lines_geo[0];
    let line_center = lines_geo[1];
    let line_right_top = lines_geo[2];

    // Left bottom
    let line_params = compute_line_params(line_left_top);
    let line_left_top_slope = line_params.slope;
    let line_left_top_intercept = line_params.intercept;
    let line_params = compute_line_params(line_center);
    let line_center_slope = line_params.slope;
    let line_center_theta = line_center_slope.atan();
    let line_left_top_theta = line_left_top_slope.atan();
    let line_left_bottom_theta = 2. * line_center_theta - line_left_top_theta;
    let line_left_bottom_slope = line_left_bottom_theta.tan();
    let corner_point = if line_left_bottom_slope >= 0. {
        (line_center.1 .0 as f32, line_center.1 .1 as f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_bottom_intercept =
        compute_line_intercept_at_point(line_left_bottom_slope, corner_point);

    // Left border
    let line_left_border_slope = line_center_slope;
    let corner_point = if line_left_border_slope >= 0. {
        (0f32, 511f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_border_intercept =
        compute_line_intercept_at_point(line_left_border_slope, corner_point);

    // Right bottom
    let line_params = compute_line_params(line_right_top);
    let line_right_top_slope = line_params.slope;
    let line_right_top_intercept = line_params.intercept;
    let line_right_top_theta = line_right_top_slope.atan();
    let line_right_bottom_theta = 2. * line_center_theta - line_right_top_theta;
    let line_right_bottom_slope = line_right_bottom_theta.tan();
    let corner_point = if line_right_bottom_slope >= 0. {
        (511f32, 0f32)
    } else {
        (line_center.1 .0 as f32, line_center.1 .1 as f32)
    };
    let line_right_bottom_intercept =
        compute_line_intercept_at_point(line_right_bottom_slope, corner_point);

    // Right border
    let line_right_border_slope = line_center_slope;
    let corner_point = if line_right_border_slope >= 0. {
        (511f32, 0f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_border_intercept =
        compute_line_intercept_at_point(line_left_border_slope, corner_point);

    // Left top line
    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_left_top_slope,
        line_left_top_intercept,
    );
    let line_left_top = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_left_top.0,
    );

    // Left bottom line
    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_left_bottom_slope,
        line_left_bottom_intercept,
    );
    let line_left_bottom = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_center.1,
    );

    // Right top line
    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_right_top_slope,
        line_right_top_intercept,
    );
    let line_right_top = (
        line_center.0,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );

    // Right bottom line
    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_right_bottom_slope,
        line_right_bottom_intercept,
    );
    let line_right_bottom = (
        line_center.1,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );

    let line_left_top = convert_line_coords_image_geo(line_left_top, image_height);
    let line_left_bottom = convert_line_coords_image_geo(line_left_bottom, image_height);
    let line_right_top = convert_line_coords_image_geo(line_right_top, image_height);
    let line_right_bottom = convert_line_coords_image_geo(line_right_bottom, image_height);

    let left_wall_polygon = WallPolygon {
        top_left: line_left_top.0,
        top_right: line_left_top.1,
        bottom_right: line_left_bottom.1,
        bottom_left: line_left_bottom.0,
    };

    let right_wall_polygon = WallPolygon {
        top_left: line_right_top.0,
        top_right: line_right_top.1,
        bottom_right: line_right_bottom.1,
        bottom_left: line_right_bottom.0,
    };

    [left_wall_polygon, right_wall_polygon]
}

fn compute_wall_polygons_for_room_type_4(lines: &Vec<Line>, image_height: i32) -> [WallPolygon; 2] {
    let lines_geo = convert_lines_coords_image_geo(&lines, image_height);

    // 0 - bottom left
    // 1 - vertical
    // 2 - bottom right

    // Left border line
    let line_center = lines_geo[1];
    let line_params = compute_line_params(line_center);
    let line_center_slope = line_params.slope;
    let line_left_border_slope = line_center_slope;
    let corner_point = if line_left_border_slope >= 0. {
        (0f32, 511f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_border_intercept =
        compute_line_intercept_at_point(line_left_border_slope, corner_point);

    // Left top
    let line_bottom_left = lines_geo[0];
    let line_params = compute_line_params(line_bottom_left);
    let line_bottom_left_slope = line_params.slope;
    let line_bottom_left_intercept = line_params.intercept;
    let line_center_theta = line_center_slope.atan();
    let line_bottom_left_theta = line_bottom_left_slope.atan();
    let line_top_left_theta = 2. * line_center_theta - line_bottom_left_theta;
    let line_top_left_slope = line_top_left_theta.tan();
    let corner_point = if line_top_left_slope >= 0. {
        (0f32, 511f32)
    } else {
        (line_center.1 .0 as f32, line_center.1 .1 as f32)
    };
    let line_top_left_intercept =
        compute_line_intercept_at_point(line_top_left_slope, corner_point);

    // Right border
    let line_right_border_slope = line_center_slope;
    let corner_point = if line_right_border_slope >= 0. {
        (511f32, 0f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_border_intercept =
        compute_line_intercept_at_point(line_right_border_slope, corner_point);

    // Right top
    let line_bottom_right = lines_geo[2];
    let line_params = compute_line_params(line_bottom_right);
    let line_bottom_right_slope = line_params.slope;
    let line_bottom_right_intercept = line_params.intercept;
    let line_bottom_right_theta = line_bottom_right_slope.atan();
    let line_top_right_theta = 2. * line_center_theta - line_bottom_right_theta;
    let line_top_right_slope = line_top_right_theta.tan();
    let corner_point = if line_top_right_slope >= 0. {
        (line_center.1 .0 as f32, line_center.1 .1 as f32)
    } else {
        (511f32, 511f32)
    };
    let line_top_right_intercept =
        compute_line_intercept_at_point(line_top_right_slope, corner_point);

    // Left polygon
    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_top_left_slope,
        line_top_left_intercept,
    );
    let line_left_top = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_center.1,
    );

    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_bottom_left_slope,
        line_bottom_left_intercept,
    );
    let line_left_bottom = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_center.0,
    );

    // Convert to image coords
    let line_left_top = convert_line_coords_image_geo(line_left_top, image_height);
    let line_center = convert_line_coords_image_geo(line_center, image_height);
    let line_left_bottom = convert_line_coords_image_geo(line_left_bottom, image_height);

    let left_wall_polygon = WallPolygon {
        top_left: line_left_top.0,
        top_right: line_center.1,
        bottom_right: line_center.0,
        bottom_left: line_left_bottom.0,
    };

    // Right polygon
    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_top_right_slope,
        line_top_right_intercept,
    );
    let line_right_top = (
        line_center.1,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );

    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_bottom_right_slope,
        line_bottom_right_intercept,
    );
    let line_right_bottom = (
        line_center.0,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );

    // Convert to image coords
    let line_right_top = convert_line_coords_image_geo(line_right_top, image_height);
    let line_right_bottom = convert_line_coords_image_geo(line_right_bottom, image_height);

    let right_wall_polygon = WallPolygon {
        top_left: line_center.1,
        top_right: line_right_top.1,
        bottom_right: line_right_bottom.1,
        bottom_left: line_center.0,
    };

    [left_wall_polygon, right_wall_polygon]
}

fn compute_wall_polygons_for_room_type_5(lines: &Vec<Line>, image_height: i32) -> [WallPolygon; 2] {
    let lines_geo = convert_lines_coords_image_geo(&lines, image_height);

    let line_center = lines_geo[2];
    let line_center_params = compute_line_params(line_center);
    let line_center_slope = line_center_params.slope;

    let line_left_border_slope = line_center_slope;
    let corner_point = if line_left_border_slope >= 0. {
        (0f32, 511f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_border_intercept =
        compute_line_intercept_at_point(line_left_border_slope, corner_point);

    // Line 3 - right border
    let line_right_border_slope = line_center_slope;
    let corner_point = if line_right_border_slope >= 0. {
        (511f32, 0f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_border_intercept =
        compute_line_intercept_at_point(line_right_border_slope, corner_point);

    // Left top, just needs to be extend to intersection point with left border line
    let line_left_top = lines_geo[0];
    let line_params = compute_line_params(line_left_top);
    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_params.slope,
        line_params.intercept,
    );
    let line_left_top = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_left_top.0,
    );

    // Left bottom line, also needs to be extended to intersection with left border line
    let line_left_bottom = lines_geo[3];
    let line_params = compute_line_params(line_left_bottom);
    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_params.slope,
        line_params.intercept,
    );
    let line_left_bottom = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_left_bottom.0,
    );

    // Right top line
    let line_right_top = lines_geo[1];
    let line_params = compute_line_params(line_right_top);
    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_params.slope,
        line_params.intercept,
    );
    let line_right_top = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_right_top.0,
    );

    // Right bottom line
    let line_right_bottom = lines_geo[4];
    let line_params = compute_line_params(line_right_bottom);
    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_params.slope,
        line_params.intercept,
    );
    let line_right_bottom = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_right_bottom.0,
    );

    // Convert back to image coords from geo coords
    let line_left_top = convert_line_coords_image_geo(line_left_top, image_height);
    let line_center = convert_line_coords_image_geo(line_center, image_height);
    let line_left_bottom = convert_line_coords_image_geo(line_left_bottom, image_height);
    let line_right_top = convert_line_coords_image_geo(line_right_top, image_height);
    let line_right_bottom = convert_line_coords_image_geo(line_right_bottom, image_height);

    let left_wall_polygon = WallPolygon {
        top_left: line_left_top.0,
        top_right: line_center.0,
        bottom_right: line_center.1,
        bottom_left: line_left_bottom.0,
    };
    let right_wall_polygon = WallPolygon {
        top_left: line_center.0,
        top_right: line_right_top.0,
        bottom_right: line_right_bottom.0,
        bottom_left: line_center.1,
    };

    [left_wall_polygon, right_wall_polygon]
}

fn compute_wall_polygon_for_room_type_6(
    lines: &Vec<Line>,
    image_width: i32,
    image_height: i32,
) -> WallPolygon {
    let lines_geo = convert_lines_coords_image_geo(&lines, image_height);

    let line_top = lines_geo[0];
    let line_bottom = lines_geo[1];

    let line_params = compute_line_params(line_top);
    let line_top_slope = line_params.slope;
    let line_top_intercept = line_params.intercept;

    let line_params = compute_line_params(line_bottom);
    let line_bottom_slope = line_params.slope;
    let line_bottom_intercept = line_params.intercept;

    // FIXME: we assume borders to be vertical lines placed at image corners
    //   Ideally, we would also compute mean angle to rotate them correspondingly,
    //   if top and bottom lines are parallel or have common slope
    // Left border
    let line_params = compute_line_params(((-1, 0), (0, image_height - 1)));
    let line_left_border_slope = line_params.slope;
    let line_left_border_intercept = line_params.intercept;

    // Right border
    let line_params = compute_line_params(((image_width, 0), (image_width - 1, image_height - 1)));
    let line_right_border_slope = line_params.slope;
    let line_right_border_intercept = line_params.intercept;

    let top_left_intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_top_slope,
        line_top_intercept,
    );
    let top_right_intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_top_slope,
        line_top_intercept,
    );
    let bottom_left_intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_bottom_slope,
        line_bottom_intercept,
    );
    let bottom_right_intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_bottom_slope,
        line_bottom_intercept,
    );

    let line_top = (
        (
            top_left_intersection_point.0 as i32,
            top_left_intersection_point.1 as i32,
        ),
        (
            top_right_intersection_point.0 as i32,
            top_right_intersection_point.1 as i32,
        ),
    );
    let line_top = convert_line_coords_image_geo(line_top, image_height);

    let line_bottom = (
        (
            bottom_left_intersection_point.0 as i32,
            bottom_left_intersection_point.1 as i32,
        ),
        (
            bottom_right_intersection_point.0 as i32,
            bottom_right_intersection_point.1 as i32,
        ),
    );
    let line_bottom = convert_line_coords_image_geo(line_bottom, image_height);

    WallPolygon {
        top_left: line_top.0,
        top_right: line_top.1,
        bottom_right: line_bottom.1,
        bottom_left: line_bottom.0,
    }
}

fn compute_wall_polygons_for_room_type_7(lines: &Vec<Line>, image_height: i32) -> [WallPolygon; 3] {
    let lines_geo = convert_lines_coords_image_geo(&lines, image_height);

    let line_left = lines_geo[0];
    let line_right = lines_geo[1];

    // Left border
    let line_params = compute_line_params(line_left);
    let line_left_slope = line_params.slope;

    let line_left_border_slope = line_left_slope;
    let corner_point = if line_left_border_slope >= 0. {
        (0f32, 511f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_border_intercept =
        compute_line_intercept_at_point(line_left_border_slope, corner_point);

    // Left top line
    // We assume it to be perpendicular to left line with some extra degrees added.
    // Nothing much we can do other than applying our best assumptions.
    // TODO: We selected 30 degrees because it gave most realistic results on parsed predictions
    //   results of LSUN val and train datasets.
    //   As well as after parsing other room types as type 7 and comparing results to actual lines (where these are visible)
    //   Bascially, the same technique as other papers used to generate missing room types form existing rooms.
    // TODO: alternatively, we could also take into account line X position to adjust extra degrees
    //   as they most oftern are sharper the close line is to either border.
    //   However, since we anyways require user to keep floor and ceiling visible, so that
    //   edges could be estimated correctly, we won't perform any more advanced workarounds here
    //   in the current implementation.
    let extra_angle_rads = 30f32.to_radians();
    let line_left_perpendicular_slope = -1.0 / line_left_slope;
    let line_left_top_slope = (line_left_perpendicular_slope.atan() - extra_angle_rads).tan();

    let corner_point = if line_left_top_slope >= 0. {
        (0f32, 511f32)
    } else {
        (line_left.1 .0 as f32, line_left.1 .1 as f32)
    };
    let line_left_top_intercept =
        compute_line_intercept_at_point(line_left_top_slope, corner_point);

    // Left bottom line
    let line_left_bottom_slope = (line_left_perpendicular_slope.atan() + extra_angle_rads).tan();
    let corner_point = if line_left_bottom_slope >= 0. {
        (line_left.0 .0 as f32, line_left.0 .1 as f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_bottom_intercept =
        compute_line_intercept_at_point(line_left_bottom_slope, corner_point);

    // Right border
    let line_params = compute_line_params(line_right);
    let line_right_slope = line_params.slope;

    let line_right_border_slope = line_right_slope;
    let corner_point = if line_right_border_slope >= 0. {
        (511f32, 0f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_border_intercept =
        compute_line_intercept_at_point(line_right_border_slope, corner_point);

    // Right top line
    let line_right_perpendicular_slope = -1.0 / line_right_slope;
    let line_right_top_slope = (line_right_perpendicular_slope.atan() + extra_angle_rads).tan();
    let corner_point = if line_right_top_slope >= 0. {
        (line_right.1 .0 as f32, line_right.1 .1 as f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_top_intercept =
        compute_line_intercept_at_point(line_right_top_slope, corner_point);

    // Right bottom line
    let line_right_bottom_slope = (line_right_perpendicular_slope.atan() - extra_angle_rads).tan();
    let corner_point = if line_right_bottom_slope >= 0. {
        (511f32, 0f32)
    } else {
        (line_right.0 .0 as f32, line_right.0 .1 as f32)
    };
    let line_right_bottom_intercept =
        compute_line_intercept_at_point(line_right_bottom_slope, corner_point);

    // Left polygon
    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_left_top_slope,
        line_left_top_intercept,
    );
    let line_left_top = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_left.1,
    );
    let line_left_top = convert_line_coords_image_geo(line_left_top, image_height);

    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_left_bottom_slope,
        line_left_bottom_intercept,
    );
    let line_left_bottom = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_left.0,
    );
    let line_left_bottom = convert_line_coords_image_geo(line_left_bottom, image_height);

    let left_wall_polygon = WallPolygon {
        top_left: line_left_top.0,
        top_right: line_left_top.1,
        bottom_right: line_left_bottom.1,
        bottom_left: line_left_bottom.0,
    };

    // Right wall polygon
    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_right_top_slope,
        line_right_top_intercept,
    );
    let line_right_top = (
        line_right.1,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );
    let line_right_top = convert_line_coords_image_geo(line_right_top, image_height);

    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_right_bottom_slope,
        line_right_bottom_intercept,
    );
    let line_right_bottom = (
        line_right.0,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );
    let line_right_bottom = convert_line_coords_image_geo(line_right_bottom, image_height);

    let right_wall_polygon = WallPolygon {
        top_left: line_right_top.0,
        top_right: line_right_top.1,
        bottom_right: line_right_bottom.1,
        bottom_left: line_right_bottom.0,
    };

    // Center wall polygon
    let center_wall_polygon = WallPolygon {
        top_left: left_wall_polygon.top_right,
        top_right: right_wall_polygon.top_left,
        bottom_right: right_wall_polygon.bottom_left,
        bottom_left: left_wall_polygon.bottom_right,
    };

    [left_wall_polygon, center_wall_polygon, right_wall_polygon]
}

fn compute_wall_polygon_for_room_type_8(lines: &Vec<Line>, image_height: i32) -> WallPolygon {
    let line_top = convert_line_coords_image_geo(lines[0], image_height);
    let line_params = compute_line_params(line_top);
    let line_top_slope = line_params.slope;
    let line_top_intercept = line_params.intercept;

    let line_bottom_slope = line_top_slope;
    let corner_point = if line_bottom_slope >= 0. {
        (511f32, 0f32)
    } else {
        (0f32, 0f32)
    };
    let line_bottom_intercept = compute_line_intercept_at_point(line_bottom_slope, corner_point);

    // Left and right border lines
    // Assume it is perpendicular to top (and bottom) line
    let line_perpendicular_slope = -1.0 / line_top_slope;

    let line_left_border_slope = line_perpendicular_slope;
    let corner_point = if line_left_border_slope >= 0. {
        (0f32, 511f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_border_intercept =
        compute_line_intercept_at_point(line_left_border_slope, corner_point);

    let line_right_border_slope = line_perpendicular_slope;
    let corner_point = if line_right_border_slope >= 0. {
        (511f32, 0f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_border_intercept =
        compute_line_intercept_at_point(line_right_border_slope, corner_point);

    // Wall polygon points
    let top_left = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_top_slope,
        line_top_intercept,
    );
    let top_right = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_top_slope,
        line_top_intercept,
    );
    let bottom_right = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_bottom_slope,
        line_bottom_intercept,
    );
    let bottom_left = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_bottom_slope,
        line_bottom_intercept,
    );

    let line_top = (
        (top_left.0 as i32, top_left.1 as i32),
        (top_right.0 as i32, top_right.1 as i32),
    );
    let line_top = convert_line_coords_image_geo(line_top, image_height);
    let line_bottom = (
        (bottom_left.0 as i32, bottom_left.1 as i32),
        (bottom_right.0 as i32, bottom_right.1 as i32),
    );
    let line_bottom = convert_line_coords_image_geo(line_bottom, image_height);

    WallPolygon {
        top_left: line_top.0,
        top_right: line_top.1,
        bottom_right: line_bottom.1,
        bottom_left: line_bottom.0,
    }
}

fn compute_wall_polygon_for_room_type_9(lines: &Vec<Line>, image_height: i32) -> WallPolygon {
    let line_bottom = convert_line_coords_image_geo(lines[0], image_height);
    let line_params = compute_line_params(line_bottom);
    let line_bottom_slope = line_params.slope;
    let line_bottom_intercept = line_params.intercept;

    let line_top_slope = line_bottom_slope;
    let corner_point = if line_bottom_slope >= 0. {
        (0f32, 511f32)
    } else {
        (511f32, 511f32)
    };
    let line_top_intercept = compute_line_intercept_at_point(line_top_slope, corner_point);

    // Left and right border lines
    // Assume it is perpendicular to top (and bottom) line
    let line_perpendicular_slope = -1.0 / line_top_slope;

    let line_left_border_slope = line_perpendicular_slope;
    let corner_point = if line_left_border_slope >= 0. {
        (0f32, 511f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_border_intercept =
        compute_line_intercept_at_point(line_left_border_slope, corner_point);

    let line_right_border_slope = line_perpendicular_slope;
    let corner_point = if line_right_border_slope >= 0. {
        (511f32, 0f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_border_intercept =
        compute_line_intercept_at_point(line_right_border_slope, corner_point);

    // Wall polygon points
    let top_left = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_top_slope,
        line_top_intercept,
    );
    let top_right = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_top_slope,
        line_top_intercept,
    );
    let bottom_right = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_bottom_slope,
        line_bottom_intercept,
    );
    let bottom_left = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_bottom_slope,
        line_bottom_intercept,
    );

    let line_top = (
        (top_left.0 as i32, top_left.1 as i32),
        (top_right.0 as i32, top_right.1 as i32),
    );
    let line_top = convert_line_coords_image_geo(line_top, image_height);
    let line_bottom = (
        (bottom_left.0 as i32, bottom_left.1 as i32),
        (bottom_right.0 as i32, bottom_right.1 as i32),
    );
    let line_bottom = convert_line_coords_image_geo(line_bottom, image_height);

    WallPolygon {
        top_left: line_top.0,
        top_right: line_top.1,
        bottom_right: line_bottom.1,
        bottom_left: line_bottom.0,
    }
}

fn compute_wall_polygons_for_room_type_10(
    lines: &Vec<Line>,
    image_height: i32,
) -> [WallPolygon; 2] {
    let line_center = convert_line_coords_image_geo(lines[0], image_height);

    let line_params = compute_line_params(line_center);
    let line_center_slope = line_params.slope;

    // Left border
    let line_left_border_slope = line_center_slope;
    let corner_point = if line_left_border_slope >= 0. {
        (0f32, 511f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_border_intercept =
        compute_line_intercept_at_point(line_left_border_slope, corner_point);

    // TODO: same assumption as for room type 7
    let extra_angle_rads = 30f32.to_radians();
    let line_perpendicular_slope = -1.0 / line_center_slope;

    // Left top
    let line_left_top_slope = (line_perpendicular_slope.atan() - extra_angle_rads).tan();
    let corner_point = if line_left_top_slope >= 0. {
        (0f32, 511f32)
    } else {
        (line_center.0 .0 as f32, line_center.0 .1 as f32)
    };
    let line_left_top_intercept =
        compute_line_intercept_at_point(line_left_top_slope, corner_point);

    // Left bottom
    let line_left_bottom_slope = (line_perpendicular_slope.atan() + extra_angle_rads).tan();
    let corner_point = if line_left_bottom_slope >= 0. {
        (line_center.1 .0 as f32, line_center.1 .1 as f32)
    } else {
        (0f32, 0f32)
    };
    let line_left_bottom_intercept =
        compute_line_intercept_at_point(line_left_bottom_slope, corner_point);

    // Right border
    let line_right_border_slope = line_center_slope;
    let corner_point = if line_right_border_slope >= 0. {
        (511f32, 0f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_border_intercept =
        compute_line_intercept_at_point(line_right_border_slope, corner_point);

    // Right top
    let line_right_top_slope = (line_perpendicular_slope.atan() + extra_angle_rads).tan();
    let corner_point = if line_right_top_slope >= 0. {
        (line_center.0 .0 as f32, line_center.0 .1 as f32)
    } else {
        (511f32, 511f32)
    };
    let line_right_top_intercept =
        compute_line_intercept_at_point(line_right_top_slope, corner_point);

    // Right bottom
    let line_right_bottom_slope = (line_perpendicular_slope.atan() - extra_angle_rads).tan();
    let corner_point = if line_right_bottom_slope >= 0. {
        (511f32, 0f32)
    } else {
        (line_center.1 .0 as f32, line_center.1 .1 as f32)
    };
    let line_right_bottom_intercept =
        compute_line_intercept_at_point(line_right_bottom_slope, corner_point);

    // Left polygon
    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_left_top_slope,
        line_left_top_intercept,
    );
    let line_left_top = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_center.0,
    );
    let line_left_top = convert_line_coords_image_geo(line_left_top, image_height);

    let intersection_point = compute_lines_intersection_point(
        line_left_border_slope,
        line_left_border_intercept,
        line_left_bottom_slope,
        line_left_bottom_intercept,
    );
    let line_left_bottom = (
        (intersection_point.0 as i32, intersection_point.1 as i32),
        line_center.1,
    );
    let line_left_bottom = convert_line_coords_image_geo(line_left_bottom, image_height);

    let left_wall_polygon = WallPolygon {
        top_left: line_left_top.0,
        top_right: line_left_top.1,
        bottom_right: line_left_bottom.1,
        bottom_left: line_left_bottom.0,
    };

    // Right wall polygon
    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_right_top_slope,
        line_right_top_intercept,
    );
    let line_right_top = (
        line_center.0,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );
    let line_right_top = convert_line_coords_image_geo(line_right_top, image_height);

    let intersection_point = compute_lines_intersection_point(
        line_right_border_slope,
        line_right_border_intercept,
        line_right_bottom_slope,
        line_right_bottom_intercept,
    );
    let line_right_bottom = (
        line_center.1,
        (intersection_point.0 as i32, intersection_point.1 as i32),
    );
    let line_right_bottom = convert_line_coords_image_geo(line_right_bottom, image_height);

    let right_wall_polygon = WallPolygon {
        top_left: line_right_top.0,
        top_right: line_right_top.1,
        bottom_right: line_right_bottom.1,
        bottom_left: line_right_bottom.0,
    };

    [left_wall_polygon, right_wall_polygon]
}

#[cfg(test)]
pub(crate) mod tests {
    use crate::polygons::{
        compute_wall_polygon_for_room_type_6, compute_wall_polygon_for_room_type_8,
        compute_wall_polygon_for_room_type_9, compute_wall_polygons,
        compute_wall_polygons_for_room_type_0, compute_wall_polygons_for_room_type_1,
        compute_wall_polygons_for_room_type_10, compute_wall_polygons_for_room_type_2,
        compute_wall_polygons_for_room_type_3, compute_wall_polygons_for_room_type_4,
        compute_wall_polygons_for_room_type_5, compute_wall_polygons_for_room_type_7,
        convert_lines_coords_image_geo,
    };
    use image::{Rgb, RgbImage};
    use imageproc::definitions::HasBlack;
    use imageproc::drawing;
    use lsun_res_parser::Line;
    use ndarray::{Array1, Array2, Axis};
    use ndarray_stats::QuantileExt;
    use serde::{Deserialize, Serialize};
    use std::{
        fs::File,
        io::{BufReader, BufWriter},
        path::PathBuf,
    };

    #[derive(Debug, Clone, Serialize, Deserialize)]
    struct LinesData {
        pub lines: Vec<((i32, i32), (i32, i32))>,
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    struct RoomLayoutData {
        #[serde(rename = "roomType")]
        pub room_type: u8,
        pub edges: Vec<LineData>,
        #[serde(rename = "wallPolygons")]
        pub wall_polygons: Vec<PolygonData>,
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    struct PointData {
        pub x: i32,
        pub y: i32,
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    struct LineData {
        pub start: PointData,
        pub end: PointData,
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    struct PolygonData {
        #[serde(rename = "topLeft")]
        pub top_left: PointData,
        #[serde(rename = "topRight")]
        pub top_right: PointData,
        #[serde(rename = "bottomRight")]
        pub bottom_right: PointData,
        #[serde(rename = "bottomLeft")]
        pub bottom_left: PointData,
    }

    #[test]
    fn prepare_seed_data() {
        let image_height = 512;
        let image_width = 512;

        let results_dir = PathBuf::from("/Users/richardkuodis/development/Bath/res_lsun_tr_gt_npy");

        let indices_file_path = results_dir.join("indices.npy");
        let indices: Array1<i32> = ndarray_npy::read_npy(indices_file_path).unwrap();
        println!("Indices: {indices:?}");

        for i in indices.iter() {
            let lines_file_name = format!("lines_{i}.json");
            let lines_file_path = results_dir.join(lines_file_name);

            println!("Reading {lines_file_path:?}");

            let lines_file = File::open(lines_file_path).unwrap();
            let mut reader = BufReader::new(lines_file);
            let lines_data: LinesData = serde_json::from_reader(&mut reader).unwrap();

            let room_type_file_name = format!("type_{i}.npy");
            let room_type_file_path = results_dir.join(room_type_file_name);
            let room_type: Array2<f32> = ndarray_npy::read_npy(room_type_file_path).unwrap();
            let room_type = room_type.mean_axis(Axis(0)).unwrap();
            let room_type = room_type.argmax().unwrap() as u8;

            let polygons =
                compute_wall_polygons(&lines_data.lines, image_width, image_height, room_type);
            println!("{polygons:?}");

            // TODO: save JSON file compatible with out Swift class

            // FIXME: for debug
            let edges: Vec<LineData> = lines_data
                .lines
                .iter()
                .map(|line| {
                    let start = line.0;
                    let start = PointData {
                        x: start.0,
                        y: start.1,
                    };
                    let end = line.1;
                    let end = PointData { x: end.0, y: end.1 };
                    LineData { start, end }
                })
                .collect();

            let wall_polygons: Vec<PolygonData> = polygons
                .iter()
                .map(|polygon| {
                    let top_left = PointData {
                        x: polygon.top_left.0,
                        y: polygon.top_left.1,
                    };
                    let top_right = PointData {
                        x: polygon.top_right.0,
                        y: polygon.top_right.1,
                    };
                    let bottom_right = PointData {
                        x: polygon.bottom_right.0,
                        y: polygon.bottom_right.1,
                    };
                    let bottom_left = PointData {
                        x: polygon.bottom_left.0,
                        y: polygon.bottom_left.1,
                    };
                    PolygonData {
                        top_left,
                        top_right,
                        bottom_right,
                        bottom_left,
                    }
                })
                .collect();

            let room_layout = RoomLayoutData {
                room_type,
                edges,
                wall_polygons,
            };

            let room_layout_file_name = format!("layout_{i}.json");
            let room_layout_file_path = results_dir.join(room_layout_file_name);
            let room_layout_file = File::create(room_layout_file_path).unwrap();
            let writer = BufWriter::new(room_layout_file);
            serde_json::to_writer(writer, &room_layout).unwrap();

            // let images_dir = PathBuf::from(
            //     "/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img",
            // );
            // let image_path = images_dir.join(format!("{i}.png"));
            // let src_image = image::open(image_path).unwrap().into_rgb8();

            // let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

            // let output_dir = PathBuf::from("./out");
            // let output_image_path = output_dir.join(format!("{i}.png"));
            // overlay_image.save(output_image_path).unwrap();
        }
    }

    #[test]
    fn compute_and_draw_polygons_for_room_type_0() {
        let image_height = 512;
        let i = 40;
        let lines = vec![
            ((116, 100), (72, 0)),
            ((116, 396), (64, 511)),
            ((344, 370), (511, 479)),
            ((342, 133), (496, 0)),
            ((116, 100), (116, 396)),
            ((116, 396), (344, 370)),
            ((344, 370), (342, 133)),
            ((342, 133), (116, 100)),
        ];

        let [left_wall_polygon, center_wall_polygon, right_wall_polygon] =
            compute_wall_polygons_for_room_type_0(&lines, image_height);

        let mut lines = left_wall_polygon.lines().to_vec();
        lines.extend(center_wall_polygon.lines());
        lines.extend(right_wall_polygon.lines());

        let images_dir =
            PathBuf::from("/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img");
        let image_path = images_dir.join(format!("{i}.png"));
        let src_image = image::open(image_path).unwrap().into_rgb8();

        let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{i}.png"));
        overlay_image.save(output_image_path).unwrap();
    }

    #[test]
    fn compute_and_draw_polygons_for_room_type_1() {
        let image_height = 512;
        let i = 135;
        let lines = vec![
            ((153, 365), (154, 0)),
            ((153, 365), (24, 511)),
            ((153, 365), (441, 375)),
            ((441, 375), (446, 1)),
            ((441, 375), (510, 439)),
        ];

        let [left_wall_polygon, center_wall_polygon, right_wall_polygon] =
            compute_wall_polygons_for_room_type_1(&lines, image_height);

        let mut lines = left_wall_polygon.lines().to_vec();
        lines.extend(center_wall_polygon.lines());
        lines.extend(right_wall_polygon.lines());

        let images_dir =
            PathBuf::from("/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img");
        let image_path = images_dir.join(format!("{i}.png"));
        let src_image = image::open(image_path).unwrap().into_rgb8();

        let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{i}.png"));
        overlay_image.save(output_image_path).unwrap();
    }

    #[test]
    fn compute_and_draw_polygons_for_room_type_2() {
        let image_height = 512;
        let i = 396;
        let lines = vec![
            ((101, 35), (86, 1)),
            ((101, 35), (93, 510)),
            ((101, 35), (336, 42)),
            ((336, 42), (365, 1)),
            ((336, 42), (336, 510)),
        ];

        let [left_wall_polygon, center_wall_polygon, right_wall_polygon] =
            compute_wall_polygons_for_room_type_2(&lines, image_height);

        let mut lines = left_wall_polygon.lines().to_vec();
        lines.extend(center_wall_polygon.lines());
        lines.extend(right_wall_polygon.lines());

        let images_dir =
            PathBuf::from("/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img");
        let image_path = images_dir.join(format!("{i}.png"));
        let src_image = image::open(image_path).unwrap().into_rgb8();

        let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{i}.png"));
        overlay_image.save(output_image_path).unwrap();
    }

    #[test]
    fn compute_and_draw_polygons_for_room_type_3() {
        let image_height = 512;
        let i = 555;
        let lines = vec![
            ((31, 110), (0, 97)),
            ((31, 110), (20, 511)),
            ((31, 110), (511, 0)),
        ];

        let [left_wall_polygon, right_wall_polygon] =
            compute_wall_polygons_for_room_type_3(&lines, image_height);

        let mut lines = left_wall_polygon.lines().to_vec();
        lines.extend(right_wall_polygon.lines());

        let images_dir =
            PathBuf::from("/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img");
        let image_path = images_dir.join(format!("{i}.png"));
        let src_image = image::open(image_path).unwrap().into_rgb8();

        let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{i}.png"));
        overlay_image.save(output_image_path).unwrap();
    }

    #[test]
    fn compute_and_draw_polygons_for_room_type_4() {
        let image_height = 512;
        let i = 13;
        let lines = vec![
            ((482, 471), (1, 422)),
            ((482, 471), (504, 1)),
            ((482, 471), (491, 512)),
        ];

        let [left_wall_polygon, right_wall_polygon] =
            compute_wall_polygons_for_room_type_4(&lines, image_height);

        let mut lines = left_wall_polygon.lines().to_vec();
        lines.extend(right_wall_polygon.lines());

        let images_dir =
            PathBuf::from("/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img");
        let image_path = images_dir.join(format!("{i}.png"));
        let src_image = image::open(image_path).unwrap().into_rgb8();

        let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{i}.png"));
        overlay_image.save(output_image_path).unwrap();
    }

    #[test]
    fn compute_and_draw_polygons_for_room_type_5() {
        let image_height = 512;
        let i = 2;
        let lines = vec![
            ((294, 167), (13, 0)),
            ((294, 167), (511, 85)),
            ((294, 167), (306, 343)),
            ((306, 343), (0, 491)),
            ((306, 343), (511, 410)),
        ];

        let [left_wall_polygon, right_wall_polygon] =
            compute_wall_polygons_for_room_type_5(&lines, image_height);

        let mut lines = left_wall_polygon.lines().to_vec();
        lines.extend(right_wall_polygon.lines());

        let images_dir =
            PathBuf::from("/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img");
        let image_path = images_dir.join(format!("{i}.png"));
        let src_image = image::open(image_path).unwrap().into_rgb8();

        let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{i}.png"));
        overlay_image.save(output_image_path).unwrap();
    }

    #[test]
    fn compute_and_draw_polygons_for_room_type_6() {
        let image_height = 512;
        let image_width = 512;
        let i = 188;
        let lines = vec![((142, 0), (511, 75)), ((2, 511), (511, 346))];

        let wall_polygon = compute_wall_polygon_for_room_type_6(&lines, image_width, image_height);

        let lines = wall_polygon.lines().to_vec();

        let images_dir =
            PathBuf::from("/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img");
        let image_path = images_dir.join(format!("{i}.png"));
        let src_image = image::open(image_path).unwrap().into_rgb8();

        let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{i}.png"));
        overlay_image.save(output_image_path).unwrap();
    }

    #[test]
    fn compute_and_draw_polygons_for_room_type_7() {
        let image_height = 512;
        let i = 206;
        let lines = vec![((51, 510), (0, 0)), ((417, 510), (419, 1))];

        let [left_wall_polygon, center_wall_polygon, right_wall_polygon] =
            compute_wall_polygons_for_room_type_7(&lines, image_height);

        let mut lines = left_wall_polygon.lines().to_vec();
        lines.extend(center_wall_polygon.lines());
        lines.extend(right_wall_polygon.lines());

        let images_dir =
            PathBuf::from("/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img");
        let image_path = images_dir.join(format!("{i}.png"));
        let src_image = image::open(image_path).unwrap().into_rgb8();

        let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{i}.png"));
        overlay_image.save(output_image_path).unwrap();
    }

    #[test]
    fn compute_and_draw_polygons_for_room_type_8() {
        let image_height = 512;
        let i = 1583;
        let lines = vec![((0, 127), (511, 95))];

        let lines = compute_wall_polygon_for_room_type_8(&lines, image_height)
            .lines()
            .to_vec();

        let images_dir =
            PathBuf::from("/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img");
        let image_path = images_dir.join(format!("{i}.png"));
        let src_image = image::open(image_path).unwrap().into_rgb8();

        let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{i}.png"));
        overlay_image.save(output_image_path).unwrap();
    }

    #[test]
    fn compute_and_draw_polygons_for_room_type_9() {
        let image_height = 512;
        let i = 11;
        let lines = vec![((0, 311), (511, 305))];

        let lines = compute_wall_polygon_for_room_type_9(&lines, image_height)
            .lines()
            .to_vec();

        let images_dir =
            PathBuf::from("/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img");
        let image_path = images_dir.join(format!("{i}.png"));
        let src_image = image::open(image_path).unwrap().into_rgb8();

        let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{i}.png"));
        overlay_image.save(output_image_path).unwrap();
    }

    #[test]
    fn compute_and_draw_polygons_for_room_type_10() {
        let image_height = 512;
        let i = 279;
        let lines = vec![((292, 0), (312, 511))];

        let [left_wall_polygon, right_wall_polygons] =
            compute_wall_polygons_for_room_type_10(&lines, image_height);
        let mut lines = left_wall_polygon.lines().to_vec();
        lines.extend(right_wall_polygons.lines());

        let images_dir =
            PathBuf::from("/Users/richardkuodis/development/pytorch-layoutnet/res/lsun_tr_gt/img");
        let image_path = images_dir.join(format!("{i}.png"));
        let src_image = image::open(image_path).unwrap().into_rgb8();

        let overlay_image = draw_lines_on_padded_image(&src_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{i}.png"));
        overlay_image.save(output_image_path).unwrap();
    }

    pub(crate) fn draw_lines_on_padded_image(
        src_image: &RgbImage,
        lines: &[Line],
        padding: u32,
    ) -> RgbImage {
        let new_width = src_image.width() + 2 * padding;
        let new_height = src_image.height() + 2 * padding;

        let mut padded_image = RgbImage::from_pixel(new_width, new_height, Rgb::black());

        image::imageops::overlay(&mut padded_image, src_image, padding as i64, padding as i64);

        let padding = padding as f32;
        for line in lines {
            let (p1, p2) = line;

            let x1 = p1.0 as f32 + padding;
            let y1 = p1.1 as f32 + padding;
            let x2 = p2.0 as f32 + padding;
            let y2 = p2.1 as f32 + padding;

            drawing::draw_line_segment_mut(
                &mut padded_image,
                (x1, y1),
                (x2, y2),
                Rgb::from([255, 0, 0]),
            );
        }

        padded_image
    }

    #[test]
    fn converts_line_coordinates_between_image_and_geo_spaces() {
        let lines_image = vec![
            ((294, 167), (13, 0)),
            ((294, 167), (511, 85)),
            ((294, 167), (306, 343)),
            ((306, 343), (0, 491)),
            ((306, 343), (511, 410)),
        ];
        let image_height = 512;

        let lines_geo = convert_lines_coords_image_geo(&lines_image, image_height);
        let expected_lines_geo = vec![
            ((294, 344), (13, 511)),
            ((294, 344), (511, 426)),
            ((294, 344), (306, 168)),
            ((306, 168), (0, 20)),
            ((306, 168), (511, 101)),
        ];
        assert_eq!(lines_geo, expected_lines_geo);

        let lines_image_from_geo = convert_lines_coords_image_geo(&lines_geo, image_height);
        assert_eq!(lines_image_from_geo, lines_image);
    }
}
