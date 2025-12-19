//
//  Extentions+UiView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//


import Foundation
import SwiftUI
import Charts

#if os(iOS)

extension UIView {
    var allSubviews: [UIView] {
        return self.subviews.flatMap({ [$0] + $0.allSubviews })
    }
    
    var viewController: UIViewController? {
        sequence(first: self) { $0.next }
            .compactMap({$0 as? UIViewController})
            .first
    }
}
#endif
