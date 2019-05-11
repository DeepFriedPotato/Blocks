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
                print("document open success")
                self.document.blocksIterator().forEach({ (block) in
                    let blockView = BlockView(color: block.color.uiColor)
                    blockView.center = block.center
                    self.view.addSubview(blockView)
                })
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    @IBAction func dismissDocumentViewController() {
        print("DismissDocumentViewController \(self.document.blocks)")
        self.document.close { (success) in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        print("Add button Pressed")
        
        let randomColor = Color.random()
        
        // Update View
        let blockView = BlockView(color: randomColor.uiColor)
        let halfWidth = BlockView.sideLength / 2.0
        let topInset = view.safeAreaInsets.top
        let randomCenter = CGPoint(x: .random(in: halfWidth...(view.bounds.width - halfWidth)), y: .random(in: (halfWidth + topInset)...(view.bounds.height - halfWidth)))
        blockView.center = randomCenter
        view.addSubview(blockView)
        
        // Update Model
        let block = Block.init(color: randomColor, center: randomCenter, identifier: UUID(), creationDate: Date())
        document.addBlock(block)
        document.updateChangeCount(.done)
        
    }
    
}
