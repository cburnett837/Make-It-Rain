//
//  RootViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI
#if os(macOS)
struct RootViewMac: View {
    //@Local(\.colorTheme) var colorTheme

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
                            
                            ForEach(calModel.months.filter { ![.lastDecember, .nextJanuary].contains($0.enumID) }, id: \.self) { month in
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
                            NavLinkMac(destination: .categories, title: "Categories", image: "books.vertical")
                        }
                        
                        NavLinkMac(destination: .paymentMethods, title: "Accounts", image: "creditcard")
                        
                        if AppState.shared.methsExist {
                            NavLinkMac(destination: .events, title: "Events", image: "beach.umbrella")
                            NavLinkMac(destination: .repeatingTransactions, title: "Reoccuring Transactions", image: "repeat")
                            NavLinkMac(destination: .keywords, title: "Rules", image: "textformat.abc.dottedunderline")
                            
                            if AppState.shared.user?.id == 1 {
                                NavLinkMac(destination: .debug, title: "Debug", image: "ladybug")
                                    
                            }
                        }
                        
                        //NavLinkMac(destination: .plaid, title: "Plaid", image: "list.bullet")
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
                    //Button("Logout", action: funcModel.logout)
                    
                    Button("Logout") {
                        Task {
                            await funcModel.logout()
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 15)
            }
            //.toolbarBackground(Color.darkGray2)
            //.background(Color.darkGray2)
        } detail: {
            switch navManager.selection {
            case .january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december, .lastDecember, .nextJanuary:
                CalendarViewMac(enumID: navManager.selection!)
                
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
                
            case .debug:
                DebugView()
                
            case .plaid:
                EmptyView()
                
            case .none, .placeholderMonth:
                Text("Invalid Selection")
            }
        }
        //.toolbarBackground(Color.darkGray2)
        //.background(Color.darkGray2)
        .tint(Color.theme)
        .toast()
    }
}

#endif
