//
//  CustomDecimalKeyboard.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/22/25.
//

import SwiftUI

#if os(iOS)
struct CustomDecimalKeyboard: View {
    
    @Binding var text: String
    
    let columns = Array(repeating: GridItem(spacing: 6), count: 3)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(1...9, id: \.self) { buttonView("\($0)") }
            AppSettings.shared.useWholeNumbers ? buttonView(type: .posNeg) : buttonView(type: .decimalPoint)
            buttonView("0")
            buttonView(type: .delete)
        }
        .padding()
        .if(AppState.shared.isIpad) {
            $0.frame(maxWidth: 400)
        }
    }
    
    @ViewBuilder
    func buttonView(_ value: String = "", type: DecimalKeyboardButtonType = .number) -> some View {
        Button("") {
            switch type {
            case .number:
                text += value
            case .delete:
                if !text.isEmpty {
                    text.removeLast()
                }
            case .decimalPoint:
                text += "."
            case .posNeg:
                Helpers.plusMinus($text)
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        .buttonStyle(.customNumpad(type: type, value: value))
        .buttonRepeatBehavior(.enabled)
    }
}


extension ButtonStyle where Self == CustomNumpadButtonStyle {
    static func customNumpad(type: DecimalKeyboardButtonType, value: String) -> CustomNumpadButtonStyle {
        CustomNumpadButtonStyle(type: type, value: value)
    }
}


struct CustomNumpadButtonStyle: ButtonStyle {
    var type: DecimalKeyboardButtonType
    let value: String
    func makeBody(configuration: Configuration) -> some View {
        Group {
            switch type {
            case .number:
                Text(value)
            case .delete:
                Image(systemName: configuration.isPressed ? "delete.backward.fill" : "delete.backward")
            case .decimalPoint:
                Text(".")
            case .posNeg:
                Image(systemName: "plus.forwardslash.minus")
            }
        }
        .font(.title3)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .contentShape(Rectangle())
        .if(type == .number) {
            $0.background(configuration.isPressed ? Color(.tertiarySystemBackground) : Color(.secondarySystemFill), in: .rect(cornerRadius: 12))
        }
        .animation(configuration.isPressed ? .easeIn(duration: 0.05) : .easeOut(duration: 0.18), value: configuration.isPressed)
        .schemeBasedForegroundStyle()
    }
}

#endif
