//
//  NavigationManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import Foundation
import SwiftUI


@Observable
class NavigationManager {
    static let shared: NavigationManager = NavigationManager()
    
    var selection: NavDestination?
    var selectedMonth: NavDestination?
    
    var navPath: Array<NavDestination> = []
    
    var columnVisibility: NavigationSplitViewVisibility = .all
}

enum NavDestination: LocalizedStringKey, Codable, Hashable, Identifiable {
    case january
    case february
    case march
    case april
    case may
    case june
    case july
    case august
    case september
    case october
    case november
    case december
    case lastDecember
    case nextJanuary
    case calendar
    case repeatingTransactions
    case paymentMethods
    case categories
    case keywords
    case search
    case analytics
    case settings
    case placeholderMonth
    case debug
    case plaid
    case toasts
    case more
    case recentReceipts
    
    var id: NavDestination { return self }
    
    var monthNum: Int? {
        switch self {
        case .lastDecember:     0
        case .january:          1
        case .february:         2
        case .march:            3
        case .april:            4
        case .may:              5
        case .june:             6
        case .july:             7
        case .august:           8
        case .september:        9
        case .october:          10
        case .november:         11
        case .december:         12
        case .nextJanuary:      13
        case .placeholderMonth: 100000
        default: nil
        }
    }
    
    var monthActualNum: Int? {
        switch self {
        case .lastDecember:     12
        case .january:          1
        case .february:         2
        case .march:            3
        case .april:            4
        case .may:              5
        case .june:             6
        case .july:             7
        case .august:           8
        case .september:        9
        case .october:          10
        case .november:         11
        case .december:         12
        case .nextJanuary:      1
        case .placeholderMonth: 100000
        default: nil
        }
    }
    
    var displayName: String {
        switch self {
        case .january, .nextJanuary:    "January"
        case .february:                 "February"
        case .march:                    "March"
        case .april:                    "April"
        case .may:                      "May"
        case .june:                     "June"
        case .july:                     "July"
        case .august:                   "August"
        case .september:                "September"
        case .october:                  "October"
        case .november:                 "November"
        case .december, .lastDecember:  "December"
        case .repeatingTransactions:    "Reoccuring Transactions"
        case .paymentMethods:           "Accounts"
        case .categories:               "Categories"
        case .keywords:                 "Rules"
        case .search:                   "Search"
        case .analytics:                "Analytics"
        case .settings:                 "Settings"
        case .debug:                    "Debug"
        case .plaid:                    "Plaid"
        case .placeholderMonth:         ""
        case .toasts:                   "Notifications"
        case .calendar:                 "Calendar"
        case .more:                     "More"
        case .recentReceipts:           "Receipts"
        }
    }
    
    var symbol: String {
        switch self {
        case .january, .nextJanuary:    ""
        case .february:                 ""
        case .march:                    ""
        case .april:                    ""
        case .may:                      ""
        case .june:                     ""
        case .july:                     ""
        case .august:                   ""
        case .september:                ""
        case .october:                  ""
        case .november:                 ""
        case .december, .lastDecember:  ""
        case .repeatingTransactions:    "repeat"
        case .paymentMethods:           "creditcard"
        case .categories:               "books.vertical"
        //case .keywords:                 "textformat.abc.dottedunderline"
        case .keywords:                 "ruler"
        case .search:                   "magnifyingglass"
        case .analytics:                "chart"
        case .settings:                 "gear"
        case .debug:                    "ladybug"
        case .plaid:                    "building.columns"
        case .placeholderMonth:         ""
        case .toasts:                   "bell.badge"
        case .calendar:                 "calendar"
        case .more:                     "ellipsis"
        case .recentReceipts:           "receipt"
        }
    }
    
    static var justMonths: [NavDestination] {
        [.january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december, .lastDecember, .nextJanuary]
    }
    
    static var justAccessorials: [NavDestination] {
        [.repeatingTransactions, .paymentMethods, .categories, .keywords, .search, .analytics, .debug, .plaid, .toasts]
    }
    
    static func getMonthFromInt(_ int: Int) -> NavDestination? {
        switch int {
        case 0:  .lastDecember
        case 1:  .january
        case 2:  .february
        case 3:  .march
        case 4:  .april
        case 5:  .may
        case 6:  .june
        case 7:  .july
        case 8:  .august
        case 9:  .september
        case 10: .october
        case 11: .november
        case 12: .december
        case 13: .nextJanuary
        default: nil
        }
    }
    
    @MainActor @ViewBuilder
    static func view(for destination: NavDestination) -> some View {
        switch destination {
        case .repeatingTransactions:
            RepeatingTransactionsTable()
            
        case .paymentMethods:
            PayMethodsTable()
            
        case .categories:
            CategoriesTable()
            
        case .keywords:
            KeywordsTable()
            
        case .search:
            AdvancedSearchView()
            
        case .analytics:
            Text("analytics")
            
        case .settings:
            SettingsView(showSettings: .constant(true))
            
        case .debug:
            DebugView()
            
        case .plaid:
            PlaidTable()
            
        case .toasts:
            ToastList()
            
        case .recentReceipts:
            RecentReceiptsView()
            
        default:
            EmptyView()
        }
    }
}
