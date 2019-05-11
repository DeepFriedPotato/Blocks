//
//  Block.swift
//  Blocks
//
//  Created by 沈畅 on 5/10/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import Foundation
import CoreGraphics

struct Block {
    let color: Color
    var center: CGPoint
    let identifier: UUID
    let creationDate: Date
}

extension Block: Codable {}
