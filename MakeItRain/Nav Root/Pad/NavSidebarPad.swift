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

    
    let monthNavigationNamespace: Namespace.ID
    @State private var calendarNavPath = NavigationPath()

    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    Group {
                        CalendarNavGridHeader(monthNavigationNamespace: monthNavigationNamespace, calendarNavPath: $calendarNavPath)
                        
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
        
    
    var iPadGrid: some View {
        Grid {
            GridRow(alignment: .top) {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                MonthNavigationLink(enumID: .lastDecember, monthNavigationNamespace: monthNavigationNamespace)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .january, monthNavigationNamespace: monthNavigationNamespace).id(1)
                MonthNavigationLink(enumID: .february, monthNavigationNamespace: monthNavigationNamespace).id(2)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .march, monthNavigationNamespace: monthNavigationNamespace).id(3)
                MonthNavigationLink(enumID: .april, monthNavigationNamespace: monthNavigationNamespace).id(4)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .may, monthNavigationNamespace: monthNavigationNamespace).id(5)
                MonthNavigationLink(enumID: .june, monthNavigationNamespace: monthNavigationNamespace).id(6)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .july, monthNavigationNamespace: monthNavigationNamespace).id(7)
                MonthNavigationLink(enumID: .august, monthNavigationNamespace: monthNavigationNamespace).id(8)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .september, monthNavigationNamespace: monthNavigationNamespace).id(9)
                MonthNavigationLink(enumID: .october, monthNavigationNamespace: monthNavigationNamespace).id(10)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .november, monthNavigationNamespace: monthNavigationNamespace).id(11)
                MonthNavigationLink(enumID: .december, monthNavigationNamespace: monthNavigationNamespace).id(12)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .nextJanuary, monthNavigationNamespace: monthNavigationNamespace)
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
