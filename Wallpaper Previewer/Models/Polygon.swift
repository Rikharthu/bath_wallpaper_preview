//
//  Polygon.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 19/09/2023.
//

import Foundation

struct Polygon: Codable {
    let topLeft: Point
    let topRight: Point
    let bottomRight: Point
    let bottomLeft: Point
}
