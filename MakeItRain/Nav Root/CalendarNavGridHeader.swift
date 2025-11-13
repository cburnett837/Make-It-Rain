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
    //@Local(\.colorTheme) var colorTheme
    @Environment(CalendarModel.self) var calModel
    @Environment(EventModel.self) var eventModel
    @Environment(PlaidModel.self) var plaidModel
    
    let monthNavigationNamespace: Namespace.ID
    
    var isPlayground: Bool {
        return calModel.sYear == 1900
    }

    
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
                        Text("Playground")
                            .tag(1900)
                    }
                }
                
                if !isPlayground {
                    Section {
                        Picker("", selection: $calModel.sYear) {
                            var years: [Int] {
                                [calModel.sYear - 1, calModel.sYear, calModel.sYear + 1]
                            }
                            
                            ForEach(years, id: \.self) {
                                Text(String($0))
                                    .tag($0)
                                //.foregroundStyle($0 == AppState.shared.todayYear ? Color.theme : .primary)
                            }
                        }
                    }
                }
                
                Section {
                    Picker("All Years", selection: $calModel.sYear) {
                        var years: [Int] { Array(2000...2099).map { $0 } }
                        ForEach(years, id: \.self) {
                            Text(String($0))
                                .tag($0)
                                //.foregroundStyle($0 == AppState.shared.todayYear ? Color.theme : .primary)
                        }
                    }
                    .pickerStyle(.menu)
                }
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Make It Rain")
                        .font(.largeTitle)
                        .bold()
                        .schemeBasedForegroundStyle()
                        .lineLimit(1)
                    
                    HStack(spacing: 2) {
                        Text("\(isPlayground ? "Playground" : String(calModel.sYear))")
                        //Image(systemName: "chevron.right")
                    }
                    .font(.title)
                    .bold()
                    .if(AppState.shared.todayYear == calModel.sYear) {
                        $0.foregroundStyle(Color.theme)
                    }
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .contentShape(Rectangle())
                }
            }
            .layoutPriority(1)
            //.padding(.leading, 16)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            .contentShape(Rectangle())
        }
        //.padding(.leading, -13) /// Negate the scrollContent margins
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
                            .foregroundStyle(Color.theme == .orange ? .red : .orange)
                    }
                    .tint(.none)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if !eventModel.invitations.isEmpty {
                    ShowEventInvitesView()
                }
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                if AppState.shared.isIpad {
                    Button {
                        NavigationManager.shared.selectedMonth = nil
                        NavigationManager.shared.selection = .search
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .tint(.none)
                } else {
                    ToolbarLongPollButton()
                }
            }
            
            if AppState.shared.isIpad {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                ToolbarRefreshButton()
            }
            
            if AppState.shared.isIphone {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: NavDestination.settings) {
                        Image(systemName: "gear")
                    }
                    .tint(.none)
                    .matchedTransitionSource(id: NavDestination.settings, in: monthNavigationNamespace)
                }
            }
            
            
            
//            ToolbarItemGroup(placement: .topBarTrailing) {
//                if !eventModel.invitations.isEmpty {
//                    ShowEventInvitesView()
//                }
//                
//                if AppState.shared.isIpad {
//                    Button {
//                        NavigationManager.shared.selectedMonth = nil
//                        NavigationManager.shared.selection = .search
//                    } label: {
//                        Image(systemName: "magnifyingglass")
//                    }
//                    
//                    Button {
//                        NavigationManager.shared.selectedMonth = nil
//                        NavigationManager.shared.selection = .settings
//                    } label: {
//                        Image(systemName: "gear")
//                    }
//                } else {
////                    NavigationLink(value: NavDestination.search) {
////                        Image(systemName: "magnifyingglass")
////                    }
////                    .matchedTransitionSource(id: NavDestination.search, in: monthNavigationNamespace)
//                    
//                    ToolbarLongPollButton()
//                    
//                    ToolbarRefreshButton()
//                    
//                    NavigationLink(value: NavDestination.settings) {
//                        Image(systemName: "gear")
//                    }
//                    .matchedTransitionSource(id: NavDestination.settings, in: monthNavigationNamespace)
//                }
//            }
            
            
            
        }
    }
}
#endif
