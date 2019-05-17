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
    
    init(color: UIColor) {
        self.color = color
        super.init(frame: CGRect(x: 0, y: 0, width: BlockView.sideLength, height: BlockView.sideLength))
        self.backgroundColor = self.color
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}
