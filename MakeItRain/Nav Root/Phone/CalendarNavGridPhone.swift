//
//  CalendarNavGridPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/1/24.
//

import SwiftUI

#if os(iOS)
struct CalendarNavGridPhone: View {
    @Local(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(EventModel.self) var eventModel
    
    let monthNavigationNamespace: Namespace.ID
    
    var body: some View {        
        VStack(spacing: 0) {
            ScrollView {
                CalendarNavGridHeader(monthNavigationNamespace: monthNavigationNamespace)
                    
                if AppState.shared.methsExist {
                    Grid {
                        GridRow(alignment: .top) {
                            Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                            Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                            MonthNavigationLink(enumID: .lastDecember, monthNavigationNamespace: monthNavigationNamespace)
                            
                        }
                        GridRow(alignment: .top) {
                            MonthNavigationLink(enumID: .january, monthNavigationNamespace: monthNavigationNamespace)
                            MonthNavigationLink(enumID: .february, monthNavigationNamespace: monthNavigationNamespace)
                            MonthNavigationLink(enumID: .march, monthNavigationNamespace: monthNavigationNamespace)
                        }
                        GridRow(alignment: .top) {
                            MonthNavigationLink(enumID: .april, monthNavigationNamespace: monthNavigationNamespace)
                            MonthNavigationLink(enumID: .may, monthNavigationNamespace: monthNavigationNamespace)
                            MonthNavigationLink(enumID: .june, monthNavigationNamespace: monthNavigationNamespace)
                        }
                        GridRow(alignment: .top) {
                            MonthNavigationLink(enumID: .july, monthNavigationNamespace: monthNavigationNamespace)
                            MonthNavigationLink(enumID: .august, monthNavigationNamespace: monthNavigationNamespace)
                            MonthNavigationLink(enumID: .september, monthNavigationNamespace: monthNavigationNamespace)
                        }
                        GridRow(alignment: .top) {
                            MonthNavigationLink(enumID: .october, monthNavigationNamespace: monthNavigationNamespace)
                            MonthNavigationLink(enumID: .november, monthNavigationNamespace: monthNavigationNamespace)
                            MonthNavigationLink(enumID: .december, monthNavigationNamespace: monthNavigationNamespace)
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
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
