//
//  Extensions+UiNavigationController.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation
import SwiftUI

#if os(iOS)
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
#endif
