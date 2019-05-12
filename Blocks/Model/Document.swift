//
//  Document.swift
//  Blocks
//
//  Created by 沈畅 on 5/8/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    var blocks = [Block]()
    
    // MARK: UIDocument Override
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        let data = try jsonEncoder.encode(blocks)
        print("contents(forType:) DEBUG: \(blocksDebugString(blocks: blocks))")
        return data
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        let data = contents as! Data
        let jsonDecoder = JSONDecoder()
        let decodedBlocks = try jsonDecoder.decode([Block].self, from: data)
        print("load(fromContents:) DEBUG: \(blocksDebugString(blocks: decodedBlocks))")
        blocks = decodedBlocks
    }
    
    // MARK: Block manipulation
    
    func addBlock(_ block: Block) {
        blocks.append(block)
    }
    
    func blocksIterator() -> IndexingIterator<[Block]> {
        return blocks.makeIterator()
    }
    
    
}

extension Document {
    private func blocksDebugString(blocks: [Block]) -> String {
        return blocks.map{$0.identifier.uuidString}.reduce("Count: \(blocks.count), UUIDs: {", {$0 + $1 + ", "}) + "}"
    }
}

