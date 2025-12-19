//
//  DataPoint.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/19/25.
//


import SwiftUI
import Charts

enum CivDataPoint {
    case moneyIn, cashOut, totalSpending, actualSpending, all
    
    var titleString: String {
        switch self {
        case .moneyIn:
            "Money In"
        case .cashOut:
            "Cash Out"
        case .totalSpending:
            "Total Spending"
        case .actualSpending:
            "Actual Spending"
        case .all:
            "All Transactions"
        }
    }
}
