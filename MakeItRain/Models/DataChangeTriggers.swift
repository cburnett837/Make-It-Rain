//
//  DataChangeTriggers.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/6/25.
//


import SwiftUI

@Observable
class DataChangeTriggers {
    static let shared: DataChangeTriggers = DataChangeTriggers()
    
    var calendarDidChange = false
    var paymentMethodListOrdersDidChange = false
    
    func viewDidChange(_ view: ViewThatTriggeredChange, source: String = #function) {
        switch view {
        case .calendar:
            self.calendarDidChange.toggle()
        case .paymentMethodListOrders:
            self.paymentMethodListOrdersDidChange.toggle()
        }
    }
}
