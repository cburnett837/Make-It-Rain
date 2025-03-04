//
//  RootViewIphone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI


#if os(iOS)
//let colorScheme = UIScreen.main.traitCollection.userInterfaceStyle



struct RootViewPhone: View {    
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    
    //@State private var showSearchBar = false
    //@State private var showSettings = false
    
    //@FocusState private var focusedField: Int?
    //@FocusState private var searchFocus: Int?
    @Binding var selectedDay: CBDay?
    
    @Binding var showMonth: Bool
    
    @Namespace private var monthNavigationNamespace

        
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        //@Bindable var vm = vm
        @Bindable var appState = AppState.shared
        
        Group {
            if AppState.shared.isIpad {
                NavigationSplitView {
                    NavSidebar(selectedDay: $selectedDay, showMonth: $showMonth)
                        .navigationTitle("")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                Text("") /// Needed to make space at the top and push the fakeNavHeader down
                                //                                Button {
                                //                                    showSettings = true
                                //                                } label: {
                                //                                    Image(systemName: "gear")
                                //                                }
                                
                                
                            }
                            
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                //                                var years: [Int] { Array(2000...2099).map { $0 } }
                                //                                Picker("Year", selection: $calModel.sYear) {
                                //                                    ForEach(years, id: \.self) {
                                //                                        Text(String($0))
                                //                                    }
                                //                                }
                                //                                .pickerStyle(.menu)
                                
                                
                                Button {
                                    //NavigationManager.shared.navPath = [destination]
                                    NavigationManager.shared.selection = .search
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                }
                                
                                Button {
                                    //NavigationManager.shared.navPath = [destination]
                                    NavigationManager.shared.selection = .settings
                                } label: {
                                    Image(systemName: "gear")
                                }
                                
                               
                                
                                //                                Button {
                                //                                    showSettings = true
                                //                                } label: {
                                //                                    Image(systemName: "gear")
                                //                                }
                            }
                        }
                } detail: {
                    switch navManager.selection {
                    case .january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december, .lastDecember, .nextJanuary:
                        CalendarViewPhone(enumID: navManager.selection!, selectedDay: $selectedDay)
                        
                    case .repeatingTransactions:
                        RepeatingTransactionsTable()
                        
                    case .paymentMethods:
                        PayMethodsTable()
                        
                    case .categories:
                        CategoriesTable()
                        
                    case .keywords:
                        KeywordsTable()
                        
                    case .search:
                        AdvancedSearchView()
                        
                    case .analytics:
                        Text("analytics")
                        
                    case .events:
                        EventsTable()
                        
                    case .settings:
                        SettingsView(showSettings: .constant(true))
                        
                    case .none:
                        EmptyView()
                        
                    @unknown default:
                        EmptyView()
                    }
                }
//                } detail: {
//                    Text("Side bar")
//                        .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 400)
//                }

            } else {
                NavigationStack/*(path: $navManager.navPath)*/ {
                    NavSidebar(selectedDay: $selectedDay, showMonth: $showMonth)
                        .navigationTitle("")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                Text("") /// Needed to make space at the top and push the fakeNavHeader down
//                                Button {
//                                    showSettings = true
//                                } label: {
//                                    Image(systemName: "gear")
//                                }
                                                        
                                
                            }
                            
                            ToolbarItemGroup(placement: .topBarTrailing) {
//                                var years: [Int] { Array(2000...2099).map { $0 } }
//                                Picker("Year", selection: $calModel.sYear) {
//                                    ForEach(years, id: \.self) {
//                                        Text(String($0))
//                                    }
//                                }
//                                .pickerStyle(.menu)
                                
                                NavigationLink(value: NavDestination.search) {
                                    Image(systemName: "magnifyingglass")
                                }
                                .matchedTransitionSource(id: NavDestination.search, in: monthNavigationNamespace)
                                
                                NavigationLink(value: NavDestination.settings) {
                                    Image(systemName: "gear")
                                }
                                .matchedTransitionSource(id: NavDestination.settings, in: monthNavigationNamespace)
                                
//                                Button {
//                                    showSettings = true
//                                } label: {
//                                    Image(systemName: "gear")
//                                }
                            }
                        }
                        .navigationDestination(for: NavDestination.self) { dest in
                            switch dest {
//                            case .january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december, .lastDecember, .nextJanuary:
//                                CalendarViewPhone(enumID: dest, showSearchBar: $showSearchBar, selectedDay: $selectedDay, focusedField: $focusedField, searchFocus: $searchFocus)
//                                    .navigationTransition(.zoom(sourceID: dest, in: monthNavigationNamespace))
                                
                            case .repeatingTransactions:
                                RepeatingTransactionsTable()
                                
                            case .paymentMethods:
                                PayMethodsTable()
                                
                            case .categories:
                                CategoriesTable()
                                
                            case .keywords:
                                KeywordsTable()
                                
                            case .search:
                                AdvancedSearchView()
                                    .navigationTransition(.zoom(sourceID: NavDestination.search, in: monthNavigationNamespace))
                                
                            case .analytics:
                                Text("analytics")
                                
                            case .events:
                                EventsTable()
                                
                            case .settings:
                                SettingsView(showSettings: .constant(true))
                                    .navigationTransition(.zoom(sourceID: NavDestination.settings, in: monthNavigationNamespace))
                                
                            default:
                               EmptyView()
                            }
                        }
                        //.fullScreenCover(item: $navManager.monthSelection, content: { selection in
                        .fullScreenCover(isPresented: $showMonth) {
                            if let selection = navManager.selection {
                                if NavDestination.justMonths.contains(selection) {
                                    CalendarViewPhone(enumID: selection, selectedDay: $selectedDay)
                                        .navigationTransition(.zoom(sourceID: selection, in: monthNavigationNamespace))
                                        .if(AppState.shared.methsExist) {
                                            $0.loadingSpinner(id: selection, text: "Loading…")
                                        }
                                }
                            }
                        }
