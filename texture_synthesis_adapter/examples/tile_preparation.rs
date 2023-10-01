use clap::Parser;
use image::imageops::FilterType;
use image::io::Reader as ImageReader;
use image::{DynamicImage, GenericImage, ImageBuffer, RgbImage, Rgba, RgbaImage};
use imageproc::drawing::draw_filled_rect_mut;
use imageproc::rect::Rect;
use serde::Serialize;
use std::fs;
use std::ops::RangeInclusive;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};
use texture_synthesis as ts;
use texture_synthesis::session::{GeneratorProgress, ProgressUpdate};
use texture_synthesis::Dims;

/// Tile preparation experimentation tool
#[derive(Parser, Debug, Serialize)]
#[command(author, version, about, long_about = None)]
struct Cli {
    /// Path to the example image
    #[arg(long, value_name = "FILE")]
    example: PathBuf,
    /// Path to the output directory
    #[arg(long, value_name = "FILE")]
    output_dir: PathBuf,
    /// Ratio of the tiling mask, expressed as percent of image size
    #[arg(long, value_parser = tiling_mask_ratio_in_range)]
    tiling_mask_ratio: f32,
    /// Number of backtrack stages
    #[arg(long)]
    backtrack_stages: u32,
    /// Number of nearest neighbor pixels to sample
    #[arg(long)]
    nearest_neighbors: u32,
    /// Number of random sample locations
    #[arg(long)]
    random_samples: u64,
    /// Cauchy dispersion
    #[arg(long, value_parser = tiling_mask_ratio_in_range)]
    cauchy_dispersion: f32,
    /// Square size of the input image to be resized before texture synthesis
    #[arg(long)]
    input_resize: u32,
}

const TILING_MASK_RATIO_RANGE: RangeInclusive<f32> = 0.0..=1.0;

fn tiling_mask_ratio_in_range(s: &str) -> Result<f32, String> {
    let ratio: f32 = s.parse().map_err(|_| format!("`{s}` isn't a ratio"))?;
    if TILING_MASK_RATIO_RANGE.contains(&ratio) {
        Ok(ratio as f32)
    } else {
        Err(format!(
            "ratio not in range {}-{}",
            TILING_MASK_RATIO_RANGE.start(),
            TILING_MASK_RATIO_RANGE.end()
        ))
    }
}

struct GeneratorProgressLogger;

impl GeneratorProgress for GeneratorProgressLogger {
    fn update(&mut self, info: ProgressUpdate<'_>) {
        println!("{:?}/{:?}", info.total.current, info.total.total);
    }
}

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

#[derive(Debug, Serialize)]
struct Report {
    pub elapsed_millis: u128,
    pub elapsed: String,
    pub parameters: Parameters,
}

#[derive(Debug, Serialize)]
struct Parameters {
    tiling_mask_ratio: f32,
    backtrack_stages: u32,
    nearest_neighbors: u32,
    random_samples: u64,
    cauchy_dispersion: f32,
    tile_width: u32,
    tile_height: u32,
    input_resize: u32,
}

// TODO: also output tile and assembled tile images with translucent mask overlay to see which areas were generated
fn main() {
    let cli = Cli::parse();

    let image_example = ImageReader::open(&cli.example)
        .expect("Could not read example image")
        .decode()
        .expect("Could not decode image");
    let source = ts::ImageSource::Image(image_example.clone());
    let example = ts::Example::new(source);

    let input_resize_dims = Dims::new(cli.input_resize, cli.input_resize);

    let mask = generate_mask_image(input_resize_dims, cli.tiling_mask_ratio);
    let mask = ts::ImageSource::Image(DynamicImage::from(mask));

    let cpu_count = num_cpus::get();

    // TODO: make it configurable from CLI
    let session = ts::Session::builder()
        .backtrack_stages(cli.backtrack_stages)
        .max_thread_count(cpu_count)
        .tiling_mode(true)
        .inpaint_example(mask, example, input_resize_dims)
        .cauchy_dispersion(cli.cauchy_dispersion)
        .nearest_neighbors(cli.nearest_neighbors)
        .random_sample_locations(cli.random_samples)
        .build()
        .expect("Could not prepare texture synthesis session");

    let logger = Box::new(GeneratorProgressLogger);

    let now = SystemTime::now();
    let generated = session.run(Some(logger));
    let elapsed = now.elapsed().unwrap();

    let result_image = generated.into_image();

    let parameters = Parameters {
        tiling_mask_ratio: cli.tiling_mask_ratio,
        backtrack_stages: cli.backtrack_stages,
        nearest_neighbors: cli.nearest_neighbors,
        random_samples: cli.random_samples,
        cauchy_dispersion: cli.cauchy_dispersion,
        tile_width: input_resize_dims.width,
        tile_height: input_resize_dims.height,
        input_resize: cli.input_resize,
    };
    let report = Report {
        elapsed_millis: elapsed.as_millis(),
        elapsed: format!("{:?}", elapsed),
        parameters,
    };

    // TODO: generate directory name from timestamp
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis();
    let output_dir = cli.output_dir.join(format!("{}", timestamp));
    if !output_dir.exists() {
        fs::create_dir_all(&output_dir).unwrap();
    }
    let tile_image_file = output_dir.join("tile.jpg");
    let example_image_file = output_dir.join("example.jpg");
    let tile_assembled_image_file = output_dir.join("tile_assempled.jpg");
    let example_assembled_image_file = output_dir.join("example_assempled.jpg");
    let report_file = output_dir.join("report.json");

    let tile_times_width = 5;
    let tile_times_height = 3;

    let tiled_image_width = tile_times_width * result_image.width();
    let tiled_image_height = tile_times_height * result_image.width();
    let mut tile_assembled_image = ImageBuffer::new(tiled_image_width, tiled_image_height);
    let mut example_assembled_image = ImageBuffer::new(tiled_image_width, tiled_image_height);
    let image_example = image::imageops::resize(
        &image_example,
        result_image.width(),
        result_image.height(),
        FilterType::Nearest,
    );
    for x in 0..tile_times_width {
        for y in 0..tile_times_height {
            let dst_x = x * result_image.width();
            let dst_y = y * result_image.height();
            println!("[{}, {}] - {} {}", x, y, dst_x, dst_y);
            tile_assembled_image
                .copy_from(&result_image, dst_x, dst_y)
                .unwrap();

            example_assembled_image
                .copy_from(&image_example, dst_x, dst_y)
                .unwrap();
        }
    }

    result_image.save(tile_image_file).unwrap();
    image_example.save(example_image_file).unwrap();
    // TODO: save mask
    tile_assembled_image
        .save(tile_assembled_image_file)
        .unwrap();
    example_assembled_image
        .save(example_assembled_image_file)
        .unwrap();
    serde_json::to_writer_pretty(fs::File::create(report_file).unwrap(), &report).unwrap();
}
