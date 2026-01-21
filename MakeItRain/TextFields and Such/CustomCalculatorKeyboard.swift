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
                
            AppSettings.shared.useWholeNumbers ? buttonView(type: .posNeg) : buttonView(type: .decimalPoint)
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
                text = result
                //text = format(result)
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
                    /// If the token is a number
                    if case .number(var num) = tokens.last {
                        //var canRemove = true
                        
                        /// Check the last 2 of the number to see if it's a decimal and a number. Remove them accordingly
                        //let lastTwo = num.suffix(2)
                        num.removeLast()
//                        if lastTwo.first == "." && lastTwo.last != "." {
//                            num.removeLast()
//                            num.removeLast(AppSettings.shared.useWholeNumbers ? 2 : 1)
//                            canRemove = false
//                        }
//                        
//                        if canRemove {
//                            num.removeLast()
//                        }
                        
                        if num.isEmpty {
                            tokens.removeLast()
                        } else {
                            tokens[tokens.count - 1] = .number(num)
                        }
                                                
                    } else {
                        /// Remove the operation.
                        tokens.removeLast()
                    }
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
        guard let _ = Double(process) else { return }
        //tokens.append(.number(value))
        tokens.append(.number(process))
        currentNumber = ""
    }

    
    func updateText() {
        //print(tokens)
        var display = tokens.map {
            switch $0 {
            case .number(let n):
                return n
                //return format(n)
                
            case .op(let op):
                return switch op {
                case .add: "+"
                case .subtract: "−"
                case .multiply: "×"
                case .divide: "÷"
                }
            }
        }.joined(separator: " ")
        
        //print("The display is \(display)")
        
        if !currentNumber.isEmpty {
            display += display.isEmpty ? currentNumber : " \(currentNumber)"
        }

        text = display
    }

    
    func format(_ value: Double) -> String {
        AppSettings.shared.useWholeNumbers ? String(Int(value)) : String(value)
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
    case number(String)
    case op(Operator)

    enum Operator {
        case add, subtract, multiply, divide
    }
}


struct CalculatorEngine {
    static func evaluate(tokens: [CalcToken]) -> String? {
        /// `stack` will get replaced as the below loop runs
        var stack = tokens

        func apply(_ ops: [CalcToken.Operator]) {
            var index = 0
            
            /// Loop through each token.
            while index < stack.count {
                guard
                    case .op(let op) = stack[index], /// ...The current token is an operation (not a number).
                    ops.contains(op), /// ...The current token is one of the passed in operations..
                    index > 0, /// ...It's not the first loop.
                    index < stack.count - 1, /// ...It's not the last loop.
                    case .number(let lhsString) = stack[index - 1], /// ...The token before this loop is a number.
                    case .number(let rhsString) = stack[index + 1], /// ...The token after this loop is a number.
                    let lhs = Double(lhsString),
                    let rhs = Double(rhsString)
                else {
                    index += 1
                    continue
                }

                /// Perform the calculation.
                let result: Double
                switch op {
                case .add:       result = lhs + rhs
                case .subtract:  result = lhs - rhs
                case .multiply:  result = lhs * rhs
                case .divide:    result = rhs == 0 ? 0 : lhs / rhs
                }
                
                
                let finalResult = AppSettings.shared.useWholeNumbers ? String(Int(result)) : String(result)
                
                /// Replace both numbers adjacent of the operation, and the operation itself with the calculated number.
                stack.replaceSubrange((index - 1)...(index + 1), with: [.number(finalResult)])
                index = max(index - 1, 0)
            }
        }
        
        /// Perform order of operations (PEMDAS)
        apply([.multiply, .divide])
        apply([.add, .subtract])

        /// At this point, the stack should just be the calculated number.
        if case .number(let value) = stack.first {
            
            if value.first == "-" {
                let returnValue = value.replacing("-", with: "")
                return "-$\(returnValue)"
            } else {
                return "$\(value)"
            }            
        }
        return nil
    }
}

#endif
