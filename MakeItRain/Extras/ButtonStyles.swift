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
    internal static var sheetHeader: SheetHeaderButtonStyle { SheetHeaderButtonStyle() }
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
    @State private var buttonColor: Color = Color(.tertiarySystemFill)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonStyle(.plain)
            //.symbolRenderingMode(.hierarchical)
            .foregroundStyle(.gray)
            .imageScale(.small)
            .frame(width: 30, height: 30)
            .foregroundStyle(.gray)
            .background(configuration.isPressed ? Color(.darkGray) : buttonColor)
            .clipShape(Circle())
                                                
            .onHover { buttonColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
            //.scaleEffect(configuration.isPressed ? 1.2 : 1)
            //.animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
