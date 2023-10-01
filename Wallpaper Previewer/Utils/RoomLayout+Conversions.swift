//
//  RoomLayout+Conversions.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 19/09/2023.
//

import Foundation

extension RoomLayoutData {
    
    var model: RoomLayout {
        let roomType = RoomType(rawValue: Int(self.room_type))!
        
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

extension LayoutWallPolygon {
    var model: Polygon {
        return Polygon(
            topLeft: self.top_left.model,
            topRight: self.top_right.model,
            bottomRight: self.bottom_right.model,
            bottomLeft: self.bottom_left.model
        )
    }
}

extension Point {
    var ffiModel: LayoutPoint {
        return LayoutPoint(x: Int32(self.x), y: Int32(self.y))
    }
}

extension Line {
    var ffiModel: LayoutLine {
        return LayoutLine(start: self.start.ffiModel, end: self.end.ffiModel)
    }
}

extension Polygon {
    var ffiModel: LayoutWallPolygon {
        return LayoutWallPolygon(
            top_left: self.topLeft.ffiModel,
            top_right: self.topRight.ffiModel,
            bottom_right: self.bottomRight.ffiModel,
            bottom_left: self.bottomLeft.ffiModel
        )
    }
}

extension RoomLayout {
    var ffiModel: RoomLayoutData {
        let num_lines = self.edges.count
        var lines = (
            LayoutLine(),
            LayoutLine(),
            LayoutLine(),
            LayoutLine(),
            LayoutLine(),
            LayoutLine(),
            LayoutLine(),
            LayoutLine()
        )
        if num_lines > 0 {
            lines.0 = self.edges[0].ffiModel
        }
        if num_lines > 1 {
            lines.1 = self.edges[1].ffiModel
        }
        if num_lines > 2 {
            lines.2 = self.edges[2].ffiModel
        }
        if num_lines > 3 {
            lines.3 = self.edges[3].ffiModel
        }
        if num_lines > 4 {
            lines.4 = self.edges[4].ffiModel
        }
        if num_lines > 5 {
            lines.5 = self.edges[5].ffiModel
        }
        if num_lines > 6 {
            lines.6 = self.edges[6].ffiModel
        }
        if num_lines > 7 {
            lines.7 = self.edges[7].ffiModel
        }
        
        let num_polygons = self.wallPolygons.count
        var polygons = (
            LayoutWallPolygon(),
            LayoutWallPolygon(),
            LayoutWallPolygon()
        )
        if num_polygons > 0 {
            polygons.0 = self.wallPolygons[0].ffiModel
        }
        if num_polygons > 1 {
            polygons.1 = self.wallPolygons[1].ffiModel
        }
        if num_polygons > 2 {
            polygons.2 = self.wallPolygons[2].ffiModel
        }
        
        return RoomLayoutData(
            lines: lines,
            num_lines: UInt8(num_lines),
            room_type: UInt8(self.roomType.rawValue),
            wall_polygons: polygons,
            num_wall_polygons: UInt8(self.wallPolygons.count)
        )
    }
}
