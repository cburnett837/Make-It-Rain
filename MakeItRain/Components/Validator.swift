//
//  PropertyWrappers.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/18/25.
//

import Foundation
import SwiftUI

enum RegexExpression: String {
    case email = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
    case currency = #"^[0-9\-\$\.\,]+$"#
    case positiveCurrency = #"^[0-9\$\.\,]+$"#
    
    case onlyNumbers = #"^[0-9]+$"#
    case onlyDecimals = #"^[0-9\.]+$"#
    
//    var genericMessage: String {
//        switch self {
//        case .email:
//            "Must be a valid email address"
//        case .currency:
//            "Only currency is allowed"
//        case .positiveCurrency:
//            "Only positive currency is allowed"
//        case .onlyNumbers:
//            "Only whole numbers are allowed"
//        case .onlyDecimals:
//            "Only decimal numbers are allowed"
//        }
//    }
}

enum ValidationRule {
    case required(String)
    case regex(RegexExpression, String)
}

// Validation View Modifier
struct ValidationModifier: ViewModifier {
    var value: String
    let rules: [ValidationRule]
    
    @State private var message: String?
    @State private var initialValue: String?
    @State private var ignoreInitial = false
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content
                .onChange(of: value) { oldValue, newValue in
                    /// Check to see if the value is required.
                    let requiredRules = rules.filter { if case .required = $0 { return true } else { return false } }
                    
                    /// if the new value is empty, ignore it, unless it is required.
                    if newValue.isEmpty && requiredRules.isEmpty {
                        message = nil
                        return
                    }
                    
                    /// Prevent evaluating when the field matches the initial value.
                    if !ignoreInitial { guard newValue != initialValue else { return } }
                    
                    /// Ignore when the field has not been changed.
                    ignoreInitial = true
                                        
                    /// Check all the rules. Set the error message for the first matching rule (if applicable).
                    var errorMessage: String?
                    for rule in rules {
                        if let message = validate(rule: rule) {
                            errorMessage = message
                            break
                        }
                    }
                    
                    /// Set the error message if a rule was broken, else invalid the error message so the error view disappears.
                    if let errorMessage = errorMessage {
                        withAnimation { self.message = errorMessage }
                    } else {
                        withAnimation { self.message = nil }
                    }
                }
                /// Set the initlal value when the view appears.
                .task {
                    initialValue = value
                }
            
            if let errorMessage = message {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(height: 20)
                    .animation(.easeInOut(duration: 0.2), value: errorMessage)
            }
            
        }
    }
    
    private func validate(rule: ValidationRule) -> String? {
        switch rule {
            case .required(let message):
                return validateRequired(message: message)
            
            case .regex(let regexExpression, let message):
                return validateRegex(pattern: regexExpression.rawValue, message: message)
        }
    }
    
    private func validateRequired(message: String) -> String? {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return message }
        return nil
    }
    
    private func validateRegex(pattern: String, message: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: value.utf16.count)
        return regex?.firstMatch(in: value, options: [], range: range) == nil ? message : nil
    }
}

extension View {
    func validate(_ value: String, rules: ValidationRule...) -> some View {
        self.modifier(ValidationModifier(value: value, rules: rules))
    }
}
