//
//  Extensions+Array.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}



extension Array where Element == CBPaymentMethod {
    func getAmount(for date: Date) -> Double {
        return self
            .flatMap { $0.breakdowns }
            .filter { Calendar.current.isDate(date, equalTo: $0.date, toGranularity: .month) }
            .map { $0.income }
            .reduce(0, +)
    }
}


extension Array where Element: FloatingPoint {
    func average() -> Element {
        reduce(0, +) / Element(count)
    }
}

