//
//  DeletedBlock.swift
//  Blocks
//
//  Created by 沈畅 on 5/18/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import Foundation

struct DeletedBlock {
    let identifier: UUID
    let creationDate: Date
}

extension DeletedBlock: Codable {}

extension DeletedBlock {
    init(from block: Block) {
        self.init(identifier: block.identifier, creationDate: block.creationDate)
    }
}

extension DeletedBlock: Comparable {
    static func < (lhs: DeletedBlock, rhs: DeletedBlock) -> Bool {
        return lhs.creationDate < rhs.creationDate
    }
}
