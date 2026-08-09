//
//  GlassCard.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var borderColor: Color = Color.white.opacity(0.15)
    var backgroundColor: Color = Color.black.opacity(0.4)

    public init(
        cornerRadius: CGFloat = 20,
        borderColor: Color = Color.white.opacity(0.15),
        backgroundColor: Color = Color.black.opacity(0.4),
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    public var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [borderColor, borderColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 6)
    }
}
