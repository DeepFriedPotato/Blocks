//
//  Block.swift
//  Blocks
//
//  Created by 沈畅 on 5/10/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit

class Block: UIView {
    static let sideLength: CGFloat = 100
    
    let color: UIColor
    
    init() {
        self.color = UIColor(hue: .random(in: 0...1), saturation: 0.8, brightness: 0.8, alpha: 1)
        super.init(frame: CGRect(x: 0, y: 0, width: Block.sideLength, height: Block.sideLength))
        self.backgroundColor = self.color
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}