//                        .fullScreenCover(isPresented: $showMonth) {
//                            if let selection = navManager.selection {
//                                if NavDestination.justMonths.contains(selection) {
//                                    CalendarViewPhone(enumID: selection, showSearchBar: $showSearchBar, selectedDay: $selectedDay, focusedField: $focusedField, searchFocus: $searchFocus)
//                                        .navigationTransition(.zoom(sourceID: selection, in: monthNavigationNamespace))
//                                }
//                            }
//                        }
                }
            }
        }
        
        
        
        //.toast()
        
        /// Don't show this loading spinner if the user has to add an initial payment method.
//        .if(AppState.shared.methsExist) {
//            $0.loadingSpinner(id: .placeholderMonth, text: "Loading…")
//        }
        
//        .overlay {
//            VStack {
//                VStack {
//                    
////                    StandardUITextField(
////                        "Search \(calModel.searchWhat == .titles ? "Titles" : "Tags")",
////                        text: $calModel.searchText,
////                        onSubmit: { withAnimation { showSearchBar = false } },
////                        onCancel: { withAnimation { showSearchBar = false } },
////                        toolbar: {
////                            KeyboardToolbarView(focusedField: $focusedField, removeNavButtons: true, extraDoneFunctionality: {
////                                withAnimation { showSearchBar = false }
////                            })
////                        }
////                    )
////                    .cbFocused(_focusedField, equals: 0)
////                    .cbClearButtonMode(.whileEditing)
////                    .cbIsSearchField(true)
////                    .cbAlwaysShowCancelButton(true)
////                    
//                    /// Opting for this since using ``StandardUITextField`` won't close the keyboard when clicking the return button.
//                    /// I also don't need the toolbar for this textField.
//                    StandardTextField(
//                        "Search \(calModel.searchWhat == .titles ? "Transaction Titles" : "Transaction Tags")",
//                        text: $calModel.searchText,
//                        isSearchField: true,
//                        alwaysShowCancelButton: true,
//                        focusedField: $focusedField,
//                        focusValue: 0,
//                        onSubmit: { withAnimation { showSearchBar = false } },
//                        onCancel: { withAnimation { showSearchBar = false } }
//                    )
//                    Picker("", selection: $calModel.searchWhat) {
//                        Text("Transaction Title")
//                            .tag(CalendarSearchWhat.titles)
//                        Text("Tag")
//                            .tag(CalendarSearchWhat.tags)
//                    }
//                    .labelsHidden()
//                    .pickerStyle(.segmented)
//                }
//                
//                .padding(.horizontal, 10)
//                .padding(.bottom, 10)
//                //.focused($focusedField, equals: .search)
//                .background(.ultraThickMaterial)
//                
//                Spacer()
//            }
//            //.animation(.easeOut, value: showSearchBar)
//            
//            //.opacity(showSearchBar ? 1 : 0)
//            .offset(y: showSearchBar ? 0 : -200)
//            .transition(.move(edge: .top))
//        }
        
        
        //.environment(vm)
        
//        .sheet(isPresented: $showSettings) {
//            SettingsView(showSettings: $showSettings)
//        }
    }
}

#endif
