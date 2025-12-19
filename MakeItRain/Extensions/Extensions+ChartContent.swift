//
//  Extensions+ChartContent.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//


import Foundation
import SwiftUI
import Charts

extension ChartContent {
    @ChartContentBuilder func `if`<Content: ChartContent>(_ condition: Bool, transform: (Self) -> Content) -> some ChartContent {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}