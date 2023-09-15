//
//  PinchPhotoView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 15/09/2023.
//

import SwiftUI

struct PinchPhotoView: View {
    let photoFilePath: String

    @State
    private var isAnimating: Bool = false
    @State
    private var imageScale: CGFloat = 1
    @State
    private var currentDragOffset: CGSize = .zero
    @State
    private var lastDragOffset: CGSize = .zero
    private var imageOffset: CGSize {
        CGSize(
            width: lastDragOffset.width + currentDragOffset.width,
            height: lastDragOffset.height + currentDragOffset.height
        )
    }

    private var image: UIImage

    init(photoFilePath: String) {
        self.photoFilePath = photoFilePath
        self.image = UIImage(contentsOfFile: photoFilePath)!
    }

    var body: some View {
        ZStack {
            Color.clear

            // MARK: Page Image

            Image(uiImage: self.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
                .padding()
                .shadow(
                    color: .black.opacity(0.2),
                    radius: 12,
                    x: 2,
                    y: 2
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(x: imageOffset.width, y: imageOffset.height)
                .animation(.linear(duration: 1), value: isAnimating)
                .scaleEffect(imageScale)

                // MARK: Tap Gesture

                .onTapGesture(count: 2) {
                    if imageScale == 1 {
                        withAnimation(.spring()) {
                            imageScale = 5
                        }
                    } else {
                        resetImageState()
                    }
                }

                // MARK: Drag Gesture

                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.linear(duration: 1)) {
                                currentDragOffset = CGSize(
                                    width: value.translation.width / imageScale,
                                    height: value.translation.height / imageScale
                                )
                            }
                        }
                        .onEnded { _ in
                            if imageScale <= 1 {
                                resetImageState()
                            } else {
                                lastDragOffset = imageOffset
                                currentDragOffset = .zero
                            }
                        }
                )

                // MARK: Magnification Gesture

                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            withAnimation(.linear(duration: 1)) {
                                if imageScale >= 1, imageScale <= 5 {
                                    imageScale = value
                                } else if imageScale > 5 {
                                    imageScale = 5
                                }
                            }
                        }
                        .onEnded { _ in
                            if imageScale > 5 {
                                imageScale = 5
                            } else if imageScale <= 1 {
                                imageScale = 1
                            }
                        }
                )
        }
        .onAppear {
            isAnimating = true
        }

        // MARK: Info Panel

        .overlay(
            InfoPanelView(scale: imageScale, offset: imageOffset)
                .padding(.horizontal)
                .padding(.top, 30),
            alignment: .top
        )

        // MARK: Controls

        .overlay(
            Group {
                HStack {
                    // Scale Down
                    Button {
                        scaleImageDown()
                    } label: {
                        ControlImageView(icon: "minus.magnifyingglass")
                    }

                    // Reset
                    Button {
                        resetImageState()
                    } label: {
                        ControlImageView(icon: "arrow.up.left.and.down.right.magnifyingglass")
                    }

                    // Scale up
                    Button {
                        scaleImageUp()
                    } label: {
                        ControlImageView(icon: "plus.magnifyingglass")
                    }
                }
                .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .opacity(isAnimating ? 1 : 0)
            }.padding(.bottom, 30),
            alignment: .bottom
        )
    }

    private func resetImageState() {
        return withAnimation(.spring()) {
            imageScale = 1
            lastDragOffset = .zero
            currentDragOffset = .zero
        }
    }

    private func scaleImageUp() {
        return withAnimation(.spring()) {
            if imageScale < 5 {
                imageScale += 1

                if imageScale >= 5 {
                    imageScale = 5
                }
            }
        }
    }

    private func scaleImageDown() {
        return withAnimation(.spring()) {
            if imageScale > 1 {
                imageScale -= 1

                if imageScale <= 1 {
                    resetImageState()
                }
            }
        }
    }
}

struct PinchPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        PinchPhotoView(photoFilePath: "/path/to/some/photo")
    }
}
