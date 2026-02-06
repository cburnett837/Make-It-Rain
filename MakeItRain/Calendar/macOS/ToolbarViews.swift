//
//  Toolbar.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import SwiftUI

#if os(macOS)

@Observable
class ToolbarAndCommandsCoordinator {
    static let shared = ToolbarAndCommandsCoordinator()
    var showPopulateAlert = false
    var showPopulateOptionsSheet = false
    var showResetMonthAlert = false
    var showResetOptionsSheet = false
}

struct CalendarToolbarLeading: View {
    
    //@AppStorage("showAccountOnUnifiedView") var showAccountOnUnifiedView = false
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarProps.self) private var calProps

    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    
    @State private var showPopulateAlert = false
    @State private var showPopulateOptionsSheet = false
    @State private var showStartingAmountsSheet = false
    @State private var showCategorySheet = false
    @State private var showPayMethodSheet = false
    
    var focusedField: FocusState<Int?>.Binding
    //@FocusState var focusedField: Int?
    
    var enumID: NavDestination = NavigationManager.shared.selection ?? .placeholderMonth
    
    var isInWindow: Bool
        
    @State private var double = 0.0
    @State private var text = ""
    
//    var formatter: NumberFormatter = {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.zeroSymbol = ""
//        return formatter
//    }()
    
    var body: some View {
        @Bindable var calModel = calModel
        @Bindable var navManager = NavigationManager.shared
        @Bindable var toolbarAndCommandsCoordinator = ToolbarAndCommandsCoordinator.shared
        
        HStack {
//            if LoadingManager.shared.showLoadingSpinner {
//                ProgressView()
//                    .tint(.none)
//                    .scaleEffect(0.5)
//            }
            
            if !isInWindow {
                addNewTransactionButton
                
                //if calModel.sYear != AppState.shared.todayYear || calModel.sMonth.num != AppState.shared.todayMonth {
                ToolbarNowButton()
                    .disabled(calModel.sYear == AppState.shared.todayYear && calModel.sMonth.num == AppState.shared.todayMonth)
                //}
                
//                PlaygroundButton()
//                    .disabled(calModel.isPlayground)
                
                previousMonthButton
                nextMonthButton
                
                Divider()
                
                //populateButton
                
                ToolbarRefreshButton()
                    .toolbarBorder()
                
                Divider()
                
                categoryButton
            }
                                    
            paymentMethodButton
            
            Divider()
                        
            startingAmountTextFields
                .disabled(isInWindow)
        }
        .alert("Woah!", isPresented: $toolbarAndCommandsCoordinator.showPopulateAlert) {
            Button("Options") {
                showPopulateOptionsSheet = true
                //calModel.populate(repTransactions: repModel.repTransactions, categories: catModel.categories)
            }
            Button("Cancel", role: .cancel) {
                
            }
        } message: {
            Text("You have already created a budget and populated this month with reoccuring transactions. If you proceed, reoccuring transactions will be duplicated.")
        }
        .sheet(isPresented: $showPopulateOptionsSheet) {
            PopulateMonthOptionsSheet()
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
        }
    }
    
    var addNewTransactionButton: some View {
        Button {
            calProps.transEditID = UUID().uuidString
            //NavigationManager.shared.selection = prev
        } label: {
            Image(systemName: "plus")
                .frame(width: 25)
        }
        .disabled(calProps.transEditID != nil)
        .toolbarBorder()
        .help("Add a new transaction to today.")
    }
    
    
    var previousMonthButton: some View {
        Button {
            var prev: NavDestination? {
                switch calModel.sMonth.enumID {
                case .lastDecember: return nil
                case .january:      return .lastDecember
                case .february:     return .january
                case .march:        return .february
                case .april:        return .march
                case .may:          return .april
                case .june:         return .may
                case .july:         return .june
                case .august:       return .july
                case .september:    return .august
                case .october:      return .september
                case .november:     return .october
                case .december:     return .november
                case .nextJanuary:  return .december
                default:            return nil
                }
            }
            NavigationManager.shared.selection = prev
        } label: {
            Image(systemName: "chevron.left")
                .frame(width: 25)
        }
        .disabled(NavigationManager.shared.selection == .lastDecember)
        .toolbarBorder()
        .help(NavigationManager.shared.selection == .lastDecember ? "Can't move to previous year": "View previous month")
    }
    
    
    var nextMonthButton: some View {
        Button {
            var next: NavDestination? {
                switch calModel.sMonth.enumID {
                case .lastDecember: return .january
                case .january:      return .february
                case .february:     return .march
                case .march:        return .april
                case .april:        return .may
                case .may:          return .june
                case .june:         return .july
                case .july:         return .august
                case .august:       return .september
                case .september:    return .october
                case .october:      return .november
                case .november:     return .december
                case .december:     return .nextJanuary
                case .nextJanuary:  return nil
                default:            return nil
                }
            }
            NavigationManager.shared.selection = next
        } label: {
            Image(systemName: "chevron.right")
                .frame(width: 25)
        }
        .disabled(NavigationManager.shared.selection == .nextJanuary)
        .toolbarBorder()
        .help(NavigationManager.shared.selection == .nextJanuary ? "Can't move to next year": "View next month")
    }
    
    
