//
//  CustomCalculatorKeyboard.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/16/25.
//

//
//  CustomDecimalKeyboard.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/22/25.
//

import SwiftUI

#if os(iOS)
struct CustomCalculatorKeyboard: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Binding var text: String
    
    @State private var tokens: [CalcToken] = []
    @State private var currentNumber: String = ""
    
    let columns = Array(repeating: GridItem(spacing: 6), count: 4)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(7...9, id: \.self) { buttonView("\($0)") }
            buttonView(type: .divide)

            ForEach(4...6, id: \.self) { buttonView("\($0)") }
            buttonView(type: .multiply)

            ForEach(1...3, id: \.self) { buttonView("\($0)") }
            buttonView(type: .subtract)
                
            useWholeNumbers ? buttonView(type: .posNeg) : buttonView(type: .decimalPoint)
            buttonView("0")
            buttonView(type: .delete)
            buttonView(type: .add)
        }
        .padding()
        .if(AppState.shared.isIpad) {
            $0.frame(maxWidth: 400)
        }
        .onChange(of: text) { oldValue, newValue in
            if text.isEmpty {
                currentNumber = ""
                tokens.removeAll()
            }
        }
        .onDisappear {
            commitCurrentNumber()

            if let result = CalculatorEngine.evaluate(tokens: tokens) {
                text = format(result)
                tokens = [.number(result)]
            }
        }
    }
    
    
    @ViewBuilder
    func buttonView(_ value: String = "", type: CalculatorKeyboardButtonType = .number) -> some View {
        Button("") {
            switch type {
            case .number:
                currentNumber.append(value)
                
            case .delete:
                if !currentNumber.isEmpty {
                    currentNumber.removeLast()
                } else if !tokens.isEmpty {
                    tokens.removeLast()
                }
                
            case .decimalPoint:
                guard !currentNumber.contains(".") else { return }
                currentNumber.append(".")
                
            case .posNeg:
                if currentNumber.hasPrefix("-") {
                    currentNumber.removeFirst()
                } else {
                    currentNumber = "-" + currentNumber
                }
                
            case .divide:
                commitCurrentNumber()
                tokens.append(.op(.divide))
                
            case .multiply:
                commitCurrentNumber()
                tokens.append(.op(.multiply))
                
            case .subtract:
                commitCurrentNumber()
                tokens.append(.op(.subtract))
                
            case .add:
                commitCurrentNumber()
                tokens.append(.op(.add))
            }
            
            updateText()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .buttonStyle(.customCalculator(type: type, value: value))
        .buttonRepeatBehavior(.enabled)
    }
    
    
    func commitCurrentNumber() {
        let process: String = currentNumber.replacing("$", with: "")
        guard let value = Double(process) else { return }
        tokens.append(.number(value))
        currentNumber = ""
    }

    
    func updateText() {
        var display = tokens.map {
            switch $0 {
            case .number(let n):
                return format(n)
                
            case .op(let op):
                return switch op {
                case .add: "+"
                case .subtract: "−"
                case .multiply: "×"
                case .divide: "÷"
                }
            }
        }.joined(separator: " ")

        if !currentNumber.isEmpty {
            display += display.isEmpty ? currentNumber : " \(currentNumber)"
        }

        text = display
    }

    
    func format(_ value: Double) -> String {
        useWholeNumbers ? String(Int(value)) : String(value)
    }
}

extension ButtonStyle where Self == CustomCalculatorButtonStyle {
    static func customCalculator(type: CalculatorKeyboardButtonType, value: String) -> CustomCalculatorButtonStyle {
        CustomCalculatorButtonStyle(type: type, value: value)
    }
}


struct CustomCalculatorButtonStyle: ButtonStyle {
    var type: CalculatorKeyboardButtonType
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
            case .divide:
                Image(systemName: "divide")
            case .multiply:
                Image(systemName: "multiply")
            case .subtract:
                Image(systemName: "minus")
            case .add:
                Image(systemName: "plus")
            }
        }
        .font(.title3)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .contentShape(Rectangle())
        .if(type == .number || type == .delete || type == .posNeg || type == .decimalPoint) {
            $0.background(configuration.isPressed ? Color(.tertiarySystemBackground) : Color(.secondarySystemFill), in: .rect(cornerRadius: 12))
        }
        .if([.divide, .multiply, .subtract, .add].contains(type)) {
            $0.background(configuration.isPressed ? Color(.orange).darker(by: 10) : Color(.orange), in: .rect(cornerRadius: 12))
        }
        .animation(configuration.isPressed ? .easeIn(duration: 0.05) : .easeOut(duration: 0.18), value: configuration.isPressed)
        .schemeBasedForegroundStyle()
    }
}

enum CalcToken: Equatable {
    case number(Double)
    case op(Operator)

    enum Operator {
        case add, subtract, multiply, divide
    }
}

struct CalculatorEngine {
    static func evaluate(tokens: [CalcToken]) -> Double? {
        var stack = tokens

        func apply(_ ops: [CalcToken.Operator]) {
            var index = 0
            while index < stack.count {
                guard
                    case .op(let op) = stack[index],
                    ops.contains(op),
                    index > 0,
                    index < stack.count - 1,
                    case .number(let lhs) = stack[index - 1],
                    case .number(let rhs) = stack[index + 1]
                else {
                    index += 1
                    continue
                }

                let result: Double
                switch op {
                case .add:       result = lhs + rhs
                case .subtract:  result = lhs - rhs
                case .multiply:  result = lhs * rhs
                case .divide:    result = rhs == 0 ? 0 : lhs / rhs
                }

                stack.replaceSubrange((index - 1)...(index + 1), with: [.number(result)])
                index = max(index - 1, 0)
            }
        }

        apply([.multiply, .divide])
        apply([.add, .subtract])

        if case .number(let value) = stack.first {
            return value
        }
        return nil
    }
}

#endif
