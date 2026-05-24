import SwiftUI
import UIKit

extension HSB {
    init(_ uiColor: UIColor) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        self.init(hue: Double(h) * 360, saturation: Double(s), brightness: Double(b))
    }

    var uiColor: UIColor {
        UIColor(
            hue: CGFloat(hue / 360),
            saturation: CGFloat(saturation),
            brightness: CGFloat(brightness),
            alpha: 1
        )
    }

    var color: Color { Color(uiColor: uiColor) }

    var hexString: String { uiColor.hexString }
}

extension UIColor {
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "#%02X%02X%02X",
            Int((r * 255).rounded()),
            Int((g * 255).rounded()),
            Int((b * 255).rounded())
        )
    }
}
