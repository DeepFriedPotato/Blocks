//
//  DocumentViewController.swift
//  Blocks
//
//  Created by 沈畅 on 5/8/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit

class DocumentViewController: UIViewController {
    
    var document: Document!
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        // Access the document
        document?.open(completionHandler: { [unowned self] (success) in
            if success {
                print()
                print("🎉Document open success")
                self.document.blocksIterator().forEach({ (block) in
                    let blockView = BlockView(color: block.color.uiColor)
                    blockView.center = block.center
                    self.view.addSubview(blockView)
                })
                print("   " + self.document.blocksDebugString())
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.documentStateChanged), name: UIDocument.stateChangedNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(self.blocksChanged), name: Document.blocksChangedNotification, object: nil)
                self.navigationItem.title = self.document.documentStateString()
                
                if self.document.documentState.contains(.inConflict) {
                    self.document.resolveConflict()
                }
                
                
                // Yuck. Can't put it in Document.init(), so I guess its goes here.
                self.document.finishedOpeningDocument()
                
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
                print("Failed to open document")
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
        
    }
    
    
    
    
}

// MARK: User action
extension DocumentViewController {
    
    @IBAction func dismissDocumentViewController() {
        print()
        print("👋 DismissDocumentViewController")
        self.document.close { (success) in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        
        
        let randomColor = Color.random()
        
        if document.documentState.contains(.editingDisabled) {
            let alert = UIAlertController(title: "Editing disabled!", message: "What a bummer", preferredStyle: UIAlertController.Style.alert)
            alert.view.backgroundColor = randomColor.uiColor
            let alertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
            alert.addAction(alertAction)
            present(alert, animated: true)
        }
        
        // Update View
        let blockView = BlockView(color: randomColor.uiColor)
        let halfWidth = BlockView.sideLength / 2.0
        let topInset = view.safeAreaInsets.top
        let randomCenter = CGPoint(x: .random(in: halfWidth...(320 - halfWidth)), y: .random(in: (halfWidth + topInset)...(320 - halfWidth)))
        blockView.center = randomCenter
        view.addSubview(blockView)
        
        // Update Model
        let block = Block.init(color: randomColor, center: randomCenter, identifier: UUID(), creationDate: Date())
        print()
        print("❇️Add button Pressed. New block UUID: \(block.identifier). Time: \(Date())")
        document.addBlock(block)
        
    }
    
    @IBAction func debugButtonPressed(_ sender: UIBarButtonItem) {
        print("==DEBUG==")
        print("NSFileVersion CURRENT")
        let currentVersion = NSFileVersion.currentVersionOfItem(at: document.fileURL)!
        print(currentVersion)
        print("isConflict: \(currentVersion.isConflict)")
        print("modificationDate: \(currentVersion.modificationDate!)")
        print("URL: \(currentVersion.url)")
        print("Current blocks")
        print(document.blocksDebugString())
        print("currentVersion URL matches document URL: \(currentVersion.url == document.fileURL)")
        print("document.fileURL: \(document.fileURL)")
        
        print("===")
        let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: document.fileURL)!
        print("unresolvedConflictVersions Count: \(conflictVersions.count)")
        for conflictVersion in conflictVersions {
            print("(")
            print(conflictVersion)
            print("isConflict: \(conflictVersion.isConflict)")
            print("modificationDate: \(conflictVersion.modificationDate!)")
            print("URL: \(conflictVersion.url)")
            print(")")
        }
        
        
        print("Attempting to open first of conflictVersions")
        if let conflictVersion = conflictVersions.first {
            let conflictDocument = Document(fileURL: conflictVersion.url)
            print("conflictDocument state: \(conflictDocument.documentState.debugDescription)")
            /*
            conflictDocument.open { (success) in
                print("Conflict document opened success: \(success)")
                print("conflictDocument state: \(conflictDocument.documentState.debugDescription)")
                if success {
                    print("Conflict document blocks:")
                    print(conflictDocument.blocksDebugString())
                    conflictDocument.close(completionHandler: { (closeSuccess) in
                        print("Conflict document closed success: \(closeSuccess)")
                        print("==END DEBUG==")
                    })
                } else {
                    print("==END DEBUG==")
                }
            }
            */
            
            do {
                try conflictDocument.read(from: conflictVersion.url)
                print("READ from conflictDocument")
                print("conflictDocument state: \(conflictDocument.documentState.debugDescription)")
                print("Conflict document blocks:")
                print(conflictDocument.blocksDebugString())
            } catch {
                print("Failed to read from conflictDocument. Error \(error)")
            }
        }
        
        print("==END DEBUG==")
    }
}

// MARK: Block changes
extension DocumentViewController {
    // Called when DocumentViewController receives notification from the model that blocks have changed.
    @objc func blocksChanged(notfication: Notification) {
        print("DocumentVC: blocksChanged notification received. Changing UI.")
        let blockChanges = document.getBlockChanges()
        for blockChange in blockChanges {
            switch blockChange {
            case .insert(let block, let index):
                let blockView = BlockView(color: block.color.uiColor)
                blockView.center = block.center
                self.view.insertSubview(blockView, at: index)
            case .delete(let index):
                fatalError()
                //self.view.subviews.value(at: index)?.removeFromSuperview()
            }
        }
    }
}

// MARK: Document state
extension DocumentViewController {
    
    @objc func documentStateChanged(notification: Notification) {
        navigationItem.title = document.documentStateString()
        
    }
    
    
}



