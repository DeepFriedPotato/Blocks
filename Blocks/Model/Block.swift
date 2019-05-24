//
//  Block.swift
//  Blocks
//
//  Created by 沈畅 on 5/10/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import Foundation
import CoreGraphics

struct Block: Equatable {
    let color: Color
    var center: CGPoint
    let identifier: UUID
    let creationDate: Date
    var modificationDate: Date
    var usesRoundedCorners: Bool
    
    // Equatable. Checks UUID only
    static func == (lhs: Block, rhs: Block) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    // Fully equals
    func fullyEquals(other: Block) -> Bool {
        return (color == other.color) && (center == other.center) && (usesRoundedCorners == other.usesRoundedCorners) && (modificationDate == other.modificationDate)
    }
}

extension Block: Codable {}
