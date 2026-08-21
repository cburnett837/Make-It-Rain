//
//  NavSidebarPad.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/24/25.
//

import SwiftUI


struct MaxNavHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
struct MaxNavWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#if os(iOS)
struct NavSidebarPad: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    
    //@Binding var showMonth: Bool
    
    @State private var linkWidth: CGFloat = 20.0
    @State private var linkHeight: CGFloat = 20.0
    @State private var hasDoneInitialScrollToThisMonth = false
    @State private var calendarNavPath = NavigationPath()

    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    Group {
                        CalendarNavGridHeader(calendarNavPath: $calendarNavPath)
                        
                        if AppState.shared.methsExist {
                            iPadGrid
                        }
                    }
                    .padding(.horizontal, 15)
                    
                    VStack(spacing: 0) {
                        Section {
                            if AppState.shared.methsExist {
                                NavLinkPad(destination: .categories, linkWidth: linkWidth, linkHeight: linkHeight)
                            }
                            
                            NavLinkPad(destination: .paymentMethods, linkWidth: linkWidth, linkHeight: linkHeight)
                        }
                        
                        if AppState.shared.methsExist {
                            Section {
                                NavLinkPad(destination: .repeatingTransactions, linkWidth: linkWidth, linkHeight: linkHeight)
                                NavLinkPad(destination: .keywords, linkWidth: linkWidth, linkHeight: linkHeight)
                                NavLinkPad(destination: .recentReceipts, linkWidth: linkWidth, linkHeight: linkHeight)
                            }
                            
                            Section {
                                NavLinkPad(destination: .plaid, linkWidth: linkWidth, linkHeight: linkHeight)
                            }
                            
                            Section {
                                NavLinkPad(destination: .toasts, linkWidth: linkWidth, linkHeight: linkHeight)
                                
                                if AppState.shared.user?.id == 1 {
                                    NavLinkPad(destination: .debug, linkWidth: linkWidth, linkHeight: linkHeight)
                                        .badge(funcModel.loadTimes.count)
                                }
                                
                                NavLinkPad(destination: .settings, linkWidth: linkWidth, linkHeight: linkHeight)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .onAppear { scrollToThisMonthOnAppearOfScrollView(scrollProxy) }
                //.contentMargins(.horizontal, 15, for: .scrollContent)
            }
        }
        .frame(maxWidth: .infinity)
        .onPreferenceChange(MaxNavWidthPreferenceKey.self) { linkWidth = max(linkWidth, $0) }
        .onPreferenceChange(MaxNavHeightPreferenceKey.self) { linkHeight = max(linkHeight, $0) }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(colorScheme == .dark ? Color.darkGray : Color(UIColor.systemGray6))
    }
    
    var sectionSpacer: some View {
        Spacer().frame(height: 20)
    }
        
    @ViewBuilder
    var iPadGrid: some View {
        let monthsByEnumID = Dictionary(uniqueKeysWithValues: calModel.months.map { ($0.enumID, $0) })

        Grid {
            GridRow(alignment: .top) {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                if let month = monthsByEnumID[.lastDecember] { MonthNavigationLink(month: month) }
//                MonthNavigationLink(enumID: .lastDecember)
            }
            GridRow(alignment: .top) {
                if let month = monthsByEnumID[.january] { MonthNavigationLink(month: month).id(1) }
                if let month = monthsByEnumID[.february] { MonthNavigationLink(month: month).id(2) }
//                MonthNavigationLink(enumID: .january).id(1)
//                MonthNavigationLink(enumID: .february).id(2)
            }
            GridRow(alignment: .top) {
                if let month = monthsByEnumID[.march] { MonthNavigationLink(month: month).id(3) }
                if let month = monthsByEnumID[.april] { MonthNavigationLink(month: month).id(4) }
//                MonthNavigationLink(enumID: .march).id(3)
//                MonthNavigationLink(enumID: .april).id(4)
            }
            GridRow(alignment: .top) {
                if let month = monthsByEnumID[.may] { MonthNavigationLink(month: month).id(5) }
                if let month = monthsByEnumID[.june] { MonthNavigationLink(month: month).id(6) }
//                MonthNavigationLink(enumID: .may).id(5)
//                MonthNavigationLink(enumID: .june).id(6)
            }
            GridRow(alignment: .top) {
                if let month = monthsByEnumID[.july] { MonthNavigationLink(month: month).id(7) }
                if let month = monthsByEnumID[.august] { MonthNavigationLink(month: month).id(8) }
//                MonthNavigationLink(enumID: .july).id(7)
//                MonthNavigationLink(enumID: .august).id(8)
            }
            GridRow(alignment: .top) {
                if let month = monthsByEnumID[.september] { MonthNavigationLink(month: month).id(9) }
                if let month = monthsByEnumID[.october] { MonthNavigationLink(month: month).id(10) }
//                MonthNavigationLink(enumID: .september).id(9)
//                MonthNavigationLink(enumID: .october).id(10)
            }
            GridRow(alignment: .top) {
                if let month = monthsByEnumID[.november] { MonthNavigationLink(month: month).id(11) }
                if let month = monthsByEnumID[.december] { MonthNavigationLink(month: month).id(12) }
//                MonthNavigationLink(enumID: .november).id(11)
//                MonthNavigationLink(enumID: .december).id(12)
            }
            GridRow(alignment: .top) {
                if let month = monthsByEnumID[.nextJanuary] { MonthNavigationLink(month: month) }
//                MonthNavigationLink(enumID: .nextJanuary)
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
            }
        }
    }
    
    func scrollToThisMonthOnAppearOfScrollView(_ proxy: ScrollViewProxy) {
        if !hasDoneInitialScrollToThisMonth {
            hasDoneInitialScrollToThisMonth = true
            //DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                //withAnimation {
                    proxy.scrollTo(AppState.shared.todayMonth, anchor: .center)
                //}
            //}
        }
    }
}
#endif
