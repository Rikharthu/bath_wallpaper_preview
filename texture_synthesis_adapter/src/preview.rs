use crate::polygons::WallPolygon;
use geo::geometry::Polygon as GeoPolygon;
use geo::{Contains, Coord, LineString};
use image::imageops::{overlay, FilterType};
use image::{DynamicImage, GrayImage, Luma, RgbImage, Rgba, RgbaImage};
use imageproc::geometric_transformations::{warp_into, Interpolation, Projection};
use lsun_res_parser::Point;
use rgb_hsv::{hsv_to_rgb, rgb_to_hsv};

const WALL_WIDTH_METERS: f32 = 3.6;
const WALL_HEIGHT_METERS: f32 = 2.4;
const WALLPAPER_TILE_WIDTH_METERS: f32 = 0.53;
const WALLPAPER_TILE_HEIGHT_METERS: f32 = 0.53;
const VISIBLE_WALLS: f32 = 1.2;
const MIN_ROOM_IMAGE_SIDE: u32 = 2056;
const POLYGON_IMAGE_SCALE: f32 = 512.0;
static VISIBLE_WIDTH_METERS: f32 = WALL_WIDTH_METERS * VISIBLE_WALLS;
static VISIBLE_HORIZONTAL_TILE_COUNT: f32 = VISIBLE_WIDTH_METERS / WALLPAPER_TILE_WIDTH_METERS;
static VISIBLE_VERTICAL_TILES_COUNT: f32 = WALL_HEIGHT_METERS / WALLPAPER_TILE_HEIGHT_METERS;

