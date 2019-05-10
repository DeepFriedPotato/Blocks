//
//  DocumentViewController.swift
//  Blocks
//
//  Created by 沈畅 on 5/8/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit

class DocumentViewController: UIViewController {
    
    
    var document: UIDocument?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
        }
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        print("Add button Pressed")
        let block = Block()
        let halfWidth = Block.sideLength / 2.0
        let topInset = view.safeAreaInsets.top
        let randomCenter = CGPoint(x: .random(in: halfWidth...(view.bounds.width - halfWidth)), y: .random(in: (halfWidth + topInset)...(view.bounds.height - halfWidth)))
        block.center = randomCenter
        view.addSubview(block)
    }
    
}
