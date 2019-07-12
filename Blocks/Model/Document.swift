//
//  Document.swift
//  Blocks
//
//  Created by 沈畅 on 5/8/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    struct BlocksBundle: Codable {
        let blocks: [Block]
        let deletedUUIDs: Set<UUID>
    }
    
    static let blocksChangedNotification: Notification.Name = Notification.Name("DocumentBlocksChangedNotification")
    
    private var blocks = [Block]()
    private var deletedUUIDs = Set<UUID>()
    private var blockChanges = [BlockChange]()
    private var shouldUpdateChangeCountOnNextStateChange = false
    
    
    
    // Called by View Controller
    func finishedOpeningDocument() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.documentStateChanged), name: UIDocument.stateChangedNotification, object: nil)
    }
    
    
    
    @objc private func documentStateChanged(notification: Notification) {
        print()
        print(" 🔀documentStateChanged: \(documentStateString())           [\(hasUnsavedChanges ? "hasUnsavedChanges💾" : "nothingToSave🤷‍♂️")]")
        if shouldUpdateChangeCountOnNextStateChange && !documentState.contains(.editingDisabled){
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
        let data = try! jsonEncoder.encode(BlocksBundle(blocks: blocks, deletedUUIDs: deletedUUIDs)) as NSData
        
        let compressedData = try data.compressed(using: .zlib)
        
        
        print()
        print("✍️contents(forType:) Time: \(Date()) DEBUG: \(blocksDebugString(blocks: blocks)) DELETED: \(deletedBlocksDebugString(deletedUUIDs: deletedUUIDs))")
        return compressedData
    }
    
    
    // Quick note: updateChangeCount does not work inside here.
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        let data = contents as! NSData
        
        let decompressedData = try data.decompressed(using: .zlib) as Data
        
        let jsonDecoder = JSONDecoder()
        let decodedBundle = try jsonDecoder.decode(BlocksBundle.self, from: decompressedData)
        let decodedBlocks = decodedBundle.blocks
        let decodedDeletedUUIDs = decodedBundle.deletedUUIDs
        
        deletedUUIDs = deletedUUIDs.union(decodedDeletedUUIDs)
        print()
        print("\(self.documentState.contains(.closed) ? "   " : "")📖load(fromContents:) Time: \(Date()) ")
        // May 15 5:29 PM
        
        
        if !documentState.contains(.closed) { // Document is open
            
            // May 15 5:29 PM. Attempting to merge within load(fromContents:)
            //blockChanges = findChange(old: blocks, new: decodedBlocks)
            
            let merged = merge(first: blocks, second: decodedBlocks, deleted: deletedUUIDs)
            //print("📖Merged: \(blocksDebugString(blocks: merged))")
            
            blockChanges = findChange(old: blocks, new: merged)
            
            // End May 15 5:29 PM
            
            print("   BLOCK CHANGES: " + blockChanges.debugDescription)
            if !blockChanges.isEmpty {
                //print("   OLD BLOCKS: \(blocksDebugString(blocks: blocks))")
                blocks = merged
                // Send notification
                NotificationCenter.default.post(name: Document.blocksChangedNotification, object: nil)
                
                if (decodedBlocks != merged) {
                    shouldUpdateChangeCountOnNextStateChange = true
                    print("   (🙋‍♂️)scheduled to updateChangeCount(.done) in load. blockChange is not empty")
                }
            }
            
            
        } else {
            blocks = decodedBlocks
            print("   document is closed. No notification sent")
        }
        
        
    }
    
    
    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
        print(error)
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
    
    func deleteBlock(at index: Int) {
        guard index >= 0 && index < blocks.count else { fatalError() }
        let blockToDelete = blocks[index]
        
        deletedUUIDs.insert(blockToDelete.uuid)
        
        blocks.remove(at: index)
        
        if documentState.contains(.editingDisabled) {
            shouldUpdateChangeCountOnNextStateChange = true
            print("   (🙋‍♂️)scheduled to updateChangeCount(.done) because a block is deleted")
        } else {
            updateChangeCount(.done)
            print("   🙋‍♂️updateChangeCount(.done) because a block is deleted")
            
        }
    }
    
    func setBlockUsesRoundedCorners(at index: Int, _ usesRoundedCorners: Bool) {
        guard index >= 0 && index < blocks.count else { fatalError() }
        blocks[index].usesRoundedCorners = usesRoundedCorners
        blocks[index].modificationDate = Date()
        
        if documentState.contains(.editingDisabled) {
            shouldUpdateChangeCountOnNextStateChange = true
            print("   (🙋‍♂️)scheduled to updateChangeCount(.done) because a block is modified")
        } else {
            updateChangeCount(.done)
            print("   🙋‍♂️updateChangeCount(.done) because a block is modified")
            
        }
    }
    
    func blocksIterator() -> IndexingIterator<[Block]> {
        return blocks.makeIterator()
    }
    
    func getBlockChanges() -> [BlockChange] {
        return blockChanges
    }
    
    func getNumberOfBlocks() -> Int {
        return blocks.count
    }
    
    func getBlock(at index: Int) -> Block? {
        return (0 <= index && index < blocks.count) ? blocks[index] : nil
    }
}

