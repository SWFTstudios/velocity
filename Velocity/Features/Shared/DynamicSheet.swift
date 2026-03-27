//
//  DynamicSheet.swift
//  Velocity
//

import SwiftUI

struct DynamicSheet<Content: View>: View {
    let maxHeight: CGFloat
    let animation: Animation
    @ViewBuilder var content: Content

    @State private var sheetHeight: CGFloat = .zero

    init(
        maxHeight: CGFloat = 620,
        animation: Animation = .easeInOut(duration: 0.22),
        @ViewBuilder content: () -> Content
    ) {
        self.maxHeight = maxHeight
        self.animation = animation
        self.content = content()
    }

    var body: some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                let measured = min(newSize.height, maxHeight)
                guard measured > 0 else { return }
                withAnimation(animation) {
                    sheetHeight = measured
                }
            }
            .modifier(DynamicSheetHeightModifier(height: sheetHeight))
    }
}

private struct DynamicSheetHeightModifier: ViewModifier, Animatable {
    var height: CGFloat

    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }

    func body(content: Content) -> some View {
        content
            .presentationDetents(height == .zero ? [.medium] : [.height(height)])
            .presentationDragIndicator(.visible)
    }
}