pub(crate) fn create_preview(
    mut room_image: RgbImage,
    mut mask_image: GrayImage,
    tile_image: RgbImage,
    mut polygons: Vec<WallPolygon>,
) -> RgbImage {
    // Compute width shares using top line since we start applying wallpaper tiles from [0; 0]
    let mut polygon_width_shares: Vec<f32> = vec![];
    let num_polygons = polygons.len();
    let mut visible_horizontal_tile_count = VISIBLE_HORIZONTAL_TILE_COUNT;

    match num_polygons {
        1 => {
            // Assume only one whole wall is visible
            visible_horizontal_tile_count = WALL_WIDTH_METERS / WALLPAPER_TILE_WIDTH_METERS;
            polygon_width_shares.push(1.0);
        }
        2 => {
            let left_polygon = &polygons[0];
            let right_polygon = &polygons[1];

            let left_polygon_top_width =
                pythagorean_distance(left_polygon.top_left, left_polygon.top_right) as f32;
            let right_polygon_top_width =
                pythagorean_distance(right_polygon.top_left, right_polygon.top_right) as f32;

            let left_polygon_share =
                left_polygon_top_width / (left_polygon_top_width + right_polygon_top_width);
            let right_polygon_share = 1.0 - left_polygon_share;

            polygon_width_shares.push(left_polygon_share);
            polygon_width_shares.push(right_polygon_share);
        }
        3 => {
            let side_polygon_width_share = VISIBLE_WALLS - 1.0;

            let left_polygon = &polygons[0];
            let right_polygon = &polygons[2];

            let left_polygon_top_width =
                pythagorean_distance(left_polygon.top_left, left_polygon.top_right) as f32;
            let right_polygon_top_width =
                pythagorean_distance(right_polygon.top_left, right_polygon.top_right) as f32;

            let mut left_polygon_share =
                left_polygon_top_width / (left_polygon_top_width + right_polygon_top_width);
            let mut right_polygon_share = 1.0 - left_polygon_share;

            left_polygon_share *= side_polygon_width_share;
            right_polygon_share *= side_polygon_width_share;

            left_polygon_share /= VISIBLE_WALLS;
            let center_polygon_width_share = 1.0 / VISIBLE_WALLS;
            right_polygon_share /= VISIBLE_WALLS;

            polygon_width_shares.push(left_polygon_share);
            polygon_width_shares.push(center_polygon_width_share);
            polygon_width_shares.push(right_polygon_share);
        }
        _ => panic!("Unexpected wall polygon count: {num_polygons}"),
    }

    let mut room_image_width = room_image.width();
    let mut room_image_height = room_image.height();
    let smallest_room_image_side = u32::min(room_image_width, room_image_height);
    if smallest_room_image_side < MIN_ROOM_IMAGE_SIDE {
        let scale_ratio = MIN_ROOM_IMAGE_SIDE as f32 / smallest_room_image_side as f32;
        room_image_width = (room_image_width as f32 * scale_ratio) as u32;
        room_image_height = (room_image_height as f32 * scale_ratio) as u32;
        room_image = image::imageops::resize(
            &room_image,
            room_image_width,
            room_image_height,
            FilterType::Lanczos3,
        );
    }

    let polygon_width_scale = room_image_width as f32 / POLYGON_IMAGE_SCALE;
    let polygon_height_scale = room_image_height as f32 / POLYGON_IMAGE_SCALE;

    // Rescale polygons to apply to room image size
    for polygon in polygons.iter_mut() {
        polygon.top_left.0 = (polygon.top_left.0 as f32 * polygon_width_scale) as i32;
        polygon.top_left.1 = (polygon.top_left.1 as f32 * polygon_height_scale) as i32;

        polygon.top_right.0 = (polygon.top_right.0 as f32 * polygon_width_scale) as i32;
        polygon.top_right.1 = (polygon.top_right.1 as f32 * polygon_height_scale) as i32;

        polygon.bottom_right.0 = (polygon.bottom_right.0 as f32 * polygon_width_scale) as i32;
        polygon.bottom_right.1 = (polygon.bottom_right.1 as f32 * polygon_height_scale) as i32;

        polygon.bottom_left.0 = (polygon.bottom_left.0 as f32 * polygon_width_scale) as i32;
        polygon.bottom_left.1 = (polygon.bottom_left.1 as f32 * polygon_height_scale) as i32;
    }

    mask_image = image::imageops::resize(
        &mask_image,
        room_image_width,
        room_image_height,
        FilterType::Nearest,
    );
    let mask_threshold = 50;
    mask_image = imageproc::contrast::threshold(&mask_image, mask_threshold);

    let assembled_tile_image = assemble_tiles_image2(
        &tile_image,
        visible_horizontal_tile_count,
        VISIBLE_VERTICAL_TILES_COUNT,
    );
    let assembled_tile_image = DynamicImage::from(assembled_tile_image).into_rgba8();
    let assembled_tile_image_width = assembled_tile_image.width();
    let assembled_tile_image_height = assembled_tile_image.height();

    let mut preview_image = room_image.clone();
    let wall_pixel = Luma([255]);
    let background_mask_pixel = Luma([0]);
    let warp_default_pixel = Rgba([0, 0, 0, 0]);
    let mut warped_individual_wall_tiles_image = RgbaImage::from_pixel(
        preview_image.width(),
        preview_image.height(),
        warp_default_pixel,
    );
    let mut warped_combined_wall_tiles_image = warped_individual_wall_tiles_image.clone();
    let mut wallpaper_section_start_x: f32 = 0.0;
    for (i, (polygon, width_share)) in polygons.iter().zip(polygon_width_shares.iter()).enumerate()
    {
        let wallpaper_section_width = assembled_tile_image_width as f32 * width_share;
        let wallpaper_section_end_x = wallpaper_section_start_x + wallpaper_section_width;

        let from_points = [
            (wallpaper_section_start_x, 0f32),
            (wallpaper_section_end_x, 0f32),
            (wallpaper_section_end_x, assembled_tile_image_height as f32),
            (
                wallpaper_section_start_x,
                assembled_tile_image_height as f32,
            ),
        ];
        let to_points = [
            (polygon.top_left.0 as f32, polygon.top_left.1 as f32),
            (polygon.top_right.0 as f32, polygon.top_right.1 as f32),
            (polygon.bottom_right.0 as f32, polygon.bottom_right.1 as f32),
            (polygon.bottom_left.0 as f32, polygon.bottom_left.1 as f32),
        ];

        let projection = Projection::from_control_points(from_points, to_points).unwrap();
        warp_into(
            &assembled_tile_image,
            &projection,
            Interpolation::Bilinear,
            warp_default_pixel,
            &mut warped_individual_wall_tiles_image,
        );

        let mut current_wall_mask = mask_image.clone();

        // Transfer shadows
        // For that compute HSV values image from room image, compuate average blackness
        // for each individual wall.
        let mut hsv_values_image = GrayImage::new(room_image.width(), room_image.height());
        let mut total_wall_blackness = 0f32;
        let mut values_count = 0usize;

        let geo_polygon = GeoPolygon::new(
            LineString::new(vec![
                Coord::from(polygon.top_left),
                Coord::from(polygon.top_right),
                Coord::from(polygon.bottom_right),
                Coord::from(polygon.bottom_left),
            ]),
            vec![],
        );

        for (x, y, room_pixel) in room_image.enumerate_pixels() {
            let is_in_polygon_bounds = geo_polygon.contains(&Coord::from((x as i32, y as i32)));
            if !is_in_polygon_bounds {
                // Update current wall mask
                *current_wall_mask.get_pixel_mut(x, y) = background_mask_pixel;
                continue;
            }

            let mask_value = mask_image.get_pixel(x, y);
            let is_wall = mask_value == &wall_pixel;
            if !is_wall {
                continue;
            }

            values_count += 1;

            let rgb = (
                room_pixel.0[0] as f32 / 255.0,
                room_pixel.0[1] as f32 / 255.0,
                room_pixel.0[2] as f32 / 255.0,
            );
            let hsv = rgb_to_hsv(rgb);
            let value = hsv.2;

            total_wall_blackness += value;

            let value_pixel = Luma([(value * 255.0) as u8]);
            *hsv_values_image.get_pixel_mut(x, y) = value_pixel;
        }

        let average_wall_blackness = total_wall_blackness / values_count as f32;
        let average_wall_blackness_pixel_value = (average_wall_blackness * 255.0) as i32;
        println!("Average wall {i} blackness: {average_wall_blackness}, pixel: {average_wall_blackness_pixel_value}");

        // Transfer shadows onto warped tiles image
        for (x, y, warped_wall_tile_pixel) in
            warped_individual_wall_tiles_image.enumerate_pixels_mut()
        {
            let is_wall = *current_wall_mask.get_pixel(x, y) == wall_pixel;
            if !is_wall {
                *warped_wall_tile_pixel = warp_default_pixel;
                continue;
            }

            let wall_blackness = hsv_values_image.get_pixel(x, y).0[0] as i32;
            let blackness_delta = wall_blackness - average_wall_blackness_pixel_value;

            let tile_pixel_rgb = (
                warped_wall_tile_pixel.0[0] as f32 / 255.0,
                warped_wall_tile_pixel.0[1] as f32 / 255.0,
                warped_wall_tile_pixel.0[2] as f32 / 255.0,
            );
            let tile_pixel_hsv = rgb_to_hsv(tile_pixel_rgb);
            let tile_pixel_hsv_value = (tile_pixel_hsv.2 * 255.0) as i32;
            let shifted_tile_pixel_hsv_value =
                (tile_pixel_hsv_value + blackness_delta).clamp(0, 255) as f32 / 255.0;
            let shifted_tile_pixel_hsv = (
                tile_pixel_hsv.0,
                tile_pixel_hsv.1,
                shifted_tile_pixel_hsv_value,
            );
            let shifted_tile_pixel_rgb = hsv_to_rgb(shifted_tile_pixel_hsv);
            *warped_wall_tile_pixel = Rgba([
                (shifted_tile_pixel_rgb.0 * 255.0) as u8,
                (shifted_tile_pixel_rgb.1 * 255.0) as u8,
                (shifted_tile_pixel_rgb.2 * 255.0) as u8,
                255,
            ]);

            let preview_pixel = preview_image.get_pixel_mut(x, y);
            preview_pixel.0[0] = warped_wall_tile_pixel.0[0];
            preview_pixel.0[1] = warped_wall_tile_pixel.0[1];
            preview_pixel.0[2] = warped_wall_tile_pixel.0[2];
        }

        overlay(
            &mut warped_combined_wall_tiles_image,
            &warped_individual_wall_tiles_image,
            0,
            0,
        );

        wallpaper_section_start_x = wallpaper_section_end_x;
    }

    preview_image
}

