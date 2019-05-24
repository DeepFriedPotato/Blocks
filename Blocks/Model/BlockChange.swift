//
//  BlockChange.swift
//  Blocks
//
//  Created by 沈畅 on 5/12/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import Foundation

enum BlockChange: CustomDebugStringConvertible {
    case insert(Block, Int)
    case delete(Int)
    case modify(Block, Int)
    
    var debugDescription: String {
        switch self {
        case .insert(let block, let index):
            return "Insert(\(block.identifier), \(index))"
        case .delete(let index):
            return "Delete(\(index))"
        case .modify(let newBlock, let index):
            return "Modify(\(newBlock.identifier), \(index))"
        }
    }
}

