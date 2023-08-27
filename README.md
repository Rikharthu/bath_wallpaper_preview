# Building and Deploying a Rust library on iOS

* https://blog.mozilla.org/data/2022/01/31/this-week-in-glean-building-and-deploying-a-rust-library-on-ios/

* https://mozilla.github.io/firefox-browser-architecture/experiments/2017-09-06-rust-on-ios.html

* https://www.youtube.com/watch?v=YcL6CXz1vmY
    * https://github.com/thombles/dw2019rust/blob/master/modules/02%20-%20Cross-compiling%20for%20Xcode.md
        * Describe the steps necessary in details

## TODO
* Integrate `cbindgen` in `build.rs` to regenerate C bindings.
* Store model somewhere else and add steps to download it as it is too large file.

'''
rustup default nightly
rustup update
rustup target add aarch64-apple-ios x86_64-apple-ios
'''

One can manually build target desired:
'''
cargo build -p shipping-rust-ffi --release --target aarch64-apple-ios
'''

We configure XCode **Build Phases** to compile this library as part of the
build process by using
the [compile-library.sh](/bin/compile-library.sh) script.

We also configure the **Link Binary with Libraries** build phase to link
'libshipping_rust_ffi.a' static library
artifact.%
