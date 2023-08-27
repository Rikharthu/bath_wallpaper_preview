use lsun_res_parser::{Line, Point};
use polyfit_rs::polyfit_rs::polyfit;

pub fn compute_room_layout_polygons(
    // TODO: use Enum
    room_type: u8,
    lines: Vec<Line>,
) {
}

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

struct LineSlopeInterceptForm {
    pub slope: f32,
    pub intercept: f32,
}

fn compute_line_params(line: Line) -> LineSlopeInterceptForm {
    let padding: f32 = if line.0 .0 == line.1 .0 { 0.00001 } else { 0. };

    let line_monomials = polyfit(
        &[line.0 .0 as f32, line.1 .0 as f32 + padding],
        &[line.0 .1 as f32, line.1 .1 as f32 + padding],
        1,
    )
    .unwrap();

    LineSlopeInterceptForm {
        slope: line_monomials[1],
        intercept: line_monomials[0],
    }
}

fn compute_line_intercept_at_point(slope: f32, point: (f32, f32)) -> f32 {
    // y = ax + b => b = y - ax
    point.1 - slope * point.0
}

fn compute_line_y_at_x(slope: f32, intercept: f32, x: f32) -> f32 {
    slope * x + intercept
}

fn compute_line_x_at_y(slope: f32, intercept: f32, y: f32) -> f32 {
    // y = a*x + b => ax = y - b => x = (y - b) / a
    (y - intercept) / slope
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

    let x = (intercept1 - intercept2) / (slope2 - slope1);
    let y = slope1 * x + intercept1; // or y = slope2 * x + intercept2, doesn't matter
    (x, y)
}

#[derive(Clone, Debug)]
pub struct WallPolygon {
    pub top_left: Point,
    pub top_right: Point,
    pub bottom_right: Point,
    pub bottom_left: Point,
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

fn compute_wall_polygons_for_room_type_5(lines: &Vec<Line>, image_height: i32) -> [WallPolygon; 2] {
    let lines_geo = convert_lines_coords_image_geo(&lines, image_height);
    println!("lines_geo: {lines_geo:?}");

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

#[cfg(test)]
mod tests {
    use crate::polygons::{compute_line_intercept_at_point, compute_line_params, compute_line_y_at_x, compute_lines_intersection_point, compute_room_layout_polygons, compute_wall_polygons_for_room_type_5, convert_line_coords_image_geo, convert_lines_coords_image_geo, WallPolygon};
    use image::{Rgb, RgbImage};
    use imageproc::definitions::HasBlack;
    use imageproc::drawing;
    use lsun_res_parser::{Line, RoomLayoutInfo};
    use std::path::PathBuf;

    #[test]
    fn compute_and_draw_polygons() {
        let image_height = 512;
        let i = 2;
        let lines = vec![
            ((294, 167), (13, 0)),
            ((294, 167), (511, 85)),
            ((294, 167), (306, 343)),
            ((306, 343), (0, 491)),
            ((306, 343), (511, 410)),
        ];

        let [left_wall_polygon, right_wall_polygon] = compute_wall_polygons_for_room_type_5(
            &lines,
            image_height
        );

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

    fn draw_lines_on_padded_image(
        src_image: &RgbImage,
        lines: &Vec<Line>,
        padding: u32,
    ) -> RgbImage {
        let new_width = src_image.width() + 2 * padding;
        let new_height = src_image.height() + 2 * padding;

        let mut padded_image = RgbImage::from_pixel(new_width, new_height, Rgb::black());

        image::imageops::overlay(&mut padded_image, src_image, padding as i64, padding as i64);

        let padding = padding as f32;
        for line in lines.iter() {
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
    fn assembles_polygons_from_lines() {
        let parse_result = RoomLayoutInfo {
            room_type: 5,
            lines: vec![
                ((294, 167), (13, 0)),
                ((294, 167), (511, 85)),
                ((294, 167), (306, 343)),
                ((306, 343), (0, 491)),
                ((306, 343), (511, 410)),
            ],
        };

        let result = compute_room_layout_polygons(parse_result.room_type, parse_result.lines);
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
