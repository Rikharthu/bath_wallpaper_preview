#[cfg(test)]
mod tests {
    use image::{DynamicImage, Luma, Pixel, Rgb, Rgba, RgbaImage, RgbImage};
    use imageproc::geometric_transformations::{
        warp, warp_into, warp_into_with, Interpolation, Projection,
    };
    use lsun_res_parser::Point;
    use serde::Deserialize;
    use std::{fs::File, io::BufReader, path::PathBuf};
    use image::imageops::{FilterType, overlay};
    use imageproc::distance_transform::Norm;

    use crate::{
        polygons::{tests::draw_lines_on_padded_image, Polygon},
        LayoutLine, LayoutPoint, RoomLayoutData, WallPolygon,
    };

    #[test]
    fn preview_generation_works() {
        let sample_idx = 2;
        let wallpaper_tile_name = "wallpaper15";

        let fixtures_dir = PathBuf::from("./fixtures");
        let wallpaper_file_path = fixtures_dir.join(format!("{wallpaper_tile_name}.jpg"));

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
                WallPolygon {
                    top_left: LayoutPoint { x: -5, y: -13 },
                    top_right: LayoutPoint { x: 300, y: 165 },
                    bottom_right: LayoutPoint { x: 302, y: 344 },
                    bottom_left: LayoutPoint { x: 0, y: 500 },
                },
                WallPolygon {
                    top_left: LayoutPoint { x: 300, y: 165 },
                    top_right: LayoutPoint { x: 511, y: 85 },
                    bottom_right: LayoutPoint { x: 515, y: 386 },
                    bottom_left: LayoutPoint { x: 302, y: 344 },
                },
                blank_polygon(),
            ],
            num_wall_polygons: 2,
        };

        let polygons: Vec<Polygon> = (0..room_layout_data.num_wall_polygons)
            .map(|i| {
                let wall_polygon = room_layout_data.wall_polygons[i as usize];
                wall_polygon.into()
            })
            .collect();

        println!("Polygons: {polygons:?}");

        // Save layout image
        let mut lines = vec![];
        for poly in polygons.iter() {
            lines.append(&mut poly.lines().to_vec());
        }

        let images_dir = PathBuf::from("/Users/richardkuodis/development/Bath/res_lsun_tr_gt_npy");
        let image_path = images_dir.join(format!("{sample_idx}.png"));
        println!("Reading image: {image_path:?}");
        let room_image = image::open(image_path).unwrap().into_rgb8();
        let room_image_width = room_image.width();
        let room_image_height = room_image.height();

        let overlay_image = draw_lines_on_padded_image(&room_image, &lines, 200);

        let output_dir = PathBuf::from("./out");
        let output_image_path = output_dir.join(format!("{sample_idx}.png"));
        overlay_image.save(output_image_path).unwrap();

        // TODO: warp tile on image
        // TODO: then generate image to be warped from multiple tiles (as in tile_perparation.rs)

        // Load mask image
        let mask_image_path = PathBuf::from("./fixtures/masks/2.jpg");
        let mask_image = image::open(mask_image_path).unwrap();
        let mask_image = image::imageops::resize(
            &mask_image,
            room_image_width,
            room_image_height,
            FilterType::Nearest,
        );
        let mask_image = DynamicImage::from(mask_image).into_luma8();
        let mask_threshold = 50;
        let mask_image = imageproc::contrast::threshold(&mask_image, mask_threshold);
        mask_image.save("./out/2_mask.jpg").unwrap();

        let tile_image_path = PathBuf::from("./fixtures/wallpaper1.jpg");
        let tile_image = image::open(tile_image_path).unwrap();
        let tile_image = tile_image.into_rgba8();
        let tile_width = tile_image.width();
        let tile_height = tile_image.height();
        println!("Tile size: {tile_width}x{tile_height}");

        let transparent = Rgba([0, 0, 0, 0]);
        let mut warped_image = RgbaImage::from_pixel(
            room_image.width(),
            room_image.height(),
            transparent,
        );
        let mut warped_tiles_image = warped_image.clone();
        for (_, polygon) in polygons.iter().enumerate() {
            let from_points = [
                (0f32, 0f32),
                (tile_width as f32, 0f32),
                (tile_width as f32, tile_height as f32),
                (0f32, tile_height as f32),
            ];
            let to_points = [
                (
                    polygon.top_left.0 as f32,
                    polygon.top_left.1 as f32,
                ),
                (
                    polygon.top_right.0 as f32,
                    polygon.top_right.1 as f32,
                ),
                (
                    polygon.bottom_right.0 as f32,
                    polygon.bottom_right.1 as f32,
                ),
                (
                    polygon.bottom_left.0 as f32,
                    polygon.bottom_left.1 as f32,
                ),
            ];
            let projection = Projection::from_control_points(from_points, to_points).unwrap();
            // TODO: use RGBA for now and fill with transparency. We will use transparent pixels
            //   to check whether we need to overlay it on room image
            warp_into(
                &tile_image,
                &projection,
                Interpolation::Bilinear,
                transparent,
                &mut warped_image,
            );

            // let dst_warped_image_path = PathBuf::from(format!("./out/warped_{index}.png"));
            // warped_image.save(dst_warped_image_path).unwrap();

            // TODO: use segmentation mask to guide which pixels must be overlaid

            overlay(
                &mut warped_tiles_image,
                &warped_image,
                0,
                0,
            );
        }

        // TODO: Copy over pixels from `warped_tiles_image` where there is an overlap with mask image
        let mut preview_image = room_image.clone();
        let wall_pixel = Luma([255]);
        for (x, y, pixel) in preview_image.enumerate_pixels_mut() {
            let mask_value = mask_image.get_pixel(x, y);
            let is_wall = mask_value == &wall_pixel;
            if !is_wall {
                continue;
            }

            let warped_tile_pixel = warped_tiles_image.get_pixel(x, y);
            // Non-wall polygon pixels are transparent
            let is_in_polygon_bounds = warped_tile_pixel.0[3] != 0;
            if !is_in_polygon_bounds {
                continue
            }

            *pixel = warped_tile_pixel.to_rgb();
        }

        let dst_preview_image_path = PathBuf::from(format!("./out/preview.jpg"));
        preview_image.save(dst_preview_image_path).unwrap();
    }

    impl From<WallPolygon> for Polygon {
        fn from(wall_polygon: WallPolygon) -> Self {
            Polygon {
                top_left: wall_polygon.top_left.into(),
                top_right: wall_polygon.top_right.into(),
                bottom_right: wall_polygon.bottom_right.into(),
                bottom_left: wall_polygon.bottom_left.into(),
            }
        }
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

    fn blank_polygon() -> WallPolygon {
        WallPolygon {
            top_left: blank_point(),
            top_right: blank_point(),
            bottom_right: blank_point(),
            bottom_left: blank_point(),
        }
    }
}
