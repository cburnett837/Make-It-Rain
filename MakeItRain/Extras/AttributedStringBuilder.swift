//
//  AttributedStringBuilder.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/5/26.
//

import Foundation
import SwiftUI


extension AttributedString {
    static func build(@AttributedStringBuilder _ content: () -> AttributedString) -> AttributedString {
        content()
    }
}

@resultBuilder
struct AttributedStringBuilder {
    static func buildBlock(_ components: AttributedString...) -> AttributedString {
        components.reduce(into: AttributedString()) { $0.append($1) }
    }

    static func buildExpression(_ expression: String) -> AttributedString {
        AttributedString(expression)
    }

    static func buildExpression(_ expression: AttributedString) -> AttributedString {
        expression
    }

    // if without else
    static func buildOptional(_ component: AttributedString?) -> AttributedString {
        component ?? AttributedString()
    }

    // if / else
    static func buildEither(first component: AttributedString) -> AttributedString {
        component
    }

    static func buildEither(second component: AttributedString) -> AttributedString {
        component
    }

    // loops
    static func buildArray(_ components: [AttributedString]) -> AttributedString {
        components.reduce(into: AttributedString()) { $0.append($1) }
    }
}

extension String {
    func foreground(_ color: Color) -> AttributedString {
        var value = AttributedString(self)
        value.foregroundColor = color
        return value
    }

    func bold() -> AttributedString {
        var value = AttributedString(self)
        value.font = .body.bold()
        return value
    }
}
