# Texture Synthesis Adapter

### Running Examples

```shell
cargo run --release --package texture_synthesis_adapter --example tile_preparation \
    -- \
    --example ./fixtures/wallpaper1.jpg \
    --output-dir ./output \
    --tiling-mask-ratio 0.2 \
    --backtrack-stages 20 \
    --nearest-neighbors 50 \
    --random-samples 50 \
    --cauchy-dispersion 1.0 \
    --input-resize 320
```