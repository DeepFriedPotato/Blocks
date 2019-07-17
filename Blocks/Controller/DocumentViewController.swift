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
        document.addBlock(block)
        
        updateNavigationBarTitle()
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
        document.deleteBlock(at: index)
        
        
        self.lastTappedBlockView = nil
        
        updateNavigationBarTitle()
    }
    
    @objc func roundedCornersMenuItemTapped() {
        guard let lastTappedBlockView = lastTappedBlockView else { fatalError() }
        guard let index = canvasView.subviews.firstIndex(of: lastTappedBlockView) else { fatalError() }
        guard let block = document.getBlock(at: index) else { fatalError() }
        print("⏹roundedCornerMenuItemTapped index=\(index) UUID=\(block.uuid)")
        document.setBlockUsesRoundedCorners(at: index, !lastTappedBlockView.usesRoundedCorners)
        
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



