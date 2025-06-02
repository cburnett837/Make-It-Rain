//
//  CalendarNavGridHeader.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/24/25.
//

import SwiftUI

#if os(iOS)
struct CalendarNavGridHeader: View {
    @Environment(\.colorScheme) var colorScheme
    @Local(\.colorTheme) var colorTheme
    @Environment(CalendarModel.self) var calModel
    @Environment(EventModel.self) var eventModel
    @Environment(PlaidModel.self) var plaidModel
    
    let monthNavigationNamespace: Namespace.ID

    
    var body: some View {
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
                        $0.foregroundStyle(Color.fromName(colorTheme))
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
            
            .contentShape(Rectangle())
        }
        .padding(.leading, -13) /// Negate the scrollContent margins
        .toolbar {
            //CalendarNavGridToolbar()
            ToolbarItemGroup(placement: .topBarLeading) {
                if calModel.sMonth.actualNum != AppState.shared.todayMonth && calModel.sYear != AppState.shared.todayYear {
                    NowButton()
                }
                
                if plaidModel.atLeastOneBankHasAnIssue {
                    Button {
                        AppState.shared.showAlert("One or more banks are currently having issues. Please review in the plaid section.")
                    } label: {
                        Image(systemName: "creditcard.trianglebadge.exclamationmark")
                            .foregroundStyle(Color.fromName(colorTheme) == .orange ? .red : .orange)
                    }
                }
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !eventModel.invitations.isEmpty {
                    ShowEventInvitesView()
                }
                
                if AppState.shared.isIpad {
                    Button {
                        NavigationManager.shared.selectedMonth = nil
                        NavigationManager.shared.selection = .search
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    Button {
                        NavigationManager.shared.selectedMonth = nil
                        NavigationManager.shared.selection = .settings
                    } label: {
                        Image(systemName: "gear")
                    }
                } else {
//                    NavigationLink(value: NavDestination.search) {
//                        Image(systemName: "magnifyingglass")
//                    }
//                    .matchedTransitionSource(id: NavDestination.search, in: monthNavigationNamespace)
                    
                    ToolbarLongPollButton()
                    
                    NavigationLink(value: NavDestination.settings) {
                        Image(systemName: "gear")
                    }
                    .matchedTransitionSource(id: NavDestination.settings, in: monthNavigationNamespace)
                }
            }
        }
    }
}
#endif
