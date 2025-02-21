//
//  DailyWidgetBundle.swift
//  DailyWidget
//
//  Created by Cody Burnett on 2/19/25.
//

import WidgetKit
import SwiftUI

@main
struct DailyWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyWidget()
        DailyWidgetControl()
    }
}
