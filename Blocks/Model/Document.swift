//
//  Document.swift
//  Blocks
//
//  Created by 沈畅 on 5/8/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    static let blocksChangedNotification: Notification.Name = Notification.Name("DocumentBlocksChangedNotification")
    
    private var blocks = [Block]()
    private var blockChanges = [BlockChange]()
    private var shouldUpdateChangeCountOnNextStateChange = false
    
    
    
    // Called by View Controller
    func finishedOpeningDocument() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.documentStateChanged), name: UIDocument.stateChangedNotification, object: nil)
    }
    
    @objc private func documentStateChanged(notification: Notification) {
        print()
        print(" 🔀documentStateChanged: \(documentStateString())           [\(hasUnsavedChanges ? "hasUnsavedChanges💾" : "nothingToSave🤷‍♂️")]")
        if shouldUpdateChangeCountOnNextStateChange {
            print("   🙋‍♂️updateChangeCount(.done) due to shouldUpdateChangeCountOnNextStateChange")
            updateChangeCount(.done)
            shouldUpdateChangeCountOnNextStateChange = false
        }
        if documentState.contains(.inConflict) {
            resolveConflict()
        }
    }
    
    // MARK: UIDocument Override
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        let data = try! jsonEncoder.encode(blocks)
        print()
        print("✍️contents(forType:) Time: \(Date()) DEBUG: \(blocksDebugString(blocks: blocks))")
        return data
    }
    
    
    // Quick note: updateChangeCount does not work inside here.
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        let data = contents as! Data
        let jsonDecoder = JSONDecoder()
        let decodedBlocks = try jsonDecoder.decode([Block].self, from: data)
        
        print()
        print("\(self.documentState.contains(.closed) ? "   " : "")📖load(fromContents:) Time: \(Date()) ")
        // May 15 5:29 PM
        
        
        if !documentState.contains(.closed) { // Document is open
            
            // May 15 5:29 PM. Attempting to merge within load(fromContents:)
            //blockChanges = findChange(old: blocks, new: decodedBlocks)
            
            let merged = merge(first: blocks, second: decodedBlocks)
            //print("📖Merged: \(blocksDebugString(blocks: merged))")
            
            blockChanges = findChange(old: blocks, new: merged)
            
            // End May 15 5:29 PM
            
            print("   BLOCK CHANGES: " + blockChanges.debugDescription)
            if !blockChanges.isEmpty {
                //print("   OLD BLOCKS: \(blocksDebugString(blocks: blocks))")
                blocks = merged
                // Send notification
                NotificationCenter.default.post(name: Document.blocksChangedNotification, object: nil)
                shouldUpdateChangeCountOnNextStateChange = true
                print("   (🙋‍♂️)scheduled to updateChangeCount(.done) in load. blockChange is not empty")
                
            }
            
            
        } else {
            blocks = decodedBlocks
            print("   document is closed. No notification sent")
        }
        
        
    }
}

// Methods for Controller (API)
extension Document {
    func addBlock(_ block: Block) {
        blocks.append(block)
        
        if documentState.contains(.editingDisabled) {
            shouldUpdateChangeCountOnNextStateChange = true
            print("   (🙋‍♂️)scheduled to updateChangeCount(.done) because new block is added")
        } else {
            updateChangeCount(.done)
            print("   🙋‍♂️updateChangeCount(.done) because new block is added")

        }
        
        if (documentState.contains(.editingDisabled)) {
            print("   ‼️‼️Attempting to updateChangeCount when .editingDisabled‼️‼️")
        }
    }
    
    func blocksIterator() -> IndexingIterator<[Block]> {
        return blocks.makeIterator()
    }
    
    func getBlockChanges() -> [BlockChange] {
        return blockChanges
    }
}

extension Document {
    private func findChange(old: [Block], new: [Block]) -> [BlockChange] {
        let patches = patch(from: old, to: new)
        var blockChanges = [BlockChange]()
        for patch in patches {
            switch patch {
            case .insertion(let index, let element):
                blockChanges.append(BlockChange.insert(element, index))
            case .deletion(let index):
                blockChanges.append(BlockChange.delete(index))
            }
        }
//        print("==findChange==")
//        print("Old: \(blocksDebugString(blocks: old))")
//        print("New: \(blocksDebugString(blocks: new))")
//        print("Changes: \(blockChanges)")
        return blockChanges
    }
    
    func resolveConflict() {
        
        print()
        print("===⚠️resolveConflict()⚠️===")
        
        var blocksVersions = [[Block]]()
        
        print("   Current blocks: \(blocksDebugString(blocks: blocks))")
        
        let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: self.fileURL)!
        print("   unresolvedConflictVersions Count: \(conflictVersions.count)")
        
