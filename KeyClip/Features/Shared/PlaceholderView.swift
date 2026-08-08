//
//  PlaceholderView.swift
//  KeyClip
//

import SwiftUI

/// Generic "Coming soon" stand-in for tabs not yet built (M2+). Wiring in the
/// real view later is a one-line switch-case swap in `RootTabView`.
struct PlaceholderView: View {
    let tab: FeatureTab

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: tab.systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(tab.title)
                .font(.title2)
                .fontWeight(.semibold)
            Text("Coming soon")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
