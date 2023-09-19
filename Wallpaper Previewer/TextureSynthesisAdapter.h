#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct RgbaImageInfo {
  const uint8_t *data;
  uintptr_t count;
  uintptr_t width;
  uintptr_t height;
} RgbaImageInfo;

typedef struct SegmentationMap {
  const float *data;
  uintptr_t height;
  uintptr_t width;
  uintptr_t strides[2];
} SegmentationMap;

typedef struct LayoutPoint {
  int32_t x;
  int32_t y;
} LayoutPoint;

typedef struct LayoutLine {
  struct LayoutPoint start;
  struct LayoutPoint end;
} LayoutLine;

typedef struct WallPolygon {
  struct LayoutPoint top_left;
  struct LayoutPoint top_right;
  struct LayoutPoint bottom_right;
  struct LayoutPoint bottom_left;
} WallPolygon;

typedef struct RoomLayoutData {
  /**
   * Identified room layout lines
   */
  struct LayoutLine lines[8];
  /**
   * Indicates how many actual lines are stored in [lines] (at most 8)
   */
  uint8_t num_lines;
  /**
   * LSUN room type
   */
  uint8_t room_type;
  /**
   * Reconstructed wall polygons based on room type
   */
  struct WallPolygon wall_polygons[3];
  /**
   * Indicates how many actual wall polygons are stored in [polygons] (at most 3)
   */
  uint8_t num_wall_polygons;
} RoomLayoutData;

typedef struct MLMultiArray3DInfo {
  const float *data;
  uintptr_t shape[3];
  uintptr_t strides[3];
} MLMultiArray3DInfo;

typedef struct MLMultiArray2DInfo {
  const float *data;
  uintptr_t shape[2];
  uintptr_t strides[2];
} MLMultiArray2DInfo;

typedef struct RoomLayoutEstimationResults {
  struct MLMultiArray3DInfo edges;
  struct MLMultiArray3DInfo corners;
  struct MLMultiArray3DInfo corners_flip;
  struct MLMultiArray2DInfo type_;
} RoomLayoutEstimationResults;

const uint8_t *synthesize_texture(const struct RgbaImageInfo *sample_info);

const uint8_t *rust_process_data(const struct RgbaImageInfo *image_info);

void process_segmentation_map(const struct SegmentationMap *segmentation_map);

int shipping_rust_addition(int a, int b);

struct RoomLayoutData process_room_layout_estimation_results(const struct RoomLayoutEstimationResults *results);
