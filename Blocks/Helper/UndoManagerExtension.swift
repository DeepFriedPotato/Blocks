//
//  UndoManagerExtension.swift
//  Blocks
//
//  Created by 沈畅 on 7/18/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import Foundation

extension UndoManager {
    func undoablyDo(_ closure: @escaping ()->(), shouldRun: Bool = true, undoClosure: @escaping ()->()) {
        self.registerUndo(withTarget: self) { target in
            target.redoablyDo(undoClosure, redoClosure: closure)
        }
        if shouldRun { closure() }
    }
    
    func redoablyDo(_ closure: @escaping ()->(), redoClosure: @escaping ()->()) {
        
        self.registerUndo(withTarget: self) { target in
            target.undoablyDo(redoClosure, undoClosure: closure)
        }
        closure()
    }
}
