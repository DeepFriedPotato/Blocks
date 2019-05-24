//
//  ThumbnailProvider.swift
//  BlocksThumbnailExtension
//
//  Created by 沈畅 on 5/24/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit
import QuickLook

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        
        
        let fileURL = request.fileURL
        let maximumSize = request.maximumSize
        let scale = request.scale
        
        print("provideThumbnail for \(fileURL) maximumSize \(maximumSize)")
        
        //let contextSize = contextSizeForFile(at: fileURL, maximumSize: maximumSize, scale: scale)
        
        let drawingBlock: () -> Bool = {
            print("drawingBlock start")
            let success = ThumbnailProvider.drawThumbnail(for: fileURL, contextSize: maximumSize)
            print("drawingBlock success: \(success)")
            return success
        }
        
        let reply = QLThumbnailReply(contextSize: maximumSize, currentContextDrawing: drawingBlock)
        print("reply: \(reply)")
        handler(reply, nil)
    }
    
    private func contextSizeForFile(at URL: URL, maximumSize: CGSize, scale: CGFloat) -> CGSize {
        return DocumentViewController.canvasSize
    }
    
    private static func drawThumbnail(for fileURL: URL, contextSize: CGSize) -> Bool {
        print("drawThumbnail")
        let document = Document(fileURL: fileURL)
        let openingSemaphore = DispatchSemaphore(value: 0)
        var openingSuccess = false
        
        let frame = CGRect(origin: .zero, size: contextSize)
        
        let view = UIView(frame: CGRect(origin: .zero, size: DocumentViewController.canvasSize))
        
        document.open { (success) in
            
            if success {
                
                // NOT SURE ABOUT THIS
                /*
                if document.documentState.contains(.inConflict) {
                    document.resolveConflict()
                }
                */
                
                print("🎉Document open success")
                document.blocksIterator().forEach({ (block) in
                    let blockView = BlockView(color: block.color.uiColor)
                    blockView.center = block.center
                    blockView.usesRoundedCorners = block.usesRoundedCorners
                    view.addSubview(blockView)
                })
                print("   " + document.blocksDebugString())
                
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
                print("Failed to open document")
            }
            openingSuccess = success
            openingSemaphore.signal()
        }
        openingSemaphore.wait()
        
        guard openingSuccess else { return false }
        
        view.layoutIfNeeded()
        
        
        let renderer = UIGraphicsImageRenderer(size: DocumentViewController.canvasSize)
        let renderedImage = renderer.image { (context) in
            view.layer.render(in: context.cgContext)
        }
        print("renderedImage \(renderedImage)")
        renderedImage.draw(in: frame)
        
        let closingSemaphore = DispatchSemaphore(value: 0)
        document.close { (_) in
            closingSemaphore.signal()
        }
        closingSemaphore.wait()
        
        return true
    }
}
