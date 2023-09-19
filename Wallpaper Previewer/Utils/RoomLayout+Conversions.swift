//
//  RoomLayout+Conversions.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 19/09/2023.
//

import Foundation

extension RoomLayoutData {
    
    var model: RoomLayout {
        let roomType: RoomType
        switch self.room_type {
        case 0:
            roomType = .type0
        case 1:
            roomType = .type1
        case 2:
            roomType = .type2
        case 3:
            roomType = .type3
        case 4:
            roomType = .type4
        case 5:
            roomType = .type5
        case 6:
            roomType = .type6
        case 7:
            roomType = .type7
        case 8:
            roomType = .type8
        case 9:
            roomType = .type9
        case 10:
            roomType = .type10
        default:
            fatalError("Unknown room type: \(self.room_type)")
        }
        
        var edges = [Line]()
        // Swift doesn't support tuple indexing with variable, so there is need for such manual work
        if self.num_lines > 0 {
            edges.append(self.lines.0.model)
        }
        if self.num_lines > 1 {
            edges.append(self.lines.1.model)
        }
        if self.num_lines > 2 {
            edges.append(self.lines.2.model)
        }
        if self.num_lines > 3 {
            edges.append(self.lines.3.model)
        }
        if self.num_lines > 4 {
            edges.append(self.lines.4.model)
        }
        if self.num_lines > 5 {
            edges.append(self.lines.5.model)
        }
        if self.num_lines > 6 {
            edges.append(self.lines.6.model)
        }
        if self.num_lines > 7 {
            edges.append(self.lines.7.model)
        }
        
        var wallPolygons = [Polygon]()
        if self.num_wall_polygons > 0 {
            wallPolygons.append(self.wall_polygons.0.model)
        }
        if self.num_wall_polygons > 1 {
            wallPolygons.append(self.wall_polygons.1.model)
        }
        if self.num_wall_polygons > 2 {
            wallPolygons.append(self.wall_polygons.2.model)
        }
        
        return RoomLayout(roomType: roomType, edges: edges, wallPolygons: wallPolygons)
    }
}

extension LayoutPoint {
    var model: Point {
        return Point(x: Int(self.x), y: Int(self.y))
    }
}

extension LayoutLine {
    var model: Line {
        return Line(from: self.start.model, to: self.end.model)
    }
}

extension WallPolygon {
    var model: Polygon {
        return Polygon(
            topLeft: self.top_left.model,
            topRight: self.top_right.model,
            bottomRight: self.bottom_right.model,
            bottomLeft: self.bottom_left.model
        )
    }
}
