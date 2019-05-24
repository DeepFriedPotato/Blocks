//
//  Block.swift
//  Blocks
//
//  Created by 沈畅 on 5/10/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit

class BlockView: UIView {
    static let sideLength: CGFloat = 50
    
    let color: UIColor
    
    var usesRoundedCorners: Bool = false {
        didSet {
            if usesRoundedCorners {
                self.layer.cornerRadius = 15
            } else {
                self.layer.cornerRadius = 0
            }
        }
    }
    
    init(color: UIColor) {
        self.color = color
        super.init(frame: CGRect(x: 0, y: 0, width: BlockView.sideLength, height: BlockView.sideLength))
        self.backgroundColor = self.color
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    // For UIMenuController
    override var canBecomeFirstResponder: Bool {
        return true
    }
}
