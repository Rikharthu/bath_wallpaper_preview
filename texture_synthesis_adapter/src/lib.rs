mod polygons;

use image::{DynamicImage, GenericImageView, Pixel, Rgba, RgbaImage};
use imageproc::drawing;
use lsun_res_parser::parse_lsun_results;
use ndarray::{Array2, Array3, Axis, ShapeBuilder};
use ndarray_stats::QuantileExt;
use std::os::raw::c_int;
use std::{default, mem, ptr, slice};
use texture_synthesis as ts;
use texture_synthesis::session::{GeneratorProgress, ProgressUpdate};
use texture_synthesis::Dims;

use crate::polygons::compute_wall_polygons;

#[repr(C)]
pub struct RgbaImageInfo {
    pub data: *const u8,
    pub count: usize,
    pub width: usize,
    pub height: usize,
}

#[repr(C)]
pub struct SegmentationMap {
    pub data: *const f32,
    pub height: usize,
    pub width: usize,
    pub strides: [usize; 2],
}

#[repr(C)]
#[derive(Debug)]
pub struct MLMultiArray2DInfo {
    pub data: *const f32,
    pub shape: [usize; 2],
    pub strides: [usize; 2],
}

#[repr(C)]
pub struct RoomLayoutData {
    /// Identified room layout lines
    pub lines: [LayoutLine; 8],
    /// Indicates how many actual lines are stored in [lines] (at most 8)
    pub num_lines: u8,
    /// LSUN room type
    pub room_type: u8,
    /// Reconstructed wall polygons based on room type
    pub wall_polygons: [WallPolygon; 3],
    /// Indicates how many actual wall polygons are stored in [polygons] (at most 3)
    pub num_wall_polygons: u8,
}

#[repr(C)]
#[derive(Default)]
pub struct LayoutPoint {
    pub x: i32,
    pub y: i32,
}

#[repr(C)]
#[derive(Default)]
pub struct LayoutLine {
    pub start: LayoutPoint,
    pub end: LayoutPoint,
}

#[repr(C)]
#[derive(Default)]
pub struct WallPolygon {
    pub top_left: LayoutPoint,
    pub top_right: LayoutPoint,
    pub bottom_right: LayoutPoint,
    pub bottom_left: LayoutPoint,
}

impl MLMultiArray2DInfo {
    pub fn array(&self) -> Array2<f32> {
        let shape = (self.shape[0], self.shape[1]).strides((self.strides[0], self.strides[1]));
        let data =
            unsafe { slice::from_raw_parts(self.data, self.shape[0] * self.shape[1]) }.to_vec();
        Array2::from_shape_vec(shape, data).unwrap()
    }
}

#[repr(C)]
pub struct MLMultiArray3DInfo {
    pub data: *const f32,
    pub shape: [usize; 3],
    pub strides: [usize; 3],
}

impl MLMultiArray3DInfo {
    pub fn array(&self) -> Array3<f32> {
        let shape = (self.shape[0], self.shape[1], self.shape[2]).strides((
            self.strides[0],
            self.strides[1],
            self.strides[2],
        ));
        let data = unsafe {
            slice::from_raw_parts(self.data, self.shape[0] * self.shape[1] * self.shape[2])
        }
        .to_vec();
        Array3::from_shape_vec(shape, data).unwrap()
    }
}

#[repr(C)]
pub struct RoomLayoutEstimationResults {
    pub edges: MLMultiArray3DInfo,
    pub corners: MLMultiArray3DInfo,
    pub corners_flip: MLMultiArray3DInfo,
    pub type_: MLMultiArray2DInfo,
}

// TODO: add a method to generate tileable results
//   See "API - 07_tiling_texture" of https://crates.io/crates/texture-synthesis
// TODO: return RgbaImageInfo as well or specify it as dst
#[no_mangle]
pub extern "C" fn synthesize_texture(sample_info: *const RgbaImageInfo) -> *const u8 {
    let sample_info = unsafe { ptr::read(sample_info) };

    let data_slice = unsafe { slice::from_raw_parts(sample_info.data, sample_info.count) };
    let buffer = data_slice.to_vec();
    let sample_image =
        RgbaImage::from_raw(sample_info.width as u32, sample_info.height as u32, buffer).unwrap();

    println!(
        "Input image size: {}x{}",
        sample_image.width(),
        sample_image.height()
    );
    let dynamic_sample_image = DynamicImage::ImageRgba8(sample_image);
    let source = ts::ImageSource::Image(dynamic_sample_image);
    let example = ts::Example::new(source);

    println!("Building synthesis session");
    // By default texture synthesis uses all CPUs, but we still specify it explicitly
    let cpu_count = num_cpus::get();
    println!("Number of CPUs available: {}", cpu_count);
    let textsynth = ts::Session::builder()
        .add_example(example)
        .max_thread_count(cpu_count)
        .resize_input(Dims::square(64))
        .output_size(Dims::square(256))
        .build()
        .expect("Could not build texture synthesis session");
    println!("Synthesizing...");

    let logger = Box::new(GeneratorProgressLogger);
    let generated = textsynth.run(Some(logger));
    println!("Synthesis finished");
    let result_image = generated.into_image();
    println!("{}x{}", result_image.width(), result_image.height());

    let result_image_rgba = result_image.as_rgba8().unwrap();
    let raw = result_image_rgba.as_raw().clone();
    println!("Raw buffer length: {}", raw.len());
    let ptr = raw.as_ptr();
    mem::forget(raw);
    ptr
}

struct GeneratorProgressLogger;

impl GeneratorProgress for GeneratorProgressLogger {
    fn update(&mut self, info: ProgressUpdate<'_>) {
        println!("{:?}/{:?}", info.total.current, info.total.total);
    }
}

