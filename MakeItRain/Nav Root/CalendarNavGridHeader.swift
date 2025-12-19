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
    @Environment(CalendarModel.self) var calModel
    @Environment(PlaidModel.self) var plaidModel
    
    let monthNavigationNamespace: Namespace.ID
    @Binding var calendarNavPath: NavigationPath
    
    var isPlayground: Bool { calModel.sYear == 1900 }
    
    var body: some View {
        mainTitleMenu
            .toolbar { toolbar }
    }
    
    // MARK: - Toolbar Stuff
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            if calModel.sMonth.actualNum != AppState.shared.todayMonth && calModel.sYear != AppState.shared.todayYear {
                NowButton()
            }
            
            if plaidModel.atLeastOneBankHasAnIssue {
                plaidWarningButton
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            if AppState.shared.isIpad {
                advancedSearchButton
            } else {
                ToolbarLongPollButton()
            }
        }
        
//        if AppState.shared.isIpad {
//            ToolbarSpacer(.fixed, placement: .topBarTrailing)
//        }
        
        ToolbarItem(placement: .topBarTrailing) {
            ToolbarRefreshButton()
        }
        
        if AppState.shared.isIphone {
            //ToolbarSpacer(.fixed, placement: .topBarTrailing)
            
            ToolbarItem(placement: .topBarTrailing) {
                settingsButton
            }
        }
    }
    
    
    var plaidWarningButton: some View {
        Button {
            AppState.shared.showAlert("One or more banks are currently having issues. Please review in the plaid section.")
        } label: {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .foregroundStyle(Color.theme == .orange ? .red : .orange)
        }
        .tint(.none)
    }
    
    
    var advancedSearchButton: some View {
        Button {
            NavigationManager.shared.selectedMonth = nil
            NavigationManager.shared.selection = .search
        } label: {
            Image(systemName: "magnifyingglass")
        }
        .tint(.none)
    }
    
    
    var settingsButton: some View {
        Button {
            calendarNavPath.append(NavDestination.settings)
        } label: {
            Image(systemName: "gear")
                .schemeBasedForegroundStyle()
        }
        
//        NavigationLink(value: NavDestination.settings) {
//            Image(systemName: "gear")
//        }
//        .navigationLinkIndicatorVisibility(.hidden)
//        .tint(.none)
        //.matchedTransitionSource(id: NavDestination.settings, in: monthNavigationNamespace)
    }
    
    
    
    
    // MARK: - Main View Stuff
    @ViewBuilder
    var mainTitleMenu: some View {
        @Bindable var calModel = calModel
        Menu {
            if (![calModel.sYear-1, calModel.sYear, calModel.sYear+1].contains(AppState.shared.todayYear)) {
                Section { nowButton }
            }
            
            Section { playgroundPicker }
            
            if !isPlayground {
                Section { nowishYearPicker }
            }
            
            Section { yearPicker }
        } label: {
            mainTitleMenuLabel
        }
        .layoutPriority(1)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
    
    
    var nowButton: some View {
        Button("Now") {
            calModel.sYear = AppState.shared.todayYear
        }
    }
    
    
    @ViewBuilder
    var playgroundPicker: some View {
        @Bindable var calModel = calModel
        Picker("", selection: $calModel.sYear) {
            Text("Playground")
                .tag(1900)
        }
    }
    
    
    @ViewBuilder
    var nowishYearPicker: some View {
        @Bindable var calModel = calModel
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
    
    
    @ViewBuilder
    var yearPicker: some View {
        @Bindable var calModel = calModel
        
        Picker("All Years", selection: $calModel.sYear) {
            var years: [Int] { Array(2000...2099).map { $0 } }
            
            ForEach(years, id: \.self) {
                Text(String($0))
                    .tag($0)
            }
        }
        .pickerStyle(.menu)
    }
    
    
    var mainTitleMenuLabel: some View {
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
    
    
}
#endif
