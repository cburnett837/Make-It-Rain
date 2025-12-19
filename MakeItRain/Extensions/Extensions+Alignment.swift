//
//  Extensions+Alignment.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation
import SwiftUI

extension VerticalAlignment {
    enum CircleAndTitle: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.top]
        }
    }
    
    static let circleAndTitle = VerticalAlignment(CircleAndTitle.self)
}


extension HorizontalAlignment {
    enum LabelAndField: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.leading]
        }
    }
    
    static let customHorizontalAlignment = HorizontalAlignment(LabelAndField.self)
}
