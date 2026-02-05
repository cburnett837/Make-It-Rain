//
//  ButtonStyles.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/25/24.
//

import Foundation
import SwiftUI

extension ButtonStyle where Self == CodyStandardButtonStyle {
    internal static var codyStandard: CodyStandardButtonStyle { CodyStandardButtonStyle() }
}
extension ButtonStyle where Self == CodyStandardWithHoverButtonStyle {
    internal static var codyStandardWithHover: CodyStandardWithHoverButtonStyle { CodyStandardWithHoverButtonStyle() }
}
extension ButtonStyle where Self == CodyGrowingButtonStyle {
    internal static var codyGrowing: CodyGrowingButtonStyle { CodyGrowingButtonStyle() }
}
extension ButtonStyle where Self == CodyGrowingWithHoverButtonStyle {
    internal static var codyGrowingWithHover: CodyGrowingWithHoverButtonStyle { CodyGrowingWithHoverButtonStyle() }
}
extension ButtonStyle where Self == SheetHeaderButtonStyle {
    internal static var roundMacButton: SheetHeaderButtonStyle { SheetHeaderButtonStyle(horizontalPadding: 0) }
}
extension ButtonStyle where Self == SheetHeaderButtonStyle {
    internal static func roundMacButton(horizontalPadding: CGFloat = 0) -> SheetHeaderButtonStyle { SheetHeaderButtonStyle(horizontalPadding: horizontalPadding) }
}
extension ButtonStyle where Self == AlertButtonStyle {
    internal static var codyAlert: AlertButtonStyle { AlertButtonStyle() }
}

struct CodyStandardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonStyle(.plain)
            .padding(6)
            .padding(.leading, 0)
            .background(Color(.tertiarySystemFill))
            .cornerRadius(6)
    }
}

struct CodyStandardWithHoverButtonStyle: ButtonStyle {
    @State private var buttonColor: Color = Color(.tertiarySystemFill)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonStyle(.plain)
            .padding(6)
            .padding(.leading, 0)
            .background(configuration.isPressed ? Color(.darkGray) : buttonColor)
            .cornerRadius(6)
            .onHover { buttonColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
    }
}

struct CodyGrowingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonStyle(.plain)
            .padding(6)
            .padding(.leading, 0)
            .background(Color(.tertiarySystemFill))
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct CodyGrowingWithHoverButtonStyle: ButtonStyle {
    @State private var buttonColor: Color = Color(.tertiarySystemFill)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonStyle(.plain)
            .padding(6)
            .padding(.leading, 0)
            .background(configuration.isPressed ? Color(.darkGray) : buttonColor)
            .cornerRadius(6)
            .onHover { buttonColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SheetHeaderButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @State private var buttonColor: Color = Color(.tertiarySystemFill)
    var horizontalPadding: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            #if os(macOS)
            .buttonStyle(.plain)
            .foregroundStyle(.gray)
            .imageScale(.large)
            .frame(minWidth: 30, minHeight: 30)
            .foregroundStyle(.gray)
            .padding(.horizontal, horizontalPadding)
            .background(configuration.isPressed ? Color(.darkGray) : buttonColor)
            .clipShape(Capsule())
            #else
            .frame(minWidth: 30, minHeight: 30)
            #endif
            .onHover { buttonColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
            //.scaleEffect(configuration.isPressed ? 1.2 : 1)
            //.animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}



struct AlertButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Material.ultraThinMaterial : Material.ultraThickMaterial)
            //.glassEffect(.regular, in: .rect())
        
            //.scaleEffect(configuration.isPressed ? 1.2 : 1)
            //.animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

