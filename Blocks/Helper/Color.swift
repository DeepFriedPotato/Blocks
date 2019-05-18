//
//  Color.swift
//  Blocks
//
//  Created by 沈畅 on 5/10/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit

struct Color: Equatable {
    let red: Double
    let green: Double
    let blue: Double
}

extension Color {
    var uiColor: UIColor {
        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 0.7)
    }
    
    static func random() -> Color {
        let uiColor = UIColor(hue: .random(in: 0...1), saturation: 0.8, brightness: 0.8, alpha: 1)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        let conversionSuccess = uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil);
        guard conversionSuccess else { fatalError() }
        return Color(red: Double(red), green: Double(green), blue: Double(blue))
    }
}

extension Color: Codable {
    
}
