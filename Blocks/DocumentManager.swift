//
//  DocumentManager.swift
//  Blocks
//
//  Created by 沈畅 on 7/16/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit

class DocumentManager {
    static let shared = DocumentManager()
    
    // Presenter UUID is used to track document open/close.
    var managedDocuments = [(document: Document, presenters: Set<UUID>)]()
    
    func openDocumentIfNecessary(url: URL, presenterUUID: UUID, completionHandler: @escaping (Document?) -> Void) {
        _ = url.startAccessingSecurityScopedResource()
        let resolvedURL = url.resolvingSymlinksInPath()
        let documentAlreadyOpen = managedDocuments.map {$0.document.fileURL}.contains(resolvedURL)
        if documentAlreadyOpen {
            // Get the existing document matching the url.
            for (index, tuple) in managedDocuments.enumerated() {
                if tuple.document.fileURL == resolvedURL {
                    managedDocuments[index].presenters.insert(presenterUUID)
                    completionHandler(tuple.document)
                    return
                }
            }
        } else {
            // Create new document
            let document = Document(fileURL: url)
            let tuple = (document, Set(arrayLiteral: presenterUUID))
            managedDocuments.append(tuple)
            document.open { (success) in
                document.startObservingDocumentStateNotifications()
                completionHandler(success ? document : nil)
            }
        }
    }
    
    func closeDocumentIfNecessary(url: URL, presenterUUID: UUID, completionHandler: @escaping (Bool) -> Void) {
        for (index, tuple) in managedDocuments.enumerated() {
            if tuple.document.fileURL == url {
                if tuple.presenters.count > 1 {
                    managedDocuments[index].presenters.remove(presenterUUID)
                    completionHandler(true)
                } else {
                    managedDocuments.remove(at: index)
                    tuple.document.close { (success) in
                        url.stopAccessingSecurityScopedResource()
                        completionHandler(success)
                        return
                    }
                }
            }
        }
    }
}
