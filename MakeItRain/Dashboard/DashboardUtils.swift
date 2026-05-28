//
//  DashboardUtils.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardUtils {
    static func summarizeCategories(_ categories: [CBCategory]) -> [CBCategory] {
        let groupedCats = Dictionary(grouping: categories, by: \.id)

        return groupedCats.values.map { related in
            let new = CBCategory()
            new.setFromAnotherInstance(category: related[0])

            new.allAmounts = DashboardAmounts()
            new.debitAmounts = DashboardAmounts()
            new.creditAmounts = DashboardAmounts()

            new.budgetAmount = related.map { $0.budgetAmount }.reduce(0.0, +)

            for cat in related {
                new.allAmounts?.add(cat.allAmounts)
                new.debitAmounts?.add(cat.debitAmounts)
                new.creditAmounts?.add(cat.creditAmounts)
            }

            return new
        }
        .sorted(by: Helpers.categorySorter())
    }

    static func summarizeGroups(_ groups: [CBCategoryGroup]) -> [CBCategoryGroup] {
        let groupedGroups = Dictionary(grouping: groups, by: \.id)

        return groupedGroups.values.map { relatedGroups in
            let newGroup = CBCategoryGroup()
            newGroup.setFromAnotherInstance(group: relatedGroups[0])

            newGroup.allAmounts = DashboardAmounts()
            newGroup.debitAmounts = DashboardAmounts()
            newGroup.creditAmounts = DashboardAmounts()

            newGroup.budgetAmount = relatedGroups.map { $0.budgetAmount }.reduce(0.0, +)

            for group in relatedGroups {
                newGroup.allAmounts?.add(group.allAmounts)
                newGroup.debitAmounts?.add(group.debitAmounts)
                newGroup.creditAmounts?.add(group.creditAmounts)
            }

            newGroup.categories = summarizeCategories(
                relatedGroups.flatMap(\.categories)
            )

            return newGroup
        }
    }

    static func incomeAmount(for cat: CBCategory) -> Double {
        if cat.isRegularIncome {
            return cat.allAmounts?.regularIncome ?? 0.0
        } else {
            return cat.allAmounts?.irregularIncome ?? 0.0
        }
    }

    static func categoryOwningXRange(
        selectedXAmount: Double,
        categories: [CBCategory],
        amountForCategory: (CBCategory) -> Double
    ) -> CBCategory? {
        var runningTotal = 0.0
        
        for category in categories {
            let amount = amountForCategory(category)
            
            guard amount > 0 else { continue }
            
            let start = runningTotal
            let end = runningTotal + amount
            
            if selectedXAmount >= start && selectedXAmount < end {
                return category
            }
            
            runningTotal = end
        }
        
        return nil
    }
}