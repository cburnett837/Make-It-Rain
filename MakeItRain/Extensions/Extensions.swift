//
//  Extensions.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import Foundation
import SwiftUI
import Charts

extension Notification.Name {
    static let updateCategoryAnalytics = Notification.Name("updateCategoryAnalytics")
}

extension [LayoutSubviews.Element] {
    func maxHeight(_ proposal: ProposedViewSize) -> CGFloat {
        return self.compactMap { view in
            return view.sizeThatFits(proposal).height
        }.max() ?? 0
    }
}