        for conflictVersion in conflictVersions {
            let conflictDocument = Document(fileURL: conflictVersion.url)
        
            print("   ===BEGIN OPENING CONFLICT DOCUMENT===")
            let fileCoordinator = NSFileCoordinator(filePresenter: nil)
            var readingError: NSError? = nil
            fileCoordinator.coordinate(readingItemAt: conflictVersion.url, options: [], error: &readingError) { (url) in
                do {
                    try conflictDocument.read(from: conflictVersion.url)
                    blocksVersions.append(conflictDocument.blocks)
                    //print("   Conflict document blocks: \(blocksDebugString(blocks: conflictDocument.blocks))")
                    print("   ===END OPENING CONFLICT DOCUMENT===")
                } catch {
                    fatalError("Failed to read from conflictDocument. Error \(error)")
                }
            }
        }
        
        let result = self.blocks
        let merged = blocksVersions.reduce(into: result) { (result, blocks) in
            result = merge(first: result, second: blocks)
        }
        
        blockChanges = findChange(old: self.blocks, new: merged)
        print("   BLOCK CHANGES: \(blockChanges)")
        print("   Reminder: Current blocks: \(blocksDebugString(blocks: blocks))")
        if !blockChanges.isEmpty {
            // Send notification
            NotificationCenter.default.post(name: Document.blocksChangedNotification, object: nil)
            blocks = merged // Only update blocks if there are changes
            print("   🙋‍♂️updateChangeCount(.done) inside merge. blockChanges is not empty")
            if (documentState.contains(.editingDisabled)) {
                print("   ‼️‼️Attempting to updateChangeCount when .editingDisabled‼️‼️")
            }
            updateChangeCount(.done)
        }
        
        
        
        do {
            print("   Begin to removeOtherVersions")
            print("   Current: \(NSFileVersion.currentVersionOfItem(at: self.fileURL)!.modificationDate!)")
            let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: self.fileURL)!
            for conflictVersion in conflictVersions {
                print("   RemovedConflict: \(conflictVersion.modificationDate!)")
                conflictVersion.isResolved = true
            }
            try NSFileVersion.removeOtherVersionsOfItem(at: self.fileURL)
            
        } catch {
            fatalError()
        }
        
        print("===END resolveConflict()===")
        
    }
    
    // https://stackoverflow.com/questions/51404787/how-to-merge-two-sorted-arrays-in-swift
    func merge(first: [Block], second: [Block]) -> [Block] {
        let all = first + second.reversed()
        let merged = all.reduce(into: (all, [Block]()), { (result, block) in
            guard let first = result.0.first else { return }
            guard let last = result.0.last else { return }
            
            if first.creationDate < last.creationDate {
                result.0.removeFirst()
                result.1.append(first)
            } else if first.creationDate > last.creationDate {
                result.0.removeLast()
                result.1.append(last)
            } else {
                result.0.removeFirst()
                if result.0.count >= 1 {    // Last one only need to be removed once.
                    result.0.removeLast()
                }
                result.1.append(first)
            }
        }).1
        print()
        print("   ===🥣MERGE🥣===")
        print("      First: \(blocksDebugString(blocks: first))")
        print("      Second: \(blocksDebugString(blocks: second))")
        print("      Merged: \(blocksDebugString(blocks: merged))")
        print("   ===END MERGE===")
        print()
        return merged
    }
}

// Debug string for blocks
extension Document {
    func blocksDebugString() -> String {
        return blocksDebugString(blocks: self.blocks)
    }
    private func blocksDebugString(blocks: [Block]) -> String {
        return blocks.map{$0.identifier.uuidString}.reduce("Count: \(blocks.count), UUIDs: {", {$0 + $1 + ", "}) + "}"
    }
    func documentStateString() -> String {
        return documentState.debugDescription
    }
}

extension UIDocument.State: CustomDebugStringConvertible {
    public var debugDescription: String {
        var str = ""
        if self.contains(.normal) {
            str += "Normal, "
        }
        if self.contains(.closed) {
            str += "Closed, "
        }
        if self.contains(.inConflict) {
            str += "In conflict, "
        }
        if self.contains(.savingError) {
            str += "Saving error, "
        }
        if self.contains(.editingDisabled) {
            str += "Editing disabled, "
        }
        if self.contains(.progressAvailable) {
            str += "Progress available, "
        }
        str.removeLast(2)
        return str
    }
}
