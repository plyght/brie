import SwiftUI
import AppKit

struct IconView: View {
    let iconName: String
    
    var body: some View {
        Group {
            if NSImage(systemSymbolName: iconName, accessibilityDescription: nil) != nil {
                Image(systemName: iconName)
                    .font(.system(size: 14))
            } else {
                Text(iconName)
                    .font(.system(size: 14))
            }
        }
    }
}

