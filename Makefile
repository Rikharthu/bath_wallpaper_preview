run_synthesis_experiment:
	cargo run --release -p texture_synthesis_adapter --example tile_preparation -- \
	--example ./texture_synthesis_adapter/fixtures/water.jpeg \
	--output-dir synthesis_output \
	--tiling-mask-ratio 0.4 \
	--backtrack-stages 24 \
	--nearest-neighbors 100 \
	--random-samples 50 \
	--cauchy-dispersion 1.0