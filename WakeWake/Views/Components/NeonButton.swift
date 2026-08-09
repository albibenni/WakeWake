//
//  NeonButton.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct NeonButton: View {
    let title: String
    var iconName: String? = nil
    var color: Color = Color.cyan
    var textColor: Color = .black
    var isFullWidth: Bool = true
    let action: () -> Void

    public init(
        title: String,
        iconName: String? = nil,
        color: Color = Color.cyan,
        textColor: Color = .black,
        isFullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.color = color
        self.textColor = textColor
        self.isFullWidth = isFullWidth
        self.action = action
    }

    public var body: some View {
        Button(action: {
            HapticService.shared.lightImpact()
            action()
        }) {
            HStack(spacing: 8) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundColor(textColor)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: color.opacity(0.6), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PressedScaleButtonStyle())
    }
}

public struct PressedScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