fn pythagorean_distance(from: Point, to: Point) -> i32 {
    let (x1, y1) = from;
    let (x2, y2) = to;
    f32::sqrt(((x2 - x1).pow(2) + (y2 - y1).pow(2)) as f32) as i32
}

fn assemble_tiles_image2(
    tile_image: &RgbImage,
    width_tile_count: f32,
    height_tile_count: f32,
) -> RgbImage {
    let tile_width = tile_image.width();
    let tile_height = tile_image.height();

    let assembled_image_width = (tile_width as f32 * width_tile_count).ceil() as u32;
    let assembled_image_height = (tile_height as f32 * height_tile_count).ceil() as u32;

    let mut assembled_tiles_image = RgbImage::new(assembled_image_width, assembled_image_height);
    for (dst_x, dst_y, dst_pixel) in assembled_tiles_image.enumerate_pixels_mut() {
        let src_tile_x = dst_x % tile_width;
        let src_tile_y = dst_y % tile_height;
        *dst_pixel = *tile_image.get_pixel(src_tile_x, src_tile_y);
    }

    assembled_tiles_image
}

#[cfg(test)]
mod tests {
    use geo::geometry::LineString;
    use geo::geometry::Polygon as GeoPolygon;
    use geo::{Contains, Coord};
    use image::imageops::{overlay, FilterType};
    use image::{DynamicImage, GrayImage, Luma, RgbImage, Rgba, RgbaImage};
    use imageproc::geometric_transformations::{warp_into, Interpolation, Projection};
    use lsun_res_parser::Point;
    use rgb_hsv::{hsv_to_rgb, rgb_to_hsv};
    use std::path::PathBuf;

