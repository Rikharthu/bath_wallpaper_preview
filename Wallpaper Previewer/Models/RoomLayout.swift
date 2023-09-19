//
//  RoomLayout.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 19/09/2023.
//

import Foundation

struct RoomLayout: Codable {
    let roomType: RoomType
    let edges: [Line]
    let wallPolygons: [Polygon]
}

