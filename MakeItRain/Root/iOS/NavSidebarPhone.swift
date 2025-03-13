//
//  NavSidebarPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/1/24.
//

import SwiftUI

#if os(iOS)
struct NavSidebar: View {
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description

    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Namespace private var monthNavigationNamespace
    
    @Binding var selectedDay: CBDay?
    //@Binding var showMonth: Bool
    
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        
        VStack(spacing: 0) {
            List {
                fakeNavHeader
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .standardNavBackground()
                
                if AppState.shared.methsExist {
                    Group {
                        if AppState.shared.isIpad {
                            iPadGrid
                        } else {
                            iPhoneGrid
                        }
                    }
                    .listRowSeparator(.hidden)
                    .standardNavRowBackground()
                }
                
                Section("More") {
                    if AppState.shared.methsExist {
                        NavLinkPhone(destination: .repeatingTransactions, title: "Reoccuring Transactions", image: "repeat")
                            .listRowSeparator(.hidden)
                    }
                    
                    NavLinkPhone(destination: .paymentMethods, title: "Payment Methods", image: "creditcard")
                        .listRowSeparator(.hidden)
                    
                    if AppState.shared.methsExist {
                        NavLinkPhone(destination: .categories, title: "Categories", image: "books.vertical")
                            .listRowSeparator(.hidden)
                        NavLinkPhone(destination: .keywords, title: "Keywords", image: "textformat.abc.dottedunderline")
                            .listRowSeparator(.hidden)
                        NavLinkPhone(destination: .events, title: "Events", image: "beach.umbrella")
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
        }
        .standardNavBackground()
        .frame(maxWidth: .infinity)
    }
    
    
    
    var fakeNavHeader: some View {
        HStack {
            @Bindable var calModel = calModel
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
                VStack(alignment: .leading, spacing: 0) {
                    Text("Make It Rain")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .lineLimit(1)
                    
                    HStack(spacing: 2) {
                        Text("\(String(calModel.sYear))")
                        //Image(systemName: "chevron.right")
                    }
                    .font(.title)
                    .bold()
                    .if(AppState.shared.todayYear == calModel.sYear) {
                        $0
                        .foregroundStyle(Color.fromName(appColorTheme))
                    }
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .contentShape(Rectangle())
                }
            }
            .layoutPriority(1)
            .padding(.leading, 16)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            
//            HStack(spacing: 15) {
//                Button {
//                    var prev: NavDestination? {
//                        switch calModel.sMonth.enumID {
//                        case .lastDecember: return nil
//                        case .january:      return .lastDecember
//                        case .february:     return .january
//                        case .march:        return .february
//                        case .april:        return .march
//                        case .may:          return .april
//                        case .june:         return .may
//                        case .july:         return .june
//                        case .august:       return .july
//                        case .september:    return .august
//                        case .october:      return .september
//                        case .november:     return .october
//                        case .december:     return .november
//                        case .nextJanuary:  return .december
//                        default:            return nil
//                        }
//                    }
//
//                    if let prev = prev {
//                        //NavigationManager.shared.navPath = [prev]
//                        NavigationManager.shared.monthSelection = prev
//                        SwipeToChangeMonthsTip.didChangeViaSwipe = true
//                        swipeToChangeMonthsTip.invalidate(reason: .actionPerformed)
//                    }
//                } label: {
//                    Image(systemName: "chevron.left")
//                }
//
//                Button {
//                    var next: NavDestination? {
//                        switch calModel.sMonth.enumID {
//                        case .lastDecember: return .january
//                        case .january:      return .february
//                        case .february:     return .march
//                        case .march:        return .april
//                        case .april:        return .may
//                        case .may:          return .june
//                        case .june:         return .july
//                        case .july:         return .august
//                        case .august:       return .september
//                        case .september:    return .october
//                        case .october:      return .november
//                        case .november:     return .december
//                        case .december:     return .nextJanuary
//                        case .nextJanuary:  return nil
//                        default:            return nil
//                        }
//                    }
//
//                    if let next = next {
//                        //NavigationManager.shared.navPath = [next]
//                        NavigationManager.shared.monthSelection = next
//                        SwipeToChangeMonthsTip.didChangeViaSwipe = true
//                        swipeToChangeMonthsTip.invalidate(reason: .actionPerformed)
//                    }
//                } label: {
//                    Image(systemName: "chevron.right")
//                }
//            }
//            .padding(.trailing, 16)
//            .padding(.bottom, 4)
            
            

            
        }
        //.background(.ultraThinMaterial)
        .padding(.bottom, 10)
        .contentShape(Rectangle())
        
        
//        .gesture(DragGesture()
//            .onEnded { value in
//                let dragAmount = value.translation.width
//                if dragAmount < -200 {
//                    var next: NavDestination? {
//                        switch calModel.sMonth.enumID {
//                        case .lastDecember: return .january
//                        case .january:      return .february
//                        case .february:     return .march
//                        case .march:        return .april
//                        case .april:        return .may
//                        case .may:          return .june
//                        case .june:         return .july
//                        case .july:         return .august
//                        case .august:       return .september
//                        case .september:    return .october
//                        case .october:      return .november
//                        case .november:     return .december
//                        case .december:     return .nextJanuary
//                        case .nextJanuary:  return nil
//                        default:            return nil
//                        }
//                    }
//
//                    if let next = next {
//                        NavigationManager.shared.monthSelection = next
//                        //NavigationManager.shared.navPath = [next]
//                        SwipeToChangeMonthsTip.didChangeViaSwipe = true
//                        swipeToChangeMonthsTip.invalidate(reason: .actionPerformed)
//                    }
//
//                } else if dragAmount > 200 {
//                    var prev: NavDestination? {
//                        switch calModel.sMonth.enumID {
//                        case .lastDecember: return nil
//                        case .january:      return .lastDecember
//                        case .february:     return .january
//                        case .march:        return .february
//                        case .april:        return .march
//                        case .may:          return .april
//                        case .june:         return .may
//                        case .july:         return .june
//                        case .august:       return .july
//                        case .september:    return .august
//                        case .october:      return .september
//                        case .november:     return .october
//                        case .december:     return .november
//                        case .nextJanuary:  return .december
//                        default:            return nil
//                        }
//                    }
//
//                    if let prev = prev {
//                        NavigationManager.shared.monthSelection = prev
//                        //NavigationManager.shared.navPath = [prev]
//                        SwipeToChangeMonthsTip.didChangeViaSwipe = true
//                        swipeToChangeMonthsTip.invalidate(reason: .actionPerformed)
//                    }
//                }
//            }
//        )
    }
    
    
    var iPhoneGrid: some View {
        Grid {
            GridRow(alignment: .top) {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                MonthNavigationLink(enumID: .lastDecember)
                
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .january)
                MonthNavigationLink(enumID: .february)
                MonthNavigationLink(enumID: .march)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .april)
                MonthNavigationLink(enumID: .may)
                MonthNavigationLink(enumID: .june)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .july)
                MonthNavigationLink(enumID: .august)
                MonthNavigationLink(enumID: .september)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .october)
                MonthNavigationLink(enumID: .november)
                MonthNavigationLink(enumID: .december)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .nextJanuary)
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
            }
        }
    }
    
    var iPadGrid: some View {
        Grid {
            GridRow(alignment: .top) {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                MonthNavigationLink(enumID: .lastDecember)
                
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .january)
                MonthNavigationLink(enumID: .february)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .march)
                MonthNavigationLink(enumID: .april)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .may)
                MonthNavigationLink(enumID: .june)
                
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .july)
                MonthNavigationLink(enumID: .august)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .september)
                MonthNavigationLink(enumID: .october)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .november)
                MonthNavigationLink(enumID: .december)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .nextJanuary)
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
            }
        }
    }
    
}




struct NavSidebarOG: View {
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
