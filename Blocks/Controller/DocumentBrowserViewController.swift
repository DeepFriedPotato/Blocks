//
//  DocumentBrowserViewController.swift
//  Blocks
//
//  Created by 沈畅 on 5/8/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    static let bookmarkDataKey = "bookmarkData"
    var documentViewController: DocumentViewController? {
        return presentedViewController?.children.first as? DocumentViewController
    }
    
    
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
        let newDocumentURL = tempDir.appendingPathComponent("Untitled").appendingPathExtension("blocks")
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
    
    func presentDocument(at documentURL: URL, animated: Bool = true) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentNavigationViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentNavigationViewController") as! UINavigationController
        let documentViewController = documentNavigationViewController.children.first! as! DocumentViewController
        documentViewController.document = Document(fileURL: documentURL)
        
        present(documentNavigationViewController, animated: animated, completion: nil)
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        print("encodeRestorableState")
        if let documentViewController = documentViewController, let documentURL = documentViewController.document?.fileURL {
            do {
                let didStartAccessing = documentURL.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        documentURL.stopAccessingSecurityScopedResource()
                    }
                }
                
                if didStartAccessing {
                    let bookmarkData = try documentURL.bookmarkData()
                    coder.encode(bookmarkData, forKey: DocumentBrowserViewController.bookmarkDataKey)
                    print("encoded")
                }
            } catch {
                print("Cannot generate bookmark data \(error)")
            }
        } else {
            print("No docuemntViewController to encode")
        }
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        print("decodeRestorableState")
        if let bookmarkData = coder.decodeObject(of: NSData.self, forKey: DocumentBrowserViewController.bookmarkDataKey) as Data? {
            do {
                var bookmarkDataIsStale: Bool = false
                let documentURL = try URL.init(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &bookmarkDataIsStale)
                print("decoded")
                presentDocument(at: documentURL, animated: false)
                    
                
            } catch {
                print("Cannot init URL from bookmark data \(error)")
            }
        } else {
            print("No bookmarkData to decode")
        }
        super.decodeRestorableState(with: coder)
    }
}