#[no_mangle]
pub extern "C" fn rust_process_data(image_info: *const RgbaImageInfo) -> *const u8 {
    let image_info = unsafe { ptr::read(image_info) };

    let data_slice = unsafe { slice::from_raw_parts(image_info.data, image_info.count) };
    let buffer = data_slice.to_vec();
    let mut image =
        RgbaImage::from_raw(image_info.width as u32, image_info.height as u32, buffer).unwrap();

    for y in 40..120 {
        for x in 0..512 {
            image.put_pixel(x, y, Rgba([255, 2, 2, 255]));
        }
    }

    let raw = image.as_raw().clone();
    let ptr = raw.as_ptr();
    mem::forget(raw);
    ptr

    // TODO: somehow display this image back to ensure that representation is correct

    // let mut data_vec = data_slice.to_vec();
    // // PngDecoder::new(data_vec.as_slice());
    // let decoder = PngDecoder::new(data_slice).unwrap();
    // println!("Decoder total bytes: {}", decoder.total_bytes());
    //
    // let mut image_buffer: Vec<u8> = vec![0; decoder.total_bytes() as usize];
    // decoder.read_image(image_buffer.as_bytes_mut()).unwrap();
    //
    // let image = RgbImage::from_raw(
    //     3024,
    //     4032,
    //     image_buffer,
    // ).unwrap();

    // TODO: compare pixels or pass back to Swift to ensure that the image is correct

    // let image2 = RgbImage::from_raw(
    //     3024,
    //     4032,
    //     data_vec,
    // ).unwrap();
}

#[no_mangle]
pub extern "C" fn process_segmentation_map(segmentation_map: *const SegmentationMap) {
    let segmentation_map_ref = unsafe { &*segmentation_map };
    println!(
        "Processing segmentation map {}x{}, strides: {:?}",
        segmentation_map_ref.width, segmentation_map_ref.height, segmentation_map_ref.strides
    );
    let data = unsafe {
        slice::from_raw_parts(
            segmentation_map_ref.data,
            segmentation_map_ref.width * segmentation_map_ref.height,
        )
    }
    .to_vec();
    let shape = (segmentation_map_ref.height, segmentation_map_ref.width).strides((
        segmentation_map_ref.strides[0],
        segmentation_map_ref.strides[1],
    ));
    let array = Array2::from_shape_vec(shape, data).unwrap();
    println!("Array: {array:?}");
}

#[no_mangle]
pub extern "C" fn shipping_rust_addition(a: c_int, b: c_int) -> c_int {
    a + b
}

#[no_mangle]
pub extern "C" fn process_room_layout_estimation_results(
    results: *const RoomLayoutEstimationResults
) -> RoomLayoutData {
    let results_ref = unsafe { &*results };

    println!("Processing room layout estimation results");
    println!("Type array info: {:?}", results_ref.type_);
    let type_array = results_ref.type_.array();
    println!("Type array: {type_array:?}");

    let room_type = type_array.mean_axis(Axis(0)).unwrap().argmax().unwrap() as usize;
    println!("Room type: {room_type}");

    let edges_array = results_ref.edges.array();
    println!("Edges array shape: {:?}", edges_array.shape());

    let corners_array = results_ref.corners.array();
    println!("Corners array shape: {:?}", corners_array.shape());

    let corners_flip_array = results_ref.corners_flip.array();
    println!("Flipped array shape: {:?}", corners_flip_array.shape());

    let parse_result =
        parse_lsun_results(edges_array, corners_array, corners_flip_array, type_array).unwrap();
    println!("Parse result: {parse_result:?}");

    // TODO: extract polygons from parse_result

    let polygons = compute_wall_polygons(
        &parse_result.lines,
        // TODO: provide from function args
        512,
        // TODO: provide from function args
        512,
        parse_result.room_type,
    );

    let mut wall_polygons: [WallPolygon; 3] = Default::default();
    for (idx, polygon) in polygons.iter().enumerate() {
        // TODO: could use `From` impl
        let top_left = LayoutPoint {
            x: polygon.top_left.0,
            y: polygon.top_left.1,
        };
        let top_right = LayoutPoint {
            x: polygon.top_right.0,
            y: polygon.top_right.1,
        };
        let bottom_right = LayoutPoint {
            x: polygon.bottom_right.0,
            y: polygon.bottom_right.1,
        };
        let bottom_left = LayoutPoint {
            x: polygon.bottom_left.0,
            y: polygon.bottom_left.1,
        };
        wall_polygons[idx] = WallPolygon {
            top_left,
            top_right,
            bottom_right,
            bottom_left,
        };
    }
    let num_wall_polygons = polygons.len() as u8;

    let mut lines: [LayoutLine; 8] = Default::default();
    for (idx, (start, end)) in parse_result.lines.iter().enumerate() {
        let line = LayoutLine {
            start: LayoutPoint {
                x: start.0,
                y: start.1,
            },
            end: LayoutPoint { x: end.0, y: end.1 },
        };
        lines[idx] = line;
    }
    let num_lines = parse_result.lines.len() as u8;

    RoomLayoutData {
        lines,
        num_lines,
        room_type: parse_result.room_type,
        wall_polygons,
        num_wall_polygons,
    }
}

#[cfg(test)]
mod tests {
    use image::io::Reader as ImageReader;
    use image::{GenericImageView, ImageBuffer, RgbImage};
    use ndarray::{array, Array2};

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
        let image2 = RgbImage::from_raw(image.width(), image.height(), image.to_bytes()).unwrap();
        image2.save("./assets/image2.jpg").unwrap();
    }
}
