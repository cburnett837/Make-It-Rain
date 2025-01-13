////
////  RootViewIphone.swift
////  MakeItRain
////
////  Created by Cody Burnett on 10/16/24.
////
//
//import SwiftUI
//
//
//#if os(iOS)
////let colorScheme = UIScreen.main.traitCollection.userInterfaceStyle
//
//
//
//struct RootViewPhone: View {
//    @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
//    
//    @Environment(RootViewModelPhone.self) var vm
//    @Environment(CalendarModel.self) var calModel
//    @Environment(PayMethodModel.self) var payModel
//    @Environment(CategoryModel.self) var catModel
//    @Environment(KeywordModel.self) var keyModel
//    @Environment(RepeatingTransactionModel.self) var repModel
//    
//    @Binding var navTitle: String?
//    @Binding var refreshTask: Task<Void, Error>?
//    @Binding var longPollTask: Task<Void, Error>?
//    
//    let downloadEverything: (_ setDefaultPayMethod: Bool, _ createNewStructs: Bool, _ refreshTechnique: RefreshTechnique) async -> Void
//    let longPollServerForChanges: () async -> Void
//    let logout: () -> Void
//    
//    @State private var showSettings = false
//    @GestureState var gestureOffset: CGFloat = 0
//    
//    @FocusState private var focusedField: Int?
//    @FocusState private var searchFocus: Int?
//    @State private var showKeyboardToolbar = false
//        
//    var body: some View {
//        @Bindable var navManager = NavigationManager.shared
//        @Bindable var calModel = calModel
//        @Bindable var vm = vm
//        @Bindable var appState = AppState.shared
//        
//        let sideBarWidth = getRect().width - 90
//            
//        HStack(spacing: 0) {
//            NavigationStack {
//                NavSidebar()
//                    .navigationTitle("Menu")
//                    .navigationBarTitleDisplayMode(.inline)
//                    .toolbar {
//                        ToolbarItem(placement: .topBarLeading) {
//                            Button {
//                                showSettings = true
//                            } label: {
//                                Image(systemName: "gear")
//                            }
//                            
//                        }
//                    }
//            }
//            
//            VStack {
//                NavigationStack {
//                    //CalendarViewPhone(downloadEverything: downloadEverything, showMenu: $showMenu, selectedDay: $selectedDay)
//                    switch navManager.selection {
//                    case .january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december, .lastDecember, .nextJanuary:
//                        CalendarViewPhone(downloadEverything: downloadEverything, longPollServerForChanges: longPollServerForChanges, focusedField: $focusedField, searchFocus: $searchFocus, showMenu: showMenu, showInfo: showInfo)
//                        
//                    case .repeatingTransactions:
//                        RepeatingTransactionsTable(showMenu: showMenu, downloadEverything: downloadEverything)
//                        
//                    case .paymentMethods:
//                        PayMethodsTable(showMenu: showMenu, downloadEverything: downloadEverything)
//                        
//                    case .categories:
//                        CategoriesTable(showMenu: showMenu, downloadEverything: downloadEverything)
//                        
//                    case .keywords:
//                        KeywordsTable(showMenu: showMenu, downloadEverything: downloadEverything)
//                        
//                    case .search:
//                        Text("search")
//                        
//                    case .analytics:
//                        Text("analytics")                                            
//                        
//                    case .none:
//                       EmptyView()
//                    }
//                }
//            }
//            .interactiveToasts($appState.toasts)
//            .frame(width: getRect().width)
//            .overlay {
//                Rectangle()
//                    .fill(Color.primary.opacity(Double((vm.offset / sideBarWidth) / 5)))
//                    .fill(Color.primary.opacity(Double((vm.offset / -sideBarWidth) / 5)))
//                    .ignoresSafeArea(.container, edges: .vertical)
//                    .onTapGesture {
//                        withAnimation {
//                            //buzzPhone(.success)
//                            focusedField = nil
//                            vm.showMenu = false
//                            vm.showInfo = false
//                            vm.offset = 0
//                        }
//                    }
//                    //.sensoryFeedback(.selection, trigger: vm.showMenu)
//                    //.sensoryFeedback(.selection, trigger: vm.showInfo)
//            }
//            
//            /// Don't show this loading spinner if the user has to add an initial payment method.
//            .if(AppState.shared.methsExist) {
//                $0.loadingSpinner(id: calModel.sMonth.enumID, text: "Loading…")
//            }
//            
//            .overlay {
//                //if vm.showSearchBar {
//                    VStack {
//                        VStack {
//                            StandardTextField("Search", text: $calModel.searchText, keyboardType: .text, isSearchField: true, onSubmit: {
////                                if vm.searchText.isEmpty {
////                                    //focusedField = nil
////                                    searchFocus = nil
////                                }
//                                withAnimation {
//                                    searchFocus = nil
//                                    vm.showSearchBar = false
//                                }
//                                
//                            }, onCancel: {
//                                //focusedField = nil
//                                withAnimation {
//                                    searchFocus = nil
//                                    vm.showSearchBar = false
//                                }
//                            })
//                            .focused($searchFocus, equals: .search)
//                            .submitLabel(.search)
//                            
//                            
//                            Picker("", selection: $calModel.searchWhat) {
//                                Text("Transaction Title")
//                                    .tag(CalendarSearchWhat.titles)
//                                Text("Tag")
//                                    .tag(CalendarSearchWhat.tags)
//                            }
//                            .labelsHidden()
//                            .pickerStyle(.segmented)
//                            
////                            if !vm.searchText.isEmpty {
////                                
////                                
////                                let suggestions: Array<CBTransaction> = calModel.justTransactions
////                                    .filter {
////                                        let rap = $0
////                                        /// This double ternery is here because if I edit an exisiting transaction, and clear the title, it causes the dayView to redraw; the pop-up to close; and the transaction to disappear.
////                                        return vm.searchWhat == .titles
////                                            ? (rap.title.lowercased().contains(vm.searchText.lowercased()) && rap.active)
////                                            : (rap.active && !rap.tags.filter { $0.tag.lowercased().contains(vm.searchText.lowercased()) }.isEmpty)
////                                    }
////                                    .filter {
////                                        let rap = $0
////                                        return calModel.sPayMethod?.accountType == .unifiedChecking
////                                        ? rap.payMethod?.accountType == .checking && rap.active
////                                        : calModel.sPayMethod?.accountType == .unifiedCredit
////                                            ? rap.payMethod?.accountType == .credit && rap.active
////                                            : rap.payMethod?.id == calModel.sPayMethod?.id && rap.active
////                                    }
////                                
////                                
////                                List {
////                                    ForEach(suggestions) { sug in
////                                        Text(sug.title.lowercased())
////                                            .listRowBackground(Color.clear)
////                                            .onTapGesture {
////                                                vm.searchText = sug.title
////                                                searchFocus = nil
////                                            }
////                                    }
////                                }
////                                .listStyle(.plain)
////                                .frame(height: 100)
////                            }
//                            
//                            
//                        }
//                        
//                        .padding(.horizontal, 10)
//                        .padding(.bottom, 10)
//                        //.focused($focusedField, equals: .search)
//                        .background(.ultraThickMaterial)
//                        
//                        Spacer()
//                    }
//                    //.animation(.easeOut, value: showSearchBar)
//                    
//                    .opacity(vm.showSearchBar ? 1 : 0)
//                    .transition(.move(edge: .top))
//                //}
//            }
//            
//            NavigationStack {
//                CalendarSidebar(downloadEverything: downloadEverything)
//                    .navigationTitle("\(calModel.sMonth.name) Info")
//                    .navigationBarTitleDisplayMode(.inline)
////                    .toolbar {
////                        ToolbarItem(placement: .topBarTrailing) {
////                            Button {
////                                showSettings = true
////                            } label: {
////                                Image(systemName: "gear")
////                            }
////
////                        }
////                    }
//            }
//        }
//        
//        .environment(vm)
//        .frame(width: getRect().width + sideBarWidth + sideBarWidth)
//        .offset(x: vm.offset)
//        .animation(.easeOut, value: vm.offset == 0)
//        .onChange(of: gestureOffset) { oldValue, newValue in
//            print(newValue)
//            onChange()
//        }
//        .if(viewMode != .budget) {
//            $0.gesture(
//                DragGesture(minimumDistance: 199)
//                    .updating($gestureOffset) { value, out, _ in
//                        out = value.translation.width
//                    }
//                    .onEnded(onEnd(value:))
//            )
//        }
//        .sheet(isPresented: $showSettings) {
//            SettingsView(longPollTask: $longPollTask, showSettings: $showSettings)
//        }
//        .sensoryFeedback(.selection, trigger: vm.didRespondToDrag) { oldValue, newValue in
//            !oldValue && newValue
//        }
//    }
//    
//    func showMenu() {
//        let sideBarWidth = getRect().width - 90
//        vm.showMenu = true
//        vm.offset = sideBarWidth
//    }
//    
//    func showInfo() {
//        let sideBarWidth = getRect().width - 90
//        vm.showInfo = true
//        vm.offset = -sideBarWidth
//    }
//    
//    func onChange() {
//        let sideBarWidth = getRect().width - 90
//        
//        if gestureOffset > 200 || gestureOffset < -200 {
//            if !vm.didRespondToDrag {
//                //buzzPhone(.success)
//                vm.didRespondToDrag = true
//                
//                withAnimation {
//                    if vm.showMenu {
//                        if gestureOffset < 200 {
//                            vm.showMenu = false
//                            vm.offset = 0
//                            return
//                        }
//                    } else if vm.showInfo {
//                        if gestureOffset > 200 {
//                            vm.showInfo = false
//                            focusedField = nil
//                            vm.offset = 0
//                            return
//                        }
//                    }
//                    
//                    if gestureOffset > 200 {
//                        vm.showMenu = true
//                        vm.offset = sideBarWidth
//                        return
//                        
//                    } else if gestureOffset < 200 {
//                        if NavDestination.justMonths.contains (NavigationManager.shared.selection ?? .january) {
//                            vm.showInfo = true
//                            vm.offset = -sideBarWidth
//                            return
//                        }
//                        
//                    }
//                }
//            }
//        }
//    }
//    
//    func onEnd(value: DragGesture.Value) {
//        vm.didRespondToDrag = false
//    }
//}
//
//#endif
