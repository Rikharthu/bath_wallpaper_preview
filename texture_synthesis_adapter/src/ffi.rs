// TODO: move whatever we export to Objective-C here.

use crate::polygons::{compute_wall_polygons, WallPolygon};
use crate::{polygons, GeneratorProgressLogger};
use image::{DynamicImage, GrayImage, RgbImage, Rgba, RgbaImage};
use lsun_res_parser::{parse_lsun_results, Point, RoomLayoutInfo};
use ndarray::{Array2, Array3, Axis, ShapeBuilder};
use ndarray_stats::QuantileExt;
use std::os::raw::c_int;
use std::{mem, ptr, slice};
use texture_synthesis as ts;
use texture_synthesis::session::{GeneratorProgress, ProgressUpdate};
use texture_synthesis::Dims;
use crate::preview::create_preview;

#[repr(C)]
pub struct ImageInfo {
    pub data: *const u8,
    pub count: usize,
    pub width: usize,
    pub height: usize,
}

impl From<RgbaImage> for ImageInfo {
    fn from(image: RgbaImage) -> Self {
        let width = image.width() as usize;
        let height = image.height() as usize;
        let buffer = image.into_raw();
        let buffer = buffer.into_boxed_slice();
        let count = buffer.len();
        let data = Box::into_raw(buffer) as *const u8;
        Self {
            data,
            count,
            width,
            height,
        }
    }
}

impl ImageInfo {
    pub fn rgba_image(&self) -> RgbaImage {
        let data_slice = unsafe { slice::from_raw_parts(self.data, self.count) };
        let buffer = data_slice.to_vec();
        RgbaImage::from_raw(self.width as u32, self.height as u32, buffer).unwrap()
    }

    pub fn gray_image(&self) -> GrayImage {
        let data_slice = unsafe { slice::from_raw_parts(self.data, self.count) };
        let buffer = data_slice.to_vec();
        GrayImage::from_raw(self.width as u32, self.height as u32, buffer).unwrap()
    }
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
#[derive(Debug)]
pub struct RoomLayoutData {
    /// Identified room layout lines
    pub lines: [LayoutLine; 8],
    /// Indicates how many actual lines are stored in [lines] (at most 8)
    pub num_lines: u8,
    /// LSUN room type
    pub room_type: u8,
    /// Reconstructed wall polygons based on room type
    pub wall_polygons: [LayoutWallPolygon; 3],
    /// Indicates how many actual wall polygons are stored in [polygons] (at most 3)
    pub num_wall_polygons: u8,
}

#[repr(C)]
#[derive(Debug, Default, Copy, Clone)]
pub struct LayoutPoint {
    pub x: i32,
    pub y: i32,
}

impl LayoutPoint {
    pub fn to_point(&self) -> Point {
        (self.x, self.y)
    }
}

#[repr(C)]
#[derive(Debug, Default, Copy, Clone)]
pub struct LayoutLine {
    pub start: LayoutPoint,
    pub end: LayoutPoint,
}

#[repr(C)]
#[derive(Debug, Default, Copy, Clone)]
pub struct LayoutWallPolygon {
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

#[no_mangle]
pub extern "C" fn release_image_buffer(buffer_ptr: *const u8, length: usize) {
    unsafe {
        let slice_ptr = std::ptr::slice_from_raw_parts(buffer_ptr, length) as *mut u8;
        let _ = Box::from_raw(slice_ptr);
    }
}

#[no_mangle]
pub unsafe extern "C" fn generate_preview(
    // TODO: no need to pass ImageInfo as pointer
    room_image: *const ImageInfo,
    wall_mask_image: *const ImageInfo,
    wallpaper_tile_image: *const ImageInfo,
    room_layout: RoomLayoutData,
) -> ImageInfo {
    let room_image = ptr::read(room_image).rgba_image();
    let wall_mask_image = ptr::read(wall_mask_image).gray_image();
    let wallpaper_tile_image = ptr::read(wallpaper_tile_image).rgba_image();

    let mut polygons: Vec<WallPolygon> = vec![];
    for i in 0..room_layout.num_wall_polygons {
        let polygon: WallPolygon = room_layout.wall_polygons[i as usize].into();
        polygons.push(polygon);
    }

    let room_image = DynamicImage::from(room_image).into_rgb8();
    let wallpaper_tile_image = DynamicImage::from(wallpaper_tile_image).into_rgb8();

    let preview_image = create_preview(
        room_image,
        wall_mask_image,
        wallpaper_tile_image,
        polygons
    );
    let preview_image = DynamicImage::from(preview_image).into_rgba8();

    ImageInfo::from(preview_image)
}

// TODO: add a method to generate tileable results
//   See "API - 07_tiling_texture" of https://crates.io/crates/texture-synthesis
// TODO: return RgbaImageInfo as well or specify it as dst
#[no_mangle]
pub extern "C" fn synthesize_texture(
    sample_info: *const ImageInfo,
    input_resize: u32,
) -> *const u8 {
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

    let input_resize_dims = Dims::square(input_resize);

    // Prepare inpaint mask so that only border pixels will be synthesized
    let mask = crate::generate_mask_image(input_resize_dims, 0.16);
    let mask = ts::ImageSource::Image(DynamicImage::from(mask));

    let textsynth = ts::Session::builder()
        .backtrack_stages(20)
        .max_thread_count(cpu_count)
        .tiling_mode(true)
        .inpaint_example(mask, example, input_resize_dims)
        .cauchy_dispersion(1.0)
        .nearest_neighbors(50)
        .random_sample_locations(50)
        .build()
        .expect("Could not prepare texture synthesis session");

    println!("Synthesizing...");

    let logger = Box::new(GeneratorProgressLogger);
    let generated = textsynth.run(Some(logger));
    println!("Synthesis finished");
    let result_image = generated.into_image();
    println!("{}x{}", result_image.width(), result_image.height());

    let result_image_rgba = result_image.as_rgba8().unwrap();
    let buffer_vec = result_image_rgba.as_raw().clone();
    let buffer_slice = buffer_vec.into_boxed_slice();
    let buffer_len = buffer_slice.len();
    println!("Buffer length: {buffer_len}");
    Box::into_raw(buffer_slice) as *const u8
}

#[no_mangle]
pub extern "C" fn rust_process_data(image_info: *const ImageInfo) -> *const u8 {
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

/// # Safety `results` must not be `null`
#[no_mangle]
pub unsafe extern "C" fn process_room_layout_estimation_results(
    results: *const RoomLayoutEstimationResults,
) -> RoomLayoutData {
    let results_ref = unsafe { &*results };

    println!("Processing room layout estimation results");
    println!("Type array info: {:?}", results_ref.type_);
    let type_array = results_ref.type_.array();
    println!("Type array: {type_array:?}");

    let room_type: usize = type_array.mean_axis(Axis(0)).unwrap().argmax().unwrap();
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

    let mut wall_polygons: [LayoutWallPolygon; 3] = Default::default();
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
        wall_polygons[idx] = LayoutWallPolygon {
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
