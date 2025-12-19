//
//  Extensions+UiColor.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit

extension UIColor {
    public var lightVariant: UIColor {
        resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }
    public var darkVariant: UIColor {
        resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
    }
    public var asColor: Color {
        Color(self)
    }
}
#endif




