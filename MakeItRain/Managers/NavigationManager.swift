//
//  NavigationManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import Foundation
import SwiftUI

enum NavDestination: String, Codable, Hashable, Identifiable {
    case january, february, march, april, may, june, july, august, september, october, november, december, lastDecember, nextJanuary, repeatingTransactions, paymentMethods, categories, keywords, search, analytics, events, settings, placeholderMonth, debug, plaid
    
    var id: NavDestination {
        return self
    }
    
    var monthNum: Int? {
        switch self {
        case .lastDecember:
            return 0
        case .january:
            return 1
        case .february:
            return 2
        case .march:
            return 3
        case .april:
            return 4
        case .may:
            return 5
        case .june:
            return 6
        case .july:
            return 7
        case .august:
            return 8
        case .september:
            return 9
        case .october:
            return 10
        case .november:
            return 11
        case .december:
            return 12
        case .nextJanuary:
            return 13
        case .placeholderMonth:
            return 100000
        default:
            return nil
        }
    }
    
    var displayName: String {
        switch self {
        case .january, .nextJanuary:    return "January"
        case .february:                 return "February"
        case .march:                    return "March"
        case .april:                    return "April"
        case .may:                      return "May"
        case .june:                     return "June"
        case .july:                     return "July"
        case .august:                   return "August"
        case .september:                return "September"
        case .october:                  return "October"
        case .november:                 return "November"
        case .december, .lastDecember:  return "December"
        case .repeatingTransactions:    return "Reoccuring Transactions"
        case .paymentMethods:           return "Accounts"
        case .categories:               return "Categories"
        case .keywords:                 return "Rules"
        case .search:                   return "Search"
        case .analytics:                return "Analytics"
        case .events:                   return "Events"
        case .settings:                 return "Settings"
        case .debug:                    return "Debug"
        case .plaid:                    return "Plaid"
        case .placeholderMonth:         return ""
        }
    }
    
    static var justMonths: [NavDestination] {
        [.january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december, .lastDecember, .nextJanuary]
    }
    
    static var justAccessorials: [NavDestination] {
        [.repeatingTransactions, .paymentMethods, .categories, .keywords, .search, .analytics, .events, .debug]
    }
    
    static func getMonthFromInt(_ int: Int) -> NavDestination? {
        switch int {
        case 0:  return .lastDecember
        case 1:  return .january
        case 2:  return .february
        case 3:  return .march
        case 4:  return .april
        case 5:  return .may
        case 6:  return .june
        case 7:  return .july
        case 8:  return .august
        case 9:  return .september
        case 10: return .october
        case 11: return .november
        case 12: return .december
        case 13: return .nextJanuary
        default: return nil
        }
    }
}

@Observable
class NavigationManager {
    static let shared: NavigationManager = NavigationManager()
    
    var selection: NavDestination?
    var selectedMonth: NavDestination?
    
    var navPath: Array<NavDestination> = []
    
    var columnVisibility: NavigationSplitViewVisibility = .all
}
