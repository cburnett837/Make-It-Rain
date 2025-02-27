//
//  NavSidebarPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/1/24.
//

import SwiftUI

#if os(iOS)
struct NavSidebarNEW: View {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description


    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Namespace private var monthNavigationNamespace
    
    @Binding var selectedDay: CBDay?
    
    let threeColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: 3)
    //let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 5, alignment: .top), count: 7)
    
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        
        VStack {
            List {
                if AppState.shared.methsExist {
                    Section {
                        Grid {
                            GridRow(alignment: .top) {
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .lastDecember}.first!)
                                
                            }
                            GridRow(alignment: .top) {
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .january}.first!)
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .february}.first!)
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .march}.first!)
                            }
                            GridRow(alignment: .top) {
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .april}.first!)
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .may}.first!)
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .june}.first!)
                            }
                            GridRow(alignment: .top) {
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .july}.first!)
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .august}.first!)
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .september}.first!)
                            }
                            GridRow(alignment: .top) {
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .october}.first!)
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .november}.first!)
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .december}.first!)
                            }
                            GridRow(alignment: .top) {
                                MonthNavigationView(month: calModel.months.filter {$0.enumID == .nextJanuary}.first!)
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                            }
                        }
                    } header: {
                        Menu {
                            if (![calModel.sYear-1, calModel.sYear, calModel.sYear+1].contains(AppState.shared.todayYear)) {
                                Section {
                                    Button("Now") {
                                        calModel.sYear = AppState.shared.todayYear
                                    }
                                }
                            }

                            
                            Section {
                                Picker("", selection: $calModel.sYear) {
                                    var years: [Int] {
                                        [calModel.sYear-1, calModel.sYear, calModel.sYear+1]
                                    }
                                    ForEach(years, id: \.self) {
                                        Text(String($0))
                                    }
                                }
                            }
                           
                            
                            
                            Section {
                                Picker("All Years", selection: $calModel.sYear) {
                                    var years: [Int] { Array(2000...2099).map { $0 } }
                                    ForEach(years, id: \.self) {
                                        Text(String($0))
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            
                        } label: {
                            Text("\(String(calModel.sYear))")
                                .font(.title)
                                .if(AppState.shared.todayYear == calModel.sYear) {
                                    $0
                                        .foregroundStyle(Color.fromName(appColorTheme))
                                        .bold()
                                }
                        }
                        
//                        Picker("Year", selection: $calModel.sYear) {
//                            ForEach(years, id: \.self) {
//                                Text(String($0))
//                            }
//                        }
//                        .pickerStyle(.menu)
                    }
                }
                
                Section("Search") {
                    if AppState.shared.methsExist {
                        NavLinkPhone(destination: .search, title: "Advanced Search", image: "magnifyingglass")
                    }
                }
                
                Section("Misc") {
                    if AppState.shared.methsExist {
                        NavLinkPhone(destination: .repeatingTransactions, title: "Reoccuring Transactions", image: "repeat")
                    }
                    
                    NavLinkPhone(destination: .paymentMethods, title: "Payment Methods", image: "creditcard")
                    
                    if AppState.shared.methsExist {
                        NavLinkPhone(destination: .categories, title: "Categories", image: "books.vertical")
                        NavLinkPhone(destination: .keywords, title: "Keywords", image: "textformat.abc.dottedunderline")
                        NavLinkPhone(destination: .events, title: "Events", image: "beach.umbrella")
                    }
                }
            }
            .listStyle(.plain)
        }
        .padding(.top, 10)
        //.frame(width: getRect().width - 90)
        .standardBackground()
        .frame(maxWidth: .infinity)
    }
}


struct MonthNavigationView: View {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    @Namespace private var monthNavigationNamespace
    let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .top), count: 7)
    
    @Bindable var month: CBMonth
    
    var body: some View {
        Button {
            NavigationManager.shared.navPath = [month.enumID]
        } label: {
            VStack(alignment: .leading) {
                Group {
                    if month.enumID == .lastDecember || month.enumID == .nextJanuary {
                        Text("\(month.abbreviatedName) \(String(month.year))")
                    } else {
                        Text(month.abbreviatedName)
                    }
                }
                .font(.title3)
                .bold()
                .if(AppState.shared.todayMonth == month.actualNum && AppState.shared.todayYear == month.year) {
                    $0.foregroundStyle(Color.fromName(appColorTheme))
                }
                
                
                LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
                    ForEach($month.days) { $day in
                        Group {
                            if day.date == nil {
                                Text("")
                                    .font(.caption2)
                            } else {
                                Text("\(day.dateComponents?.day ?? 0)")
                                    .font(.caption2)
                                    .if(AppState.shared.todayDay == (day.dateComponents?.day ?? 0) && AppState.shared.todayMonth == month.actualNum && AppState.shared.todayYear == month.year) {
                                        $0
                                        .bold()
                                        .foregroundStyle(Color.fromName(appColorTheme))
                                    }
                            }
                        }
                        .padding(.bottom, 4)
                        
                    }
                }
            }
            //.matchedTransitionSource(id: month.enumID, in: monthNavigationNamespace)
        }
        .padding(.bottom, 10)
        .buttonStyle(.plain)
    }
}


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
                        
                        NavLinkPhone(destination: .lastDecember, title: "\(lastDec.name) \(lastDec.year)", image: "12.circle")
                        
                        ForEach(calModel.months.filter{![.lastDecember, .nextJanuary].contains($0.enumID)}, id: \.self) { month in
                            NavLinkPhone(destination: month.enumID, title: month.name, image: "\(month.num).circle")
                        }
                        
                        NavLinkPhone(destination: .nextJanuary, title: "\(nextJan.name) \(nextJan.year)", image: "1.circle")
                    }
                }
                
                Section("Search") {
                    if AppState.shared.methsExist {
                        NavLinkPhone(destination: .search, title: "Advanced Search", image: "magnifyingglass")
                    }
                }
                
                Section("Misc") {
                    if AppState.shared.methsExist {
                        NavLinkPhone(destination: .repeatingTransactions, title: "Reoccuring Transactions", image: "repeat")
                    }
                    
                    NavLinkPhone(destination: .paymentMethods, title: "Payment Methods", image: "creditcard")
                    
                    if AppState.shared.methsExist {
                        NavLinkPhone(destination: .categories, title: "Categories", image: "books.vertical")
                        NavLinkPhone(destination: .keywords, title: "Keywords", image: "textformat.abc.dottedunderline")
                        NavLinkPhone(destination: .events, title: "Events", image: "beach.umbrella")
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