    use crate::ffi::{LayoutLine, LayoutPoint, LayoutWallPolygon, RoomLayoutData};
    use crate::polygons::{tests::draw_lines_on_padded_image, WallPolygon};
    use crate::preview::{
        create_preview, VISIBLE_HORIZONTAL_TILE_COUNT, VISIBLE_VERTICAL_TILES_COUNT, VISIBLE_WALLS,
        WALLPAPER_TILE_WIDTH_METERS, WALL_WIDTH_METERS,
    };

    #[test]
    fn preview_generation_works() {
        let sample_idx = 2;

        // Image 2.jpg
        // TODO: resize polygons to match input image size
        let room_layout_data = RoomLayoutData {
            lines: [
                LayoutLine {
                    start: LayoutPoint { x: 300, y: 165 },
                    end: LayoutPoint { x: 18, y: 0 },
                },
                LayoutLine {
                    start: LayoutPoint { x: 300, y: 165 },
                    end: LayoutPoint { x: 511, y: 85 },
                },
                LayoutLine {
                    start: LayoutPoint { x: 300, y: 165 },
                    end: LayoutPoint { x: 302, y: 344 },
                },
                LayoutLine {
                    start: LayoutPoint { x: 302, y: 344 },
                    end: LayoutPoint { x: 0, y: 499 },
                },
                LayoutLine {
                    start: LayoutPoint { x: 302, y: 344 },
                    end: LayoutPoint { x: 511, y: 385 },
                },
                blank_line(),
                blank_line(),
                blank_line(),
            ],
            num_lines: 5,
            room_type: 5,
            wall_polygons: [
                LayoutWallPolygon {
                    top_left: LayoutPoint { x: -5, y: -13 },
                    top_right: LayoutPoint { x: 300, y: 165 },
                    bottom_right: LayoutPoint { x: 302, y: 344 },
                    bottom_left: LayoutPoint { x: 0, y: 500 },
                },
                LayoutWallPolygon {
                    top_left: LayoutPoint { x: 300, y: 165 },
                    top_right: LayoutPoint { x: 511, y: 85 },
                    bottom_right: LayoutPoint { x: 515, y: 386 },
                    bottom_left: LayoutPoint { x: 302, y: 344 },
                },
                blank_polygon(),
            ],
            num_wall_polygons: 2,
        };

        let mut polygons: Vec<WallPolygon> = (0..room_layout_data.num_wall_polygons)
            .map(|i| {
                let wall_polygon = room_layout_data.wall_polygons[i as usize];
                wall_polygon.into()
            })
            .collect();

        let images_dir = PathBuf::from("/Users/richardkuodis/development/Bath/res_lsun_tr_gt_npy");
        let image_path = images_dir.join(format!("{sample_idx}.png"));
        println!("Reading image: {image_path:?}");
        let mut room_image = image::open(image_path).unwrap().into_rgb8();

        let mask_image_path = PathBuf::from("./fixtures/masks/2.jpg");
        let mask_image = image::open(mask_image_path).unwrap().into_luma8();
        let tile_image_path = PathBuf::from("./fixtures/wallpaper1.jpg");
        let tile_image = image::open(tile_image_path).unwrap().into_rgb8();

        let preview_image = create_preview(room_image, mask_image, tile_image, polygons);

        preview_image.save("./out/preview.jpg").unwrap();
    }

