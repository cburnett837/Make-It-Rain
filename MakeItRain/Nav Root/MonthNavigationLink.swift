//
//  MonthNavigationLink.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/5/25.
//


import SwiftUI

struct MonthNavigationLink: View {
    @Environment(CalendarModel.self) var calModel
    
    //@Local(\.colorTheme) var colorTheme
    let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .top), count: 7)
    
    @State private var blinkView = false
    @State private var blinkTimer: Timer?
    
    var enumID: NavDestination
    let monthNavigationNamespace: Namespace.ID
    
    var month: CBMonth {
        calModel.months.filter { $0.enumID == enumID }.first!
    }
    
    var monthTitle: String {
        if calModel.isPlayground {
            if month.enumID == .lastDecember {
                "Last \(month.abbreviatedName)"
            } else if month.enumID == .nextJanuary {
                "Next \(month.abbreviatedName)"
            } else {
                month.abbreviatedName
            }
        } else {
            if month.enumID == .lastDecember || month.enumID == .nextJanuary {
                "\(month.abbreviatedName) \(String(month.year))"
            } else {
                month.abbreviatedName
            }
        }
    }
            
    var body: some View {
        VStack(alignment: .leading) {
            monthName
            monthDayGrid
        }
        .contentShape(Rectangle())
        .matchedTransitionSource(id: month.enumID, in: monthNavigationNamespace)
        
        .padding(.bottom, 10)
        .buttonStyle(.plain)
        .padding(4)
        /// Make sure all buttons are the same height, regardless of the amount of weekly rows in the month
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(blinkView
                      ? Color.theme
                      : NavigationManager.shared.selectedMonth == month.enumID
                      ? Color(.tertiarySystemFill)
                      : Color.clear
                )
        )
        
        .onTapGesture {
            //print("SourceID: \(month.enumID)")
            navigateToMonth()
        }
        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
            AppState.shared.dragMonthTarget = nil
            return true
        } isTargeted: {
            if $0 {
                monthIsDragTargeted()
            } else {
                AppState.shared.dragOnMonthTimer?.invalidate()
            }
        }
    }
    
    
    var monthName: some View {
        Text(monthTitle)
            .font(.title3)
            .bold()
            .foregroundStyle(
                AppState.shared.todayMonth == month.actualNum && AppState.shared.todayYear == month.year
                ? Color.theme
                : Color.primary
            )
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
                            .font(.caption2)
                            .bold(day.date.isToday)
                            .foregroundStyle(day.date.isToday ? Color.theme : .primary)
                    }
                }
                .padding(.bottom, 4)
                
            }
        }
    }
    
    
    func navigateToMonth() {
        NavigationManager.shared.selectedMonth = month.enumID
        NavigationManager.shared.selection = nil
        
        #if os(iOS)
        if AppState.shared.isIphone {
            calModel.showMonth = true
        }
        #endif
    }
    
    
    func monthIsDragTargeted() {
        AppState.shared.dragOnMonthTimer?.invalidate()
                        
        AppState.shared.dragOnMonthTimer = Timer(fire: Date.now.addingTimeInterval(1), interval: 0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.1).repeatCount(2)) {
                blinkView.toggle()
            } completion: {
                AppState.shared.dragMonthTarget = enumID
                NavigationManager.shared.selectedMonth = enumID
                blinkView = false
            }
        }
                                                
        if let dragOnMonthTimer = AppState.shared.dragOnMonthTimer {
            RunLoop.main.add(dragOnMonthTimer, forMode: .common)
        }
    }
}
