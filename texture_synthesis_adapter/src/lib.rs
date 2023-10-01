mod ffi;
pub mod polygons;
pub mod preview;

use image::{DynamicImage, RgbImage, Rgba, RgbaImage};
use imageproc::drawing::draw_filled_rect_mut;
use imageproc::rect::Rect;
use ndarray::ShapeBuilder;
use ndarray_stats::QuantileExt;
use texture_synthesis as ts;
use texture_synthesis::session::{GeneratorProgress, ProgressUpdate};
use texture_synthesis::Dims;

fn generate_mask_image(size: Dims, ratio: f32) -> RgbImage {
    assert!((0f32..=1f32).contains(&ratio));

    let mut image: RgbaImage = RgbaImage::from_pixel(
        size.width,
        size.width,
        Rgba::from([255u8, 255u8, 255u8, 255u8]),
    );

    let width = image.width();
    let height = image.height();

    // TODO: use width for left and right, and height for top and bottom
    let rect_side = (width as f32 / 2.0 * ratio) as u32;
    let black = Rgba::from([0u8, 0u8, 0u8, 255u8]);
    // Top
    draw_filled_rect_mut(&mut image, Rect::at(0, 0).of_size(width, rect_side), black);
    // Right
    draw_filled_rect_mut(
        &mut image,
        Rect::at((width - rect_side) as i32, 0).of_size(rect_side, height),
        black,
    );
    // Bottom
    draw_filled_rect_mut(
        &mut image,
        Rect::at(0, (height - rect_side) as i32).of_size(width, rect_side),
        black,
    );
    // Left
    draw_filled_rect_mut(&mut image, Rect::at(0, 0).of_size(rect_side, height), black);

    DynamicImage::ImageRgba8(image).to_rgb8()
}

struct GeneratorProgressLogger;

impl GeneratorProgress for GeneratorProgressLogger {
    fn update(&mut self, info: ProgressUpdate<'_>) {
        println!("{:?}/{:?}", info.total.current, info.total.total);
    }
}

#[cfg(test)]
mod tests {
    use image::io::Reader as ImageReader;
    use image::RgbImage;

    #[test]
    fn test_image() {
        let image = ImageReader::open("./assets/lenna.png")
            .unwrap()
            .decode()
            .unwrap();

        println!("Image size: {}x{}", image.width(), image.height());
        println!("Color type: {:?}", image.color());
        let num_bytes = image.as_bytes().len();
        println!("Image has {} bytes", num_bytes);

        // Reconstruct image from bytes
        // let mut image2 = RgbImage::new(image.width(), image.height());
        let image2 = RgbImage::from_raw(image.width(), image.height(), image.into_bytes()).unwrap();
        image2.save("./assets/image2.jpg").unwrap();
    }
}