    impl From<LayoutPoint> for Point {
        fn from(layout_point: LayoutPoint) -> Self {
            (layout_point.x, layout_point.y)
        }
    }

    fn blank_line() -> LayoutLine {
        LayoutLine {
            start: blank_point(),
            end: blank_point(),
        }
    }

    fn blank_point() -> LayoutPoint {
        LayoutPoint { x: 0, y: 0 }
    }

    fn blank_polygon() -> LayoutWallPolygon {
        LayoutWallPolygon {
            top_left: blank_point(),
            top_right: blank_point(),
            bottom_right: blank_point(),
            bottom_left: blank_point(),
        }
    }

    fn pythagorean_distance(from: Point, to: Point) -> i32 {
        let (x1, y1) = from;
        let (x2, y2) = to;
        f32::sqrt(((x2 - x1).pow(2) + (y2 - y1).pow(2)) as f32) as i32
    }

    fn assemble_tiles_image2(
        tile_image: &RgbImage,
        width_tile_count: f32,
        height_tile_count: f32,
    ) -> RgbImage {
        let tile_width = tile_image.width();
        let tile_height = tile_image.height();

        let assembled_image_width = (tile_width as f32 * width_tile_count).ceil() as u32;
        let assembled_image_height = (tile_height as f32 * height_tile_count).ceil() as u32;

        let mut assembled_tiles_image =
            RgbImage::new(assembled_image_width, assembled_image_height);
        for (dst_x, dst_y, dst_pixel) in assembled_tiles_image.enumerate_pixels_mut() {
            let src_tile_x = dst_x % tile_width;
            let src_tile_y = dst_y % tile_height;
            *dst_pixel = *tile_image.get_pixel(src_tile_x, src_tile_y);
        }

        assembled_tiles_image
    }

    #[test]
    fn transferring_shadows() {
        // TODO: https://blog.griddynamics.com/using-augmented-reality-in-interior-property-design-how-did-we-live-without-it/
        let sample_idx = 2;
        let images_dir = PathBuf::from("/Users/richardkuodis/development/Bath/res_lsun_tr_gt_npy");
        let image_path = images_dir.join(format!("{sample_idx}.png"));
        let room_image = image::open(image_path).unwrap();

        let room_image_rgb = room_image.as_rgb8().unwrap();
        let mut hsv_values_image = GrayImage::new(room_image.width(), room_image.height());
        // let mut hsv_values: Array2<f32> = Array2::zeros((room_image.height() as usize, room_image.width() as usize));
        for (x, y, pixel) in room_image_rgb.enumerate_pixels() {
            let rgb = (
                pixel.0[0] as f32 / 255.0,
                pixel.0[1] as f32 / 255.0,
                pixel.0[2] as f32 / 255.0,
            );
            let hsv = rgb_to_hsv(rgb);
            let value = hsv.2;
            let value_pixel = Luma([(value * 255.0) as u8]);
            *hsv_values_image.get_pixel_mut(x, y) = value_pixel;
        }

        hsv_values_image.save("./out/hsv_values.jpg").unwrap();
    }
}
