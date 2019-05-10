//
//  DocumentBrowserViewController.swift
//  Blocks
//
//  Created by 沈畅 on 5/8/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        
        // Update the style of the UIDocumentBrowserViewController
        // browserUserInterfaceStyle = .dark
        // view.tintColor = .white
        
        // Specify the allowed content types of your application via the Info.plist.
        
        // Do any additional setup after loading the view.
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let tempDir = FileManager.default.temporaryDirectory
        let newDocumentURL = tempDir.appendingPathComponent("Blank").appendingPathExtension("blocks")
        let newDocument = Document(fileURL: newDocumentURL)
        
        newDocument.save(to: newDocumentURL, for: .forCreating) { (saveSuccess) in
            guard saveSuccess else {
                fatalError("Failed to save document upon creation")
            }
            newDocument.close(completionHandler: { (closeSuccess) in
                guard closeSuccess else {
                    fatalError("Failed to close the document upon creation")
                }
                importHandler(newDocumentURL, .move)
            })
        }
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentNavigationViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentNavigationViewController") as! UINavigationController
        let documentViewController = documentNavigationViewController.children.first! as! DocumentViewController
        documentViewController.document = Document(fileURL: documentURL)
        
        present(documentNavigationViewController, animated: true, completion: nil)
    }
}

