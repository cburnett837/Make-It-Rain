//
//  NavSidebarPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/1/24.
//

import SwiftUI

#if os(iOS)
struct NavSidebar: View {
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    
    @Binding var selectedDay: CBDay?
    
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        
        VStack {
            List {
                if AppState.shared.methsExist {
                    Section("Months") {
                        let lastDec = calModel.months.filter { $0.enumID == .lastDecember }.first!
                        let nextJan = calModel.months.filter { $0.enumID == .nextJanuary }.first!
                        
                        NavLinkPhone2(destination: .lastDecember, title: "\(lastDec.name) \(lastDec.year)", image: "12.circle")
                        
                        ForEach(calModel.months.filter{![.lastDecember, .nextJanuary].contains($0.enumID)}, id: \.self) { month in
                            NavLinkPhone2(destination: month.enumID, title: month.name, image: "\(month.num).circle")
                        }
                        
                        NavLinkPhone2(destination: .nextJanuary, title: "\(nextJan.name) \(nextJan.year)", image: "1.circle")
                    }
                }
                
                Section("Search") {
                    if AppState.shared.methsExist {
                        NavLinkPhone2(destination: .search, title: "Advanced Search", image: "magnifyingglass")
                    }
                }
                
                Section("Misc") {
                    if AppState.shared.methsExist {
                        NavLinkPhone2(destination: .repeatingTransactions, title: "Reoccuring Transactions", image: "repeat")
                    }
                    
                    NavLinkPhone2(destination: .paymentMethods, title: "Payment Methods", image: "creditcard")
                    
                    if AppState.shared.methsExist {
                        NavLinkPhone2(destination: .categories, title: "Categories", image: "books.vertical")
                        NavLinkPhone2(destination: .keywords, title: "Keywords", image: "textformat.abc.dottedunderline")
                        NavLinkPhone2(destination: .events, title: "Events", image: "beach.umbrella")
                    }
                }
            }
            .listStyle(.plain)
        }
        //.frame(width: getRect().width - 90)
        .standardBackground()
        .frame(maxWidth: .infinity)
    }
}

#endif
