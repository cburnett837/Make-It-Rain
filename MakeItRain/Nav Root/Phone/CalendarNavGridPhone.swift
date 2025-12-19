//
//  CalendarNavGridPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/1/24.
//

import SwiftUI

#if os(iOS)
struct CalendarNavGridPhone: View {
    //@Local(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    
    
    let monthNavigationNamespace: Namespace.ID
    
    @Binding var calendarNavPath: NavigationPath

    
    @State private var hasDoneInitialScrollToThisMonth = false
    
    var body: some View {        
        VStack(spacing: 0) {
            CalendarNavGridHeader(
                monthNavigationNamespace: monthNavigationNamespace,
                calendarNavPath: $calendarNavPath
            )
            .scenePadding(.horizontal)
            
            ScrollViewReader { scrollProxy in
                ScrollView {
                    if AppState.shared.methsExist {
                        Grid {
                            GridRow(alignment: .top) {
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                MonthNavigationLink(enumID: .lastDecember, monthNavigationNamespace: monthNavigationNamespace)
                                
                            }
                            GridRow(alignment: .top) {
                                MonthNavigationLink(enumID: .january, monthNavigationNamespace: monthNavigationNamespace).id(1)
                                MonthNavigationLink(enumID: .february, monthNavigationNamespace: monthNavigationNamespace).id(2)
                                MonthNavigationLink(enumID: .march, monthNavigationNamespace: monthNavigationNamespace).id(3)
                            }
                            GridRow(alignment: .top) {
                                MonthNavigationLink(enumID: .april, monthNavigationNamespace: monthNavigationNamespace).id(4)
                                MonthNavigationLink(enumID: .may, monthNavigationNamespace: monthNavigationNamespace).id(5)
                                MonthNavigationLink(enumID: .june, monthNavigationNamespace: monthNavigationNamespace).id(6)
                            }
                            GridRow(alignment: .top) {
                                MonthNavigationLink(enumID: .july, monthNavigationNamespace: monthNavigationNamespace).id(7)
                                MonthNavigationLink(enumID: .august, monthNavigationNamespace: monthNavigationNamespace).id(8)
                                MonthNavigationLink(enumID: .september, monthNavigationNamespace: monthNavigationNamespace).id(9)
                            }
                            GridRow(alignment: .top) {
                                MonthNavigationLink(enumID: .october, monthNavigationNamespace: monthNavigationNamespace).id(10)
                                MonthNavigationLink(enumID: .november, monthNavigationNamespace: monthNavigationNamespace).id(11)
                                MonthNavigationLink(enumID: .december, monthNavigationNamespace: monthNavigationNamespace).id(12)
                            }
                            GridRow(alignment: .top) {
                                MonthNavigationLink(enumID: .nextJanuary, monthNavigationNamespace: monthNavigationNamespace)
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                            }
                        }
                    }
                }
                .contentMargins(.horizontal, 15, for: .scrollContent)
                .onAppear { scrollToThisMonthOnAppearOfScrollView(scrollProxy) }
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
