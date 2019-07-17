//
//  SceneDelegate.swift
//  Blocks
//
//  Created by 沈畅 on 7/9/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit


class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    // UIWindowScene delegate
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        
        if let documentURL = connectionOptions.urlContexts.first?.url {
            if let documentBrowser = window?.rootViewController as? DocumentBrowserViewController {
                documentBrowser.presentDocument(at: documentURL, animated: false)
            }
        } else if let userActivity = session.stateRestorationActivity {
            if let bookmarkData = userActivity.userInfo?["bookmark"] as? Data {
                do {
                    var bookmarkDataIsStale: Bool = false
                    let documentURL = try URL.init(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &bookmarkDataIsStale)
                    print("decoded, bookmarkIsStale: \(bookmarkDataIsStale)")
                    print("\(window)")
                    
                    if let documentBrowser = window?.rootViewController as? DocumentBrowserViewController {
                        documentBrowser.presentDocument(at: documentURL, animated: false)
                    }
                    
                } catch {
                    print("Cannot init URL from bookmark data \(error)")
                }
            }
        }
        
    }
        // If there were no user activities, we don't have to do anything.
        // The `window` property will automatically be loaded with the storyboard's initial view controller.
    
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }
    
    
}
