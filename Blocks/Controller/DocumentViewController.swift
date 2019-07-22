//
//  DocumentViewController.swift
//  Blocks
//
//  Created by 沈畅 on 5/8/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit

class DocumentViewController: UIViewController {
    
    var canvasView: UIView!
    static let canvasSize = CGSize(width: 320, height: 320)
    
    
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var redoButton: UIBarButtonItem!
    
    private(set) var document: Document!
    var documentPresentationUUID = UUID()
    
    var lastTappedBlockView: BlockView?
    
    override func viewDidLoad() {
        print("DocumentViewController viewDidLoad()")
        canvasView = UIView(frame: CGRect(origin: .zero, size: DocumentViewController.canvasSize))
        //canvasView.backgroundColor = .red
        
        view.addSubview(canvasView)
        
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        canvasView.widthAnchor.constraint(equalToConstant: DocumentViewController.canvasSize.width).isActive = true
        canvasView.heightAnchor.constraint(equalToConstant: DocumentViewController.canvasSize.height).isActive = true
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGestureUpdated))
        view.addGestureRecognizer(pinchGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUndoAndRedoButtons), name: Notification.Name.NSUndoManagerCheckpoint, object: nil)
        undoButton.isEnabled = false
        redoButton.isEnabled = false
    }
    
    func configureUsingDocument(document: Document) {
        loadViewIfNeeded()
        self.document = document
        document.notificationCenter.addObserver(self, selector: #selector(blocksChanged(notfication:)), name: Document.blocksChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(documentStateChanged(notification:)), name: UIDocument.stateChangedNotification, object: nil)
        
        self.document.blocksIterator().forEach({ (block) in
            let blockView = BlockView(color: block.color.uiColor)
            blockView.center = block.center
            blockView.usesRoundedCorners = block.usesRoundedCorners
            self.canvasView.addSubview(blockView)
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.blockTapped))
            blockView.addGestureRecognizer(tap)
        })
        print("   " + self.document.blocksDebugString())
    }
    
//
//    func setAndOpenDocumentURL(_ url: URL, completion: @escaping () -> Void) {
//        loadViewIfNeeded()
//
//        url.startAccessingSecurityScopedResource()
//
//        self.document = Document(fileURL: url)
//
//        print("FileManager.default.isWritableFile(atPath: document.fileURL.path) \(FileManager.default.isWritableFile(atPath: document.fileURL.path))")
//
//
//
//        document.open(completionHandler: { [unowned self] (success) in
//            if success {
//                print()
//                print("🎉Document open success")
//                print("FileManager.default.isWritableFile(atPath: document.fileURL.path) \(FileManager.default.isWritableFile(atPath: self.document.fileURL.path))")
//                self.document.blocksIterator().forEach({ (block) in
//                    let blockView = BlockView(color: block.color.uiColor)
//                    blockView.center = block.center
//                    blockView.usesRoundedCorners = block.usesRoundedCorners
//                    self.canvasView.addSubview(blockView)
//                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.blockTapped))
//                    blockView.addGestureRecognizer(tap)
//                })
//                print("   " + self.document.blocksDebugString())
//
//                NotificationCenter.default.addObserver(self, selector: #selector(self.documentStateChanged), name: UIDocument.stateChangedNotification, object: nil)
//                NotificationCenter.default.addObserver(self, selector: #selector(self.blocksChanged), name: Document.blocksChangedNotification, object: nil)
//                self.updateNavigationBarTitle()
//
//                if self.document.documentState.contains(.inConflict) {
//                    self.document.resolveConflict()
//                }
//
//
//                // Yuck. Can't put it in Document.init(), so I guess its goes here.
//                self.document.finishedOpeningDocument()
//                completion()
//
//            } else {
//                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
//                print("Failed to open document")
//                showAlert(presentingViewController: self, title: "Failed to open document")
//            }
//        })
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            let bookmarkData = try document.fileURL.bookmarkData()
            
            let userActivity = NSUserActivity(activityType: "com.changshen.Blocks.openDocument")
            userActivity.title = "openDocument"
            userActivity.userInfo = ["bookmark" : bookmarkData]
            
            view.window?.windowScene?.userActivity = userActivity
            
            print("encoded")
            
        } catch {
            print("Cannot generate bookmark data \(error)")
        }
        
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.window?.windowScene?.userActivity = nil
    }
    
}

// MARK: User action
extension DocumentViewController {
    
    @IBAction func closeDocumentButtonTapped() {
        dismissDocumentViewController()
    }
    
    func dismissDocumentViewController(completion: (() -> Void)? = nil) {
        print()
        print("👋 DismissDocumentViewController")
        
        DocumentManager.shared.closeDocumentIfNecessary(url: document.fileURL, presenterUUID: documentPresentationUUID) { (success) in
            self.dismiss(animated: true, completion: nil)
        }
        
        
    }
    
