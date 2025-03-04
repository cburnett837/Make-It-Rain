//
//  RootViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI
#if os(macOS)
struct RootViewMac: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description

    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
            
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        @Bindable var appState = AppState.shared
        
        NavigationSplitView {
            VStack {
                List(selection: $navManager.selection) {
                    if AppState.shared.methsExist {
                        Section("Year") {
                            YearPicker()
                        }
                        
                        Section("Months") {
                            let lastDec = calModel.months.filter { $0.enumID == .lastDecember }.first!
                            NavLinkMac(destination: lastDec.enumID, title: lastDec.name, image: "12.circle")
                                .italic()
                                                                                    
                            ForEach(calModel.months.filter{![.lastDecember, .nextJanuary].contains($0.enumID)}, id: \.self) { month in
                                NavLinkMac(destination: month.enumID, title: month.name, image: "\(month.num).circle")
                                
                            }
                                                        
                            let nextJan = calModel.months.filter { $0.enumID == .nextJanuary }.first!
                            NavLinkMac(destination: nextJan.enumID, title: nextJan.name, image: "1.circle")
                                .italic()
                        }
                    }
                    
                    Section("Search") {
                        if AppState.shared.methsExist {
                            NavLinkMac(destination: .search, title: "Advanced Search", image: "magnifyingglass")
                        }
                    }
                    
                    Section("More") {
                        if AppState.shared.methsExist {
                            NavLinkMac(destination: .repeatingTransactions, title: "Reoccuring Transactions", image: "repeat")
                        }
                        
                        NavLinkMac(destination: .paymentMethods, title: "Payment Methods", image: "creditcard")
                        
                        if AppState.shared.methsExist {
                            NavLinkMac(destination: .categories, title: "Categories", image: "books.vertical")
                            NavLinkMac(destination: .keywords, title: "Keywords", image: "textformat.abc.dottedunderline")
                            NavLinkMac(destination: .events, title: "Events", image: "beach.umbrella")
                        }
                    }
                }
            }
            
            Spacer()
            /// removed because of flashing when the view loads
            #warning("PUT ME BACK")
//
//            if LoadingManager.shared.showLoadingBar {
//                ProgressView(value: LoadingManager.shared.downloadAmount, total: 150)
//                    .padding(.horizontal, 12)
//            }
            
            HStack {
                Spacer()
                Button("Logout", action: funcModel.logout)
                Spacer()
            }
            .padding(.bottom, 15)
            
        } detail: {
            switch navManager.selection {
            case .january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december, .lastDecember, .nextJanuary:
                CalendarViewMac()
                
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
                Text("Analytics")
                
            case .events:
                EventsTable()
                
            case .settings:
                Text("Settings")
                
            case .none, .placeholderMonth:
               EmptyView()
            }
        }
        .tint(Color.fromName(appColorTheme))
        .toast()
    }
}

#endif
