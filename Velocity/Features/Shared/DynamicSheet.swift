//
//  DynamicSheet.swift
//  Velocity
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum MapLayoutConstants {
    static let minVisibleMapHeight: CGFloat = 500
}

enum DynamicSheetLayout {
    /// Max sheet height: at most 65% of screen and at least `minVisibleMapHeight` of map kept visible below the status area.
    static func capHeight() -> CGFloat {
        #if canImport(UIKit)
        guard
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })
        else {
            return UIScreen.main.bounds.height * 0.65
        }
        let h = window.bounds.height
        let top = window.safeAreaInsets.top
        return min(h * 0.65, h - top - MapLayoutConstants.minVisibleMapHeight)
        #else
        return 620
        #endif
    }

    static func homeBottomSafeInset() -> CGFloat {
        #if canImport(UIKit)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 0
        #else
        return 0
        #endif
    }
}

private struct DynamicSheetMeasuredContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct DynamicSheet<Content: View>: View {
    let animation: Animation
    let onPresentedHeightChange: ((CGFloat) -> Void)?
    private let content: Content

    @State private var sheetHeight: CGFloat = .zero
    @State private var contentIntrinsicHeight: CGFloat = 0
    @State private var hasMeasuredContent = false

    init(
        animation: Animation = .easeInOut(duration: 0.22),
        onPresentedHeightChange: ((CGFloat) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.animation = animation
        self.onPresentedHeightChange = onPresentedHeightChange
        self.content = content()
    }

    private var cap: CGFloat {
        max(DynamicSheetLayout.capHeight(), 120)
    }

    private var clampedDetent: CGFloat {
        guard hasMeasuredContent, contentIntrinsicHeight > 0 else { return cap }
        return min(contentIntrinsicHeight, cap)
    }

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: .infinity, alignment: .top)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: DynamicSheetMeasuredContentHeightKey.self,
                            value: geo.size.height
                        )
                    }
                )
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: clampedDetent)
        .onPreferenceChange(DynamicSheetMeasuredContentHeightKey.self) { height in
            guard height > 0 else { return }
            if abs(height - contentIntrinsicHeight) > 0.5 {
                contentIntrinsicHeight = height
                hasMeasuredContent = true
            }
            let detent = min(height, cap)
            withAnimation(animation) {
                sheetHeight = detent
            }
            onPresentedHeightChange?(detent + DynamicSheetLayout.homeBottomSafeInset())
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
