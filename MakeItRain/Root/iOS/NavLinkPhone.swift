//
//  NavLinkPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/7/24.
//

import SwiftUI

#if os(iOS)
struct NavLinkPhone: View {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("useGrayBackground") var useGrayBackground = true
        
    let destination: NavDestination
    let title: String
    let image: String
    
    var body: some View {
        Group {
            if AppState.shared.isIpad {
                Button {
                    NavigationManager.shared.selectedMonth = nil
                    NavigationManager.shared.selection = destination
                } label: {
                    Label(
                        title: { Text(title) },
                        icon: { Image(systemName: image) }
                    )
                }
            } else {
                NavigationLink(value: destination) {
                    Label(
                        title: { Text(title) },
                        icon: { Image(systemName: image) }
                    )
                }
            }
        }
        .standardNavRowBackgroundWithSelection(id: destination.rawValue, selectedID: NavigationManager.shared.selection?.rawValue)
    }
}

struct MonthNavigationLink: View {
    @Environment(CalendarModel.self) var calModel; @Environment(CalendarViewModel.self) var calViewModel
    
    
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @Namespace private var monthNavigationNamespace
    let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .top), count: 7)
    
    var enumID: NavDestination
    //@Binding var showMonth: Bool
    
    var month: CBMonth {
        calModel.months.filter {$0.enumID == enumID}.first!
    }
    
    var body: some View {
        Button(action: navigateToMonth) {
            VStack(alignment: .leading) {
                monthName
                monthDayGrid
            }
            .contentShape(Rectangle())
            .matchedTransitionSource(id: month.enumID, in: monthNavigationNamespace)
        }
        .padding(.bottom, 10)
        .buttonStyle(.plain)
        .padding(4)
        .if(AppState.shared.isIpad) {
            $0.background(
                RoundedRectangle(cornerRadius: 6)
                    /// Use this to only hilight the overview day.
                    .fill(NavigationManager.shared.selectedMonth == month.enumID ? Color(.tertiarySystemFill) : Color.clear)
            )
        }
    }
    
    var monthName: some View {
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
    }
    
    var monthDayGrid: some View {
        LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
            ForEach(month.days) { day in
                Group {
                    if day.date == nil {
                        Text("")
                            .font(.caption2)
                    } else {
                        Text("\(day.dateComponents?.day ?? 0)")
                            .lineLimit(1)
                            //.minimumScaleFactor(0.5)
                            .font(.caption2)
                            //.font(.system(size: 5))
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
    
    func navigateToMonth() {
        NavigationManager.shared.selectedMonth = month.enumID
        NavigationManager.shared.selection = nil
        
        if !AppState.shared.isIpad {
            calModel.showMonth = true
        }
    }
}
#endif