//    var populateButton: some View {
//        Button {
//            if calModel.sMonth.hasBeenPopulated {
//                ToolbarAndCommandsCoordinator.shared.showPopulateAlert = true
//            } else {
//                showPopulateOptionsSheet = true
//                //calModel.populate(repTransactions: repModel.repTransactions, categories: catModel.categories)
//            }
//        } label: {
//            Image(systemName: "arrow.triangle.branch")
//                .rotationEffect(Angle(degrees: 180))
//        }
//        .toolbarBorder()
//        .help("Populate this month with repeating transactions")
//    }
//   
    
    var categoryButton: some View {
        Group {
            @Bindable var calModel = calModel
            Button {
                showCategorySheet = true
            } label: {
                HStack(spacing: 2) {
                    if !calModel.sCategories.isEmpty {
                        var categoryFilterTitle: String {
                            let cats = calModel.sCategories
                            if cats.isEmpty {
                                return ""
                                
                            } else if cats.count == 1 {
                                return cats.first!.title
                                
                            } else if cats.count == 2 {
                                return "\(cats[0].title), \(cats[1].title)"
                                
                            } else {
                                return "\(cats[0].title), \(cats[1].title), \(cats.count - 2)+"
                            }
                        }
                        
                        Text("(\(categoryFilterTitle))")
                            .italic()
                    } else {
                        Text("Categories")
                    }
                }
                //.font(.callout)
                //.foregroundStyle(.gray)
                .contentShape(Rectangle())
                //.frame(width: 150)
            }
            .toolbarBorder()
            .sheet(isPresented: $showCategorySheet) {
                MultiCategorySheet(categories: $calModel.sCategories, categoryGroup: $calModel.sCategoryGroupsForAnalysis)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.fitted)
                //CategorySheet(category: $calModel.sCategory)
            }
        }
        
    }
    
    
    var paymentMethodButton: some View {
        Group {
            @Bindable var calModel = calModel
            Button {
                showPayMethodSheet = true
            } label: {
                HStack {
                    
                    BusinessLogo(config: .init(
                        parent: calModel.sPayMethod,
                        fallBackType: (calModel.sPayMethod ?? CBPaymentMethod()).isUnified ? .gradient : .color,
                        size: 20
                    ))
//                    
//                    Image(systemName: "circle.fill")
//                        .if(calModel.sPayMethod?.isUnified ?? false) {
//                            $0.foregroundStyle(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
//                        }
//                        .if((calModel.sPayMethod?.isUnified ?? false == false)) {
//                            $0.foregroundStyle((calModel.sPayMethod?.isUnified ?? false ? .white : calModel.sPayMethod?.color) ?? .white, .primary, .secondary)
//                        }
                    Text(calModel.sPayMethod?.title ?? "Select Account")
                }
                
                    //.frame(width: 100)
            }
            .toolbarBorder()
            .sheet(isPresented: $showPayMethodSheet, onDismiss: {
                calModel.startingAmountSheetDismissed()
            }) {
                PayMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all, showStartingAmountOption: true, showNoneOption: true)
                    .frame(minWidth: 300, minHeight: 500)
//                    .presentationSizing(.fitted)
            }
        }
    }
    
    
    var startingAmountTextFields: some View {
        Group {
            @Bindable var calModel = calModel
            let sMeth: CBPaymentMethod? = calModel.sPayMethod
                                                            
            Button {
                /// For when you reset the month
//                for meth in payModel.paymentMethods.filter({ !$0.isUnified }) {
//                    calModel.prepareStartingAmount(for: meth)
//                }
                showStartingAmountsSheet = true
            } label: {
                Text(calModel.sMonth.startingAmounts.filter { $0.payMethod.id == sMeth?.id }.first?.amount.currencyWithDecimals() ?? "0.0")
                    .contentShape(Rectangle())
                    .frame(width: 100)
                    .padding(6)
                    .foregroundStyle(.gray)
            }
            .toolbarBorder()
            .sheet(isPresented: $showStartingAmountsSheet) {
                StartingAmountSheet()
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.fitted)
            }
            .onChange(of: showStartingAmountsSheet) { oldValue, newValue in
                if !newValue {
                    let _ = calModel.calculateTotal(for: calModel.sMonth)
                    
                    Task {
                        await withTaskGroup(of: Void.self) { group in
                            let starts = calModel.sMonth.startingAmounts.filter { !$0.payMethod.isUnified }
                            for start in starts {
                                
                                if start.hasChanges() {
                                    group.addTask {
                                        await calModel.submit(start)
                                    }
                                } else {
                                    //print("No Starting amount Changes for \(start.payMethod.title)")
                                }
                            }
                        }
                    }
                }
            }
                                                
            /// Show a total limit field for credit or unified credit views.
            if sMeth?.accountType == .credit || sMeth?.accountType == .unifiedCredit || sMeth?.accountType == .loan {
                Text("of")
                    .foregroundStyle(.gray)
                
                if sMeth?.accountType == .credit || sMeth?.accountType == .loan {
                    StaticAmountText(amount: sMeth?.limit, alertText: "Please edit the credit limit from the accounts screen.")
                        .help("Current \(sMeth?.title ?? "?") credit limit")
                    
                } else {
                    let doubleAmount = payModel.paymentMethods.filter { $0.accountType == .credit || $0.accountType == .loan }.map { $0.limit ?? 0.0 }.reduce(0.0, +)
                    StaticAmountText(amount: doubleAmount, alertText: "This credit limit is auto-calculated from your other credit accounts.")
                }
            }
        }
    }
    
    
    func submitStartingAmount () {
        let _ = calModel.calculateTotal(for: calModel.sMonth)
        
        if let starting = calModel.sMonth.startingAmounts.filter({ $0.payMethod.id == calModel.sPayMethod?.id }).first {
            if !calModel.isUnifiedPayMethod {
                Task { await calModel.submit(starting) }
            }
        }
    }
    
