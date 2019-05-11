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
        let data = try jsonEncoder.encode(blocks)
        print("contents(forType:) DATA: \(String(data: data, encoding: .utf8) ?? nil)")
        return data
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        let data = contents as! Data
        print("load(fromContents:) DATA: \(String(data: data, encoding: .utf8) ?? nil)")
        let jsonDecoder = JSONDecoder()
        blocks = try jsonDecoder.decode([Block].self, from: data)
    }
    
    // MARK: Block manipulation
    
    func addBlock(_ block: Block) {
        blocks.append(block)
    }
    
    func blocksIterator() -> IndexingIterator<[Block]> {
        return blocks.makeIterator()
    }
    
    
}

