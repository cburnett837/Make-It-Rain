//
//  NavSidebarPad.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/24/25.
//

import SwiftUI


struct MaxNavHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
struct MaxNavWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#if os(iOS)
struct NavSidebarPad: View {
    @Environment(\.colorScheme) var colorScheme    
    @Local(\.colorTheme) var colorTheme

    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(EventModel.self) var eventModel
    //@Binding var showMonth: Bool
    
    @State private var linkWidth: CGFloat = 20.0
    @State private var linkHeight: CGFloat = 20.0
    
    let monthNavigationNamespace: Namespace.ID
    
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        
        VStack(spacing: 0) {
            ScrollView {
                CalendarNavGridHeader(monthNavigationNamespace: monthNavigationNamespace)
                
                if AppState.shared.methsExist {
                    iPadGrid
                }
                
                Spacer()
                    .frame(height: 20)
                
                VStack(spacing: 0) {
                    if AppState.shared.methsExist {
                        NavLinkPad(destination: .categories, title: "Categories", image: "books.vertical", linkWidth: linkWidth, linkHeight: linkHeight)
                            .listRowSeparator(.hidden)
                    }
                    
                    NavLinkPad(destination: .paymentMethods, title: "Accounts", image: "creditcard", linkWidth: linkWidth, linkHeight: linkHeight)
                        .listRowSeparator(.hidden)
                    
                    if AppState.shared.methsExist {
                        Section("") {
                            NavLinkPad(destination: .events, title: "Events", image: "beach.umbrella", linkWidth: linkWidth, linkHeight: linkHeight)
                                .listRowSeparator(.hidden)
                            
                            NavLinkPad(destination: .repeatingTransactions, title: "Reoccuring Transactions", image: "repeat", linkWidth: linkWidth, linkHeight: linkHeight)
                                .listRowSeparator(.hidden)
                            
                            NavLinkPad(destination: .keywords, title: "Keywords", image: "textformat.abc.dottedunderline", linkWidth: linkWidth, linkHeight: linkHeight)
                                .listRowSeparator(.hidden)
                        }
                                                
                        Section("") {
                            NavLinkPad(destination: .plaid, title: "Plaid", image: "list.bullet", linkWidth: linkWidth, linkHeight: linkHeight)
                                .listRowSeparator(.hidden)
                        }
                                                                        
                        if AppState.shared.user?.id == 1 {
                            Section("") {
                                NavLinkPad(destination: .debug, title: "Debug", image: "ladybug", linkWidth: linkWidth, linkHeight: linkHeight)
                                    .listRowSeparator(.hidden)
                                    .badge(funcModel.loadTimes.count)
                            }
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 15, for: .scrollContent)
        }
        .frame(maxWidth: .infinity)
        .onPreferenceChange(MaxNavWidthPreferenceKey.self) { linkWidth = max(linkWidth, $0) }
        .onPreferenceChange(MaxNavHeightPreferenceKey.self) { linkHeight = max(linkHeight, $0) }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(colorScheme == .dark ? Color.darkGray : Color(UIColor.systemGray6))
    }
        
    
    var iPadGrid: some View {
        Grid {
            GridRow(alignment: .top) {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                MonthNavigationLink(enumID: .lastDecember, monthNavigationNamespace: monthNavigationNamespace)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .january, monthNavigationNamespace: monthNavigationNamespace)
                MonthNavigationLink(enumID: .february, monthNavigationNamespace: monthNavigationNamespace)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .march, monthNavigationNamespace: monthNavigationNamespace)
                MonthNavigationLink(enumID: .april, monthNavigationNamespace: monthNavigationNamespace)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .may, monthNavigationNamespace: monthNavigationNamespace)
                MonthNavigationLink(enumID: .june, monthNavigationNamespace: monthNavigationNamespace)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .july, monthNavigationNamespace: monthNavigationNamespace)
                MonthNavigationLink(enumID: .august, monthNavigationNamespace: monthNavigationNamespace)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .september, monthNavigationNamespace: monthNavigationNamespace)
                MonthNavigationLink(enumID: .october, monthNavigationNamespace: monthNavigationNamespace)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .november, monthNavigationNamespace: monthNavigationNamespace)
                MonthNavigationLink(enumID: .december, monthNavigationNamespace: monthNavigationNamespace)
            }
            GridRow(alignment: .top) {
                MonthNavigationLink(enumID: .nextJanuary, monthNavigationNamespace: monthNavigationNamespace)
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
            }
        }
    }
}
#endif
