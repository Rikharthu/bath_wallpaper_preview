//
//  Line.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 19/09/2023.
//

import Foundation

struct Line: Codable {
    let start: Point
    let end: Point
    
    init(from start: Point, to end: Point) {
        self.start = start
        self.end = end
    }
}
