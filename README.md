# Wallpaper Preview

## Building and Running the Application

The application uses the [texture-synthesis](https://github.com/EmbarkStudios/texture-synthesis) Rust library and our
FFI bridge is generated using the `cbindgen`utility. As such, [Rust](https://www.rust-lang.org/tools/install)
and [cbindgen](https://github.com/mozilla/cbindgen) must be installed

XCode by default doesn't user the system's `PATH` variable. The easiest way to make `cargo` accessible to XCode during
the build phase is to modify the [bin/compile-library.sh](/bin/compile-library.sh) and change the line

```shell
PATH="$PATH:/Users/<user>/.cargo/bin"
```

to point to own Cargo installation directory.

Next, model weights must be downloaded
from [OneDrive/Shared Models](https://computingservices-my.sharepoint.com/:f:/g/personal/rak56_bath_ac_uk/EpuBnN5Utd5PjCufX5bNYFkB7gFVWwDfyUkqJgv313QMww?e=dQr7FK)
or [Google Drive/Shared Models](https://drive.google.com/drive/folders/1uxwYHxXAon9ae0vLJkPip-aGRLmRimNj?usp=sharing)
and placed into the [Wallpaper Previewer/Neural Networks](Wallpaper%20Previewer/Neural%20Networks) directory in Xcode.

From now on the project can be configured as usual Xcode iPhone application project and run on devices.

## Related Repositories

- Wall semantic segmentation model training and
  evaluation - [Rikharthu/bath_wall_segmentation_model](https://github.com/Rikharthu/bath_wall_segmentation_model)
- Room layout estimation model fork - [Rikharthu/pytorch-layoutnet](https://github.com/Rikharthu/pytorch-layoutnet)
- LSUN room layout network result parsing Rust
  code [Rikharthu/bath_rust_lsun_res_parser](https://github.com/Rikharthu/bath_rust_lsun_res_parser)
- Neural network model
  files - [OneDrive/Shared Models](https://computingservices-my.sharepoint.com/:f:/g/personal/rak56_bath_ac_uk/EpuBnN5Utd5PjCufX5bNYFkB7gFVWwDfyUkqJgv313QMww?e=dQr7FK)
  - Alternative: [Google Drive/Shared Models](https://drive.google.com/drive/folders/1uxwYHxXAon9ae0vLJkPip-aGRLmRimNj?usp=sharing)

## Attributions

### Images

Image assets bundled in the application seed data were taken from the following sources:

- Scene Parsing through ADE20K Dataset. Bolei Zhou, Hang Zhao, Xavier Puig, Sanja Fidler, Adela Barriuso and Antonio
  Torralba. Computer Vision and Pattern Recognition (CVPR),
    2017. [PDF](http://people.csail.mit.edu/bzhou/publication/scene-parse-camera-ready.pdf)
- Opara, A. and Stachowiak, T., 2021. texture-synthesis (v.0.8.2) [Online]. Embark Studios. Available
  from: https://github.com/EmbarkStudios/texture-synthesis
- ChatGPT + DALL-E, (pers. comm.) 20 July 2023
- Kmet, M., Smailova, S. and Lukianykhin, O., 2021. Using Augmented Reality in Interior & Property Design: How Did We
  Live Without It? [Online]. Available
  from: https://blog.griddynamics.com/using-augmented-reality-in-interior-property-design-how-did-we-live-without-it/ [Accessed 18 March 2023].
- Alexander Grey https://unsplash.com/photos/gray-concrete-brick-wallpaper-D_lsnqKA3PE
- Jarrod Reed https://unsplash.com/photos/brown-and-gray-concrete-brick-wall-BN9D50cVMBo
- Ashkan Forouzani
    - https://unsplash.com/photos/red-white-and-black-floral-textile-eBwGgqSt1QA
    - https://unsplash.com/photos/white-blue-and-brown-textile-oVrkcrvAO3s
- Birmingham Museums Trust
    - https://unsplash.com/photos/blue-and-white-abstract-painting-j4dEz8IHIhs
    - https://unsplash.com/photos/a-drawing-of-a-piece-of-cake-with-flowers-on-it-_sn71oyTN4o
    - https://unsplash.com/photos/brown-and-beige-floral-textile-tHsU3R9P_90
    - https://unsplash.com/photos/blue-and-white-floral-textile-G0PuUqpMfaY
- Leo Chane https://unsplash.com/photos/black-and-white-floral-textile-Y7YJL3de2zA
- Andrej Lišakov https://unsplash.com/photos/a-close-up-of-three-different-colors-of-paper-V2OyJtFqEtY
- Amy Tran https://unsplash.com/photos/closeup-photo-of-pink-paint-plank-wall-L2owAEPX0Vk
- Patrick Tomasso https://unsplash.com/photos/gray-concrete-bricks-painted-in-blue-QMDap1TAu0g
- Pawel Czerwinski https://unsplash.com/photos/pink-and-blue-abstract-painting-Qiy4hr18aGs
- Mitchell Luo https://unsplash.com/photos/green-leaves-plant-during-daytime-lWVQMR7sURg
- Henry & Co. https://unsplash.com/photos/gray-concrete-surface--odUkx8C2gg
- Andrew Ridley https://unsplash.com/photos/a-multicolored-tile-wall-with-a-pattern-of-small-squares-jR4Zf-riEjI

### Libraries

This project includes a copy of the [texture-synthesis](https://github.com/EmbarkStudios/texture-synthesis) library.

