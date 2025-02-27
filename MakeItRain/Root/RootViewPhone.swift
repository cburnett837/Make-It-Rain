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
    
    @State private var showSearchBar = false
    @State private var showSettings = false
    
    @FocusState private var focusedField: Int?
    @FocusState private var searchFocus: Int?
    @Binding var selectedDay: CBDay?
    
    @Namespace private var monthNavigationNamespace

        
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        //@Bindable var vm = vm
        @Bindable var appState = AppState.shared
        
        Group {
            if AppState.shared.isIpad {
                NavigationSplitView {
                    NavSidebar(selectedDay: $selectedDay)
                        .navigationTitle("Make It Rain")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "gear")
                                }
                                                        
                                NavigationLink(value: NavDestination.search) {
                                    Image(systemName: "magnifyingglass")
                                }
                            }
                            
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                var years: [Int] { Array(2000...2099).map { $0 } }
                                Picker("Year", selection: $calModel.sYear) {
                                    ForEach(years, id: \.self) {
                                        Text(String($0))
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                } detail: {
                    switch navManager.selection {
                    case .january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december, .lastDecember, .nextJanuary:
                        CalendarViewPhone(enumID: navManager.selection!, showSearchBar: $showSearchBar, selectedDay: $selectedDay, focusedField: $focusedField, searchFocus: $searchFocus)
                                                
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
                        
                    case .none:
                        EmptyView()
                        
                    @unknown default:
                       EmptyView()
                    }
                }

            } else {
                NavigationStack(path: $navManager.navPath) {
                    NavSidebar(selectedDay: $selectedDay)
                        .navigationTitle("Make It Rain")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarLeading) {
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
                                
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "gear")
                                }
                            }
                        }
                        .navigationDestination(for: NavDestination.self) { dest in
                            switch dest {
                            case .january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december, .lastDecember, .nextJanuary:
                                CalendarViewPhone(enumID: dest, showSearchBar: $showSearchBar, selectedDay: $selectedDay, focusedField: $focusedField, searchFocus: $searchFocus)
                                    //.navigationTransition(.zoom(sourceID: dest, in: monthNavigationNamespace))
                                
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
                                
                            @unknown default:
                               EmptyView()
                            }
                        }
                }
            }
        }
        
        
        
        //.toast()
        
        /// Don't show this loading spinner if the user has to add an initial payment method.
        .if(AppState.shared.methsExist) {
            $0.loadingSpinner(id: calModel.sMonth.enumID, text: "Loading…")
        }
        
        .overlay {
            VStack {
                VStack {
                    
//                    StandardUITextField(
//                        "Search \(calModel.searchWhat == .titles ? "Titles" : "Tags")",
//                        text: $calModel.searchText,
//                        onSubmit: { withAnimation { showSearchBar = false } },
//                        onCancel: { withAnimation { showSearchBar = false } },
//                        toolbar: {
//                            KeyboardToolbarView(focusedField: $focusedField, removeNavButtons: true, extraDoneFunctionality: {
//                                withAnimation { showSearchBar = false }
//                            })
//                        }
//                    )
//                    .cbFocused(_focusedField, equals: 0)
//                    .cbClearButtonMode(.whileEditing)
//                    .cbIsSearchField(true)
//                    .cbAlwaysShowCancelButton(true)
//                    
                    /// Opting for this since using ``StandardUITextField`` won't close the keyboard when clicking the return button.
                    /// I also don't need the toolbar for this textField.
                    StandardTextField(
                        "Search \(calModel.searchWhat == .titles ? "Transaction Titles" : "Transaction Tags")",
                        text: $calModel.searchText,
                        isSearchField: true,
                        alwaysShowCancelButton: true,
                        focusedField: $focusedField,
                        focusValue: 0,
                        onSubmit: { withAnimation { showSearchBar = false } },
                        onCancel: { withAnimation { showSearchBar = false } }
                    )
                    Picker("", selection: $calModel.searchWhat) {
                        Text("Transaction Title")
                            .tag(CalendarSearchWhat.titles)
                        Text("Tag")
                            .tag(CalendarSearchWhat.tags)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                //.focused($focusedField, equals: .search)
                .background(.ultraThickMaterial)
                
                Spacer()
            }
            //.animation(.easeOut, value: showSearchBar)
            
            //.opacity(showSearchBar ? 1 : 0)
            .offset(y: showSearchBar ? 0 : -200)
            .transition(.move(edge: .top))
        }
        
        
        //.environment(vm)
        
        .sheet(isPresented: $showSettings) {
            SettingsView(showSettings: $showSettings)
        }
    }
}

#endif