//    var showAccountOnUnifiedViewToggle: some View {
//        Toggle(isOn: $showAccountOnUnifiedView) {
//            Text("\(showAccountOnUnifiedView ? "Hide" : "Show") account on lines")
//        }
//        .toolbarBorder()
//    }
    
    
    struct StaticAmountText: View {
        

        let amount: Double?
        let alertText: String
                
        var body: some View {
            Text(amount?.currencyWithDecimals() ?? "0.0")
                .padding(6)
                .foregroundStyle(.gray)
                .toolbarBorder()
                .onTapGesture {
                    AppState.shared.showAlert(alertText)
                }
        }
    }
    
}


struct ToolbarCenterView: View {
    @Environment(CalendarModel.self) private var calModel
    
    var enumID: NavDestination
    
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        VStack(spacing: 2) {
            Text(enumID.displayName)
                .font(.title)
        }
        .padding()
    }
}




struct CalendarToolbarTrailing: View {
    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    @Environment(\.openWindow) private var openWindow
    
    @AppStorage("calendarSplitViewPercentage") var calendarSplitViewPercentage = 0.0
    @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PlaidModel.self) private var plaidModel
    
    
    //@Binding var searchText: String
    //@Binding var searchWhat: CalendarSearchWhat
    var focusedField: FocusState<Int?>.Binding
    //@FocusState var focusedField: Int?
            
    var isInWindow: Bool
    
    @State private var showResetMonthAlert = false
    @State private var showResetOptionsSheet = false
    @State private var showAnalysisSheet = false
    @State private var showFitTransactions = false
    @State private var showMultiSelectSheet = false
    
    var body: some View {
        @Bindable var calModel = calModel
        @Bindable var toolbarAndCommandsCoordinator = ToolbarAndCommandsCoordinator.shared
        
        HStack {
            Spacer()
            if !isInWindow {
                if AppState.shared.longPollFailed { longPollButton }
                
//                if !calModel.fitTrans.filter({ !$0.isAcknowledged }).isEmpty {
//                    Button {
//                        openWindow(id: "pendingFitTransactions")
//                        //showFitTransactions = true
//                    } label: {
//                        Image(systemName: "clock.badge.exclamationmark")
//                            .foregroundStyle(.orange)
//                    }
//                    .toolbarBorder()
//                    .help("View pending fit transactions that were downloaded directly from the bank")
//                }
                
                
                Button {
                    openWindow(id: "pendingPlaidTransactions")
                    //showFitTransactions = true
                } label: {
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundStyle(plaidModel.trans.filter({ !$0.isAcknowledged }).isEmpty ? .gray : .orange)
                }
                .toolbarBorder()
                .help("View pending plaid transactions that were downloaded directly from the bank")
            
                
                
                
                Button {
                    calModel.isInMultiSelectMode.toggle()
                    //showMultiSelectSheet = true
                    
                    openWindow(id: "multiSelectSheet")
                    
                } label: {
                    Image(systemName: "rectangle.and.hand.point.up.left.filled")
                }
                .toolbarBorder()
                .help("Entere multi-select mode, where you can select multiple transactions and peform an action on them")
                
                
                Button {
                    openWindow(id: "analysisSheet")
                    //showAnalysisSheet = true
                } label: {
                    Image(systemName: "brain")
                }
                .toolbarBorder()
                .help("Open the insights sheet")
                
                displayModePicker
                
                //Divider()
                
                //resetButton
                //infoButton
                
                Divider()
            }
            
            ToolbarTextField("Search by \(calModel.searchWhat == .titles ? "title" : "tag")", text: $calModel.searchText, keyboardType: .text, isSearchField: true)
                .frame(minWidth: 150, maxWidth: 300)
                .focused(focusedField, equals: 1)
                //.toolbarBorder()
            
            Picker("Search Scope", selection: $calModel.searchWhat) {
                Text("Title")
                    .tag(CalendarSearchWhat.titles)
                Text("Tag")
                    .tag(CalendarSearchWhat.tags)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .toolbarBorder()
            .help("Change the search scope to either titles or tags")
        }
        
        .alert("Reset \(calModel.sMonth.name) \(String(calModel.sMonth.year))", isPresented: $toolbarAndCommandsCoordinator.showResetMonthAlert) {
            Button("Options", role: .destructive) {
                showResetOptionsSheet = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will be able to choose what to reset on the next page.")
        }
        .sheet(isPresented: $showResetOptionsSheet) {
            ResetMonthOptionSheet()
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
        }
//        .sheet(isPresented: $showMultiSelectSheet) {
//            MultiSelectTransactionOptionsSheet(
//                bottomPanelContent: .constant(.multiSelectOptions),
//                bottomPanelHeight: .constant(0),
//                scrollContentMargins: .constant(0),
//                showAnalysisSheet: .constant(false)
//            )
//            .frame(minWidth: 300, minHeight: 500)
//            .presentationSizing(.fitted)
//        }
        
//        .sheet(isPresented: $showAnalysisSheet) {
//            CategoryInsightsSheetshowAnalysisSheet: $showAnalysisSheet)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//        }
        
//        .sheet(isPresented: $showFitTransactions) {
//            FitTransactionOverlay(showFitTransactions: $showFitTransactions)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//        }
        
        
        
        
        
        
        
//        let relevantTransactionTitles: Array<String> = calModel
//            .sMonth
//            .justTransactions
//            .filter { $0.payMethod?.id == calModel.sPayMethod?.id }
//            .compactMap { $0.title }
//            .uniqued()
//            .filter { $0.lowercased().contains(searchText.lowercased()) }
//                
//        ForEach(relevantTransactionTitles, id: \.self) { title in
//            Text(title)
//                .searchCompletion(title)
//        }
        
    }
    
    
    
    
    var longPollButton: some View {
        Button {
            AppState.shared.showAlert("Attempting to resubscribe to multi-device updates. \nIf this keeps failing please contact the developer.")
            
            Task {
                AppState.shared.longPollFailed = false
                await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaButton)
            }
//            Task {
//                
//                
//                
//                AppState.shared.longPollFailed = false
//                await longPollServerForChanges()
//            }
        } label: {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .foregroundStyle(.red)
        }
        .help("Resubscribe to multi-device updates")
        .toolbarBorder()
    }
    
    
    var displayModePicker: some View {
        Button {
            openWindow(id: "budgetWindow")
        } label: {
            Image(systemName: "chart.pie.fill")
        }
        .help("View details of this months budget")
        .toolbarBorder()
    }
    
    
//    var resetButton: some View {
//        Button {
//            showResetMonthAlert = true
//        } label: {
//            Image("calendar.days.reset")
//                .scaleEffect(1.5)
//                .padding(.horizontal, 5)
//            //Image(systemName: "arrow.triangle.2.circlepath")
//                //.foregroundStyle(.red)
////            Image(systemName: "calendar.badge.exclamationmark")
////                .symbolRenderingMode(.palette)
////                .foregroundStyle(.red, .gray)
//        }
//        .toolbarBorder()
//        //.disabled(calModel.refreshTask != nil)
//        .help("Select options to reset this month")
//    }
    
    
//    var infoButton: some View {
//        Button {
//            
//        } label: {
//            Image(systemName: "info.circle")
//        }
//        .toolbarBorder()
//    }
}
#endif