extension Document {
    private func findChange(old: [Block], new: [Block]) -> [BlockChange] {
        //let patches = patch(from: old, to: new)
        
        let patches = new.difference(from: old)
        var blockChanges = [BlockChange]()
        
        for patch in patches {
            switch patch {
            case .insert(let offset, let element, _):
                blockChanges.append(BlockChange.insert(element, offset))
            case .remove(let offset, _, _):
                blockChanges.append(BlockChange.delete(offset))
            }
        }
        
        
        // Find modifications
        var newDictionary = [UUID:(Int,Block)]()
        for (index, newBlock) in new.enumerated() {
            newDictionary[newBlock.uuid] = (index,newBlock)
        }
        
        for oldBlock in old {
            guard let (index,newBlock) = newDictionary[oldBlock.uuid] else { continue }   // If new does not contain oldBlock identifier, skip
            if !newBlock.fullyEquals(other: oldBlock) {
                blockChanges.append(BlockChange.modify(newBlock, index))
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
        
        var bundleVersions = [BlocksBundle]()
        
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
                    bundleVersions.append(BlocksBundle(blocks: conflictDocument.blocks, deletedUUIDs: conflictDocument.deletedUUIDs))
                    //print("   Conflict document blocks: \(blocksDebugString(blocks: conflictDocument.blocks))")
                    print("   ===END OPENING CONFLICT DOCUMENT===")
                } catch {
                    fatalError("Failed to read from conflictDocument. Error \(error)")
                }
            }
        }
        
        let result = BlocksBundle(blocks: self.blocks, deletedUUIDs: self.deletedUUIDs)
        let merged = bundleVersions.reduce(into: result) { (result, bundle) in
            let mergedDeletedUUIDs = result.deletedUUIDs.union(bundle.deletedUUIDs)
            let mergedBlocks = merge(first: result.blocks, second: bundle.blocks, deleted: mergedDeletedUUIDs)
            result = BlocksBundle(blocks: mergedBlocks, deletedUUIDs: mergedDeletedUUIDs)
        }
        
        
        blockChanges = findChange(old: self.blocks, new: merged.blocks)
        print("   BLOCK CHANGES: \(blockChanges)")
        print("   Reminder: Current blocks: \(blocksDebugString(blocks: blocks))")
        if !blockChanges.isEmpty {
            // Send notification
            NotificationCenter.default.post(name: Document.blocksChangedNotification, object: nil)
            blocks = merged.blocks // Only update blocks if there are changes
            shouldUpdateChangeCountOnNextStateChange = true
            print("   (🙋‍♂️)scheduled to updateChangeCount(.done) in load. blockChange is not empty")
        }
        
        if (deletedUUIDs != merged.deletedUUIDs) {
            deletedUUIDs = merged.deletedUUIDs
            shouldUpdateChangeCountOnNextStateChange = true
            print("   (🙋‍♂️)scheduled to updateChangeCount(.done) in load. deletedBlocks Updated")
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
    func merge(first: [Block], second: [Block], deleted: Set<UUID>) -> [Block] {
        let all = first + second.reversed()
        let merged = all.reduce(into: (all, [Block]()), { (result, block) in
            guard let firstBlock = result.0.first else { return }
            guard let lastBlock = result.0.last else { return }
            
            if firstBlock.creationDate < lastBlock.creationDate {
                result.0.removeFirst()
                if !deleted.contains(firstBlock.uuid) {
                    result.1.append(firstBlock)
                }
            } else if firstBlock.creationDate > lastBlock.creationDate {
                result.0.removeLast()
                if !deleted.contains(lastBlock.uuid) {
                    result.1.append(lastBlock)
                }
            } else {
                result.0.removeFirst()
                if result.0.count >= 1 && firstBlock == lastBlock {    // Last one only need to be removed once.
                    result.0.removeLast()
                }
                if !deleted.contains(firstBlock.uuid) {
                    // Append the version with the latest modification date.
                    let useFirstBlock = firstBlock.modificationDate > lastBlock.modificationDate
                    result.1.append(useFirstBlock ? firstBlock : lastBlock)
                }
            }
        }).1
        print()
        print("   ===🥣MERGE🥣===")
        print("      First: \(blocksDebugString(blocks: first))")
        print("      Second: \(blocksDebugString(blocks: second))")
        print("      Deleted: \(deletedBlocksDebugString(deletedUUIDs: deleted))")
        print("      Merged: \(blocksDebugString(blocks: merged))")
        print("   ===END MERGE===")
        print()
        return merged
    }
}

// Debug string for blocks
extension Document {
    func blocksDebugString() -> String {
        return "BLOCKS: " + blocksDebugString(blocks: self.blocks) + " DELETED: " + deletedBlocksDebugString(deletedUUIDs: self.deletedUUIDs)
    }
    private func blocksDebugString(blocks: [Block]) -> String {
        return blocks.map{$0.uuid.uuidString}.reduce("Count: \(blocks.count), UUIDs: {", {$0 + $1 + ", "}) + "}"
    }
    private func deletedBlocksDebugString(deletedUUIDs: Set<UUID>) -> String {
        return deletedUUIDs.map{$0.uuidString}.reduce("Count: \(deletedUUIDs.count), UUIDs: {", {$0 + $1 + ", "}) + "}"
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
