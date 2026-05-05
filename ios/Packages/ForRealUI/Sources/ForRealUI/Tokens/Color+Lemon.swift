import SwiftUI

public extension Color {
    /// Drenched primary surface. The fax IS this color.
    static let zestyLemon  = Color(red: 1.00, green: 1.00, blue: 0.40)   // #FFFF66
    /// One step quieter — claim card backgrounds.
    static let lemonCream  = Color(red: 1.00, green: 0.898, blue: 0.40)  // #FFE566
    /// Tertiary surfaces, dividers, inactive states.
    static let lemonSage   = Color(red: 0.839, green: 0.835, blue: 0.545) // #D6D58B
    /// Deep end of the same hue family — grounded chrome.
    static let oliveAnchor = Color(red: 0.702, green: 0.702, blue: 0.278) // #B3B347
    /// Body type. Warm near-black. Explicitly NOT #000.
    static let lemonCharcoal = Color(red: 0.118, green: 0.106, blue: 0.082) // ~OKLCH 18% L tinted toward yellow
}