    @objc func pinchGestureUpdated(gr: UIPinchGestureRecognizer) {
        if (gr.state == .began && gr.scale < 1) {
            dismissDocumentViewController()
        }
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        
        
        let randomColor = Color.random()
        
        
        let halfWidth = BlockView.sideLength / 2.0
        //let topInset = view.safeAreaInsets.top
        let canvasSize = DocumentViewController.canvasSize
        //let randomCenter = CGPoint(x: .random(in: halfWidth...(canvasSize.width - halfWidth)), y: .random(in: (halfWidth + topInset)...(canvasSize.height - halfWidth)))
        let randomCenter = CGPoint(x: .random(in: halfWidth...(canvasSize.width - halfWidth)), y: .random(in: halfWidth...(canvasSize.height - halfWidth)))

        
        // Update Model
        let block = Block.init(color: randomColor, center: randomCenter, uuid: UUID(), creationDate: Date(), modificationDate: Date(), usesRoundedCorners: false)
        print()
        print("❇️Add button Pressed. New block UUID: \(block.uuid). Time: \(Date())")
        
        let addedBlockIndex = document.getNumberOfBlocks()
        document.undoManager.undoablyDo({ [unowned self] in
            self.document.addBlock(block)
        }, undoClosure: { [unowned self] in
            self.document.deleteBlock(at: addedBlockIndex, addToDeletedUUIDs: false)
        })
        
    }
    
    
    @IBAction func undoButtonTapped(_ sender: UIBarButtonItem) {
        document.undoManager.undo()
        
    }
    
    
    @IBAction func redoButtonTapped(_ sender: UIBarButtonItem) {
        document.undoManager.redo()
        
    }
    
    @objc func updateUndoAndRedoButtons() {
        undoButton.isEnabled = document.undoManager.canUndo
        redoButton.isEnabled = document.undoManager.canRedo
    }
    
    @objc func blockTapped(gr: UITapGestureRecognizer) {
        print("blockTapped")
        guard let blockView = gr.view as? BlockView else { fatalError() }
        
        blockView.becomeFirstResponder()
        
        let menu = UIMenuController.shared
        let deleteMenuItem = UIMenuItem(title: "Delete", action: #selector(self.deleteMenuItemTapped))
        let roundedCornerMenuItem = UIMenuItem(title: (blockView.usesRoundedCorners ? "Disable" : "Enable") + " Rounded Corners", action: #selector(self.roundedCornersMenuItemTapped))
        menu.menuItems = [deleteMenuItem, roundedCornerMenuItem]
        menu.setTargetRect(blockView.frame, in: canvasView)
        menu.setMenuVisible(true, animated: true)
        
        lastTappedBlockView = blockView
        
        
    }
    
    @objc func deleteMenuItemTapped() {
        
        guard let lastTappedBlockView = lastTappedBlockView else { fatalError() }
        guard let index = canvasView.subviews.firstIndex(of: lastTappedBlockView) else { fatalError() }
        guard let block = document.getBlock(at: index) else { fatalError() }
        print("❌deleteMenuItemTapped index=\(index) UUID=\(block.uuid)")
        
        document.undoManager.undoablyDo({ [unowned self] in
            self.document.deleteBlock(at: index)
        }, undoClosure: { [unowned self] in
            self.document.removeDeletedUUID(uuid: block.uuid)
            self.document.addBlock(block, atIndex: index)
        })
        
        
        
        self.lastTappedBlockView = nil
        
    }
    
    @objc func roundedCornersMenuItemTapped() {
        guard let lastTappedBlockView = lastTappedBlockView else { fatalError() }
        guard let index = canvasView.subviews.firstIndex(of: lastTappedBlockView) else { fatalError() }
        guard let block = document.getBlock(at: index) else { fatalError() }
        print("⏹roundedCornerMenuItemTapped index=\(index) UUID=\(block.uuid)")
        
        let currentUsesRoundedCorners = lastTappedBlockView.usesRoundedCorners
        
        document.undoManager.undoablyDo({ [unowned self] in
            self.document.setBlockUsesRoundedCorners(at: index, !currentUsesRoundedCorners)
        }, undoClosure: { [unowned self] in
            self.document.setBlockUsesRoundedCorners(at: index, currentUsesRoundedCorners)
        })
        
        self.lastTappedBlockView = nil
    }
}

// MARK: Block changes
extension DocumentViewController {
    // Called when DocumentViewController receives notification from the model that blocks have changed.
    @objc func blocksChanged(notfication: Notification) {
        print("DocumentVC: blocksChanged notification received. Changing UI.")
        let blockChanges = document.getBlockChanges()
        updateNavigationBarTitle()
        for blockChange in blockChanges {
            switch blockChange {
            case .insert(let block, let index):
                let blockView = BlockView(color: block.color.uiColor)
                blockView.center = block.center
                blockView.usesRoundedCorners = block.usesRoundedCorners
                self.canvasView.insertSubview(blockView, at: index)
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.blockTapped))
                blockView.addGestureRecognizer(tap)
            case .delete(let index):
                self.canvasView.subviews[index].removeFromSuperview()
                //self.view.subviews.value(at: index)?.removeFromSuperview()
            case .modify(let newBlock, let index):
                let blockView = self.canvasView.subviews[index] as! BlockView
                blockView.usesRoundedCorners = newBlock.usesRoundedCorners
            }
        }
    }
}

// MARK: Document state
extension DocumentViewController {
    
    func updateNavigationBarTitle() {
        navigationItem.title = "[\(document.getNumberOfBlocks())] \(document.documentStateString())"
    }
    
    @objc func documentStateChanged(notification: Notification) {
        updateNavigationBarTitle()
        
    }
    
    
}



