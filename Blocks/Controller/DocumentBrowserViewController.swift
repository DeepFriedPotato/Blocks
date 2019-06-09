//
//  DocumentBrowserViewController.swift
//  Blocks
//
//  Created by 沈畅 on 5/8/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIViewControllerTransitioningDelegate, UIDocumentPickerDelegate {
    
    static let bookmarkDataKey = "bookmarkData"
    var documentViewController: DocumentViewController? {
        return presentedViewController?.children.first as? DocumentViewController
    }
    
    var transitionController: UIDocumentBrowserTransitionController?
    
    
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
                print("Failed to save document upon creation")
                showAlert(presentingViewController: self, title: "Failed to save doucment upon creation")
                return
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
        print("didImportDocumentAt")
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
        print("failedToImportDocument at \(documentURL), error: \(error?.localizedDescription ?? "nil")")
        showAlert(presentingViewController: self, title: "Cannot import document", message: error?.localizedDescription)
    }
    
    // MARK: Document Presentation
    
    private var temporaryDirectoryURLForImport: URL? = nil
    func openURLFromApplication(url: URL, openInPlace: Bool) {
        if !openInPlace {
            var readWriteURL = url
            if !FileManager.default.isWritableFile(atPath: url.path) {
                // Attempt to move the file to Documents directory
                do {
                    
                    
                    readWriteURL = FileManager.default.temporaryDirectory
                    readWriteURL.appendPathComponent(url.lastPathComponent)
                    
                    if FileManager.default.fileExists(atPath: readWriteURL.path) {
                        try FileManager.default.removeItem(at: readWriteURL)
                    }
                    
                    try FileManager.default.moveItem(at: url, to: readWriteURL)
                    temporaryDirectoryURLForImport = readWriteURL
                } catch {
                    
                    fatalError()
                }
            }
            
            if let documentVC = self.documentViewController {  // There is a documentVC presented
                self.documentViewController?.dismissDocumentViewController(completion: {
                    self.showMoveToServiceDocumentPicker(fileURL: readWriteURL)
                })
            } else {
                self.showMoveToServiceDocumentPicker(fileURL: readWriteURL)
            }
        } else {
            revealAndOpenDocument(at: url)
        }
    }
    
    private func revealAndOpenDocument(at documentURL: URL) {
        revealDocument(at: documentURL, importIfNeeded: true) { (revealedDocumentURL, error) in
            if let error = error {
                // Handle the error appropriately
                print("Failed to reveal the document at URL \(documentURL) with error: '\(error)'")
                
                return
            }
            guard let revealedDocumentURL = revealedDocumentURL else {
                print("revelaedDocument URL is nil")
                return
            }
            print("FileManager.default.isWritableFile(atPath: revealedDocumentURL.path) \(FileManager.default.isWritableFile(atPath: revealedDocumentURL.path))")
            
            if let documentVC = self.documentViewController {  // There is a documentVC presented
                let alreadyOpened = (documentVC.document.fileURL == revealedDocumentURL)
                if !alreadyOpened {
                    self.documentViewController?.dismissDocumentViewController(completion: {
                        self.presentDocument(at: revealedDocumentURL)
                    })
                }
            } else {
                self.presentDocument(at: revealedDocumentURL)
            }
            
            
        }
    }
    
    func presentDocument(at documentURL: URL, animated: Bool = true) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentNavigationViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentNavigationViewController") as! UINavigationController
        let documentViewController = documentNavigationViewController.children.first! as! DocumentViewController
        
        var document = Document(fileURL: documentURL)
        print("FileManager.default.isWritableFile(atPath: document.fileURL.path) \(FileManager.default.isWritableFile(atPath: document.fileURL.path))")
        
        // When importing from external sources, the file is in Document/Inbox, which seems to be readonly.
//        if !FileManager.default.isWritableFile(atPath: document.fileURL.path) {
//            // Attempt to move the file to Documents directory
//            do {
//                var destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
//                destinationURL.appendPathComponent(document.fileURL.lastPathComponent)
//
//                print("destinationURL \(destinationURL)")
//
//                try FileManager.default.moveItem(at: document.fileURL, to: destinationURL)
//
//                document = Document(fileURL: destinationURL)
//            } catch {
//                fatalError()
//            }
//        }
        
        
        documentViewController.setAndOpenDocument(document) {
            documentNavigationViewController.transitioningDelegate = self
            self.transitionController = self.transitionController(forDocumentAt: documentURL)
            self.transitionController?.targetView = documentViewController.canvasView
            
            documentNavigationViewController.modalPresentationStyle = .fullScreen
            
            self.present(documentNavigationViewController, animated: animated, completion: nil)
        }
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
    
    // MARK: UIDocumentPickerViewController Move To Service
    
    func showMoveToServiceDocumentPicker(fileURL: URL) {
        let documentPickerVC = UIDocumentPickerViewController(url: fileURL, in: .moveToService)
        documentPickerVC.delegate = self
        present(documentPickerVC, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("documentPicker didPickDocumentsAt")
        
        temporaryDirectoryURLForImport = nil
        
        // picker.allowsMultipleSelection = false
        let newURL = urls.last!
        revealAndOpenDocument(at: newURL)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("documentPickerWasCancelled")
        if let temporaryDirectoryURLForImport = temporaryDirectoryURLForImport {
            do {
                try FileManager.default.removeItem(at: temporaryDirectoryURLForImport)
            } catch {
                print(" failed to remove temporary itme at \(temporaryDirectoryURLForImport)")
            }
            self.temporaryDirectoryURLForImport = nil
        }
    }
    
    // MARK: UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
    
}

