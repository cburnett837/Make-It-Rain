//
//  Toolbar.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import SwiftUI

#if os(macOS)

struct CalendarToolbarLeading: View {
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    //@AppStorage("showAccountOnUnifiedView") var showAccountOnUnifiedView = false
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    
    @State private var showPopulateAlert = false
    @State private var showPopulateOptionsSheet = false
    @State private var showStartingAmountsSheet = false
    @State private var showCategorySheet = false
    @State private var showPaymentMethodSheet = false
    
    
    
    
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
        
        HStack {
//            if LoadingManager.shared.showLoadingSpinner {
//                ProgressView()
//                    .tint(.none)
//                    .scaleEffect(0.5)
//            }
            
            if !isInWindow {
                previousMonthButton
                nextMonthButton
                
                //if calModel.sYear != AppState.shared.todayYear || calModel.sMonth.num != AppState.shared.todayMonth {
                ToolbarNowButton()
                    .disabled(calModel.sYear == AppState.shared.todayYear && calModel.sMonth.num == AppState.shared.todayMonth)
                //}
                Divider()
                
                populateButton
                
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
        .alert("Woah!", isPresented: $showPopulateAlert) {
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
    
    
    var populateButton: some View {
        Button {
            if calModel.sMonth.hasBeenPopulated {
                showPopulateAlert = true
            } else {
                showPopulateOptionsSheet = true
                //calModel.populate(repTransactions: repModel.repTransactions, categories: catModel.categories)
            }
        } label: {
            Image(systemName: "arrow.triangle.branch")
                .rotationEffect(Angle(degrees: 180))
        }
        .toolbarBorder()
        .help("Populate this month with repeating transactions")
    }
   
    
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
            .popover(isPresented: $showCategorySheet) {
                MultiCategorySheet(categories: $calModel.sCategories)
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
                showPaymentMethodSheet = true
            } label: {
                HStack {
                    Image(systemName: "circle.fill")
                        .if(calModel.sPayMethod?.isUnified ?? false) {
                            $0.foregroundStyle(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
                        }
                        .if((calModel.sPayMethod?.isUnified ?? false == false)) {
                            $0.foregroundStyle((calModel.sPayMethod?.isUnified ?? false ? .white : calModel.sPayMethod?.color) ?? .white, .primary, .secondary)
                        }
                    Text(calModel.sPayMethod?.title ?? "Select Payment Method")
                }
                
                    //.frame(width: 100)
            }
            .toolbarBorder()
            .popover(isPresented: $showPaymentMethodSheet) {
                PaymentMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all)
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
                for meth in payModel.paymentMethods.filter({ !$0.isUnified }) {
                    calModel.prepareStartingAmount(for: meth)
                }
                showStartingAmountsSheet = true
            } label: {
                Text(calModel.sMonth.startingAmounts.filter { $0.payMethod.id == sMeth?.id }.first?.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "0.0")
                    .contentShape(Rectangle())
                    .frame(width: 100)
                    .padding(6)
                    .foregroundStyle(.gray)
            }
            .toolbarBorder()
            .popover(isPresented: $showStartingAmountsSheet) {
                StartingAmountSheet()
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.fitted)
            }
            .onChange(of: showStartingAmountsSheet) { oldValue, newValue in
                if !newValue {
                    calModel.calculateTotalForMonth(month: calModel.sMonth)
                    Task {
                        await withTaskGroup(of: Void.self) { group in
                            let starts = calModel.sMonth.startingAmounts.filter { !$0.payMethod.isUnified }
                            print(starts)
                            for start in starts {
                                print(start.amountString)
                                group.addTask {
                                    await calModel.submit(start)
                                }
                            }
                        }
                    }
                }
            }
                                                
            /// Show a total limit field for credit or unified credit views.
            if sMeth?.accountType == .credit || sMeth?.accountType == .unifiedCredit {
                Text("of")
                    .foregroundStyle(.gray)
                
                if sMeth?.accountType == .credit {
                    StaticAmountText(amount: sMeth?.limit, alertText: "Please edit the credit limit from the payment methods screen.")
                        .help("Current \(sMeth?.title ?? "?") credit limit")
                    
                } else {
                    let doubleAmount = payModel.paymentMethods.filter { $0.accountType == .credit }.map { $0.limit ?? 0.0 }.reduce(0.0, +)
                    StaticAmountText(amount: doubleAmount, alertText: "This credit limit is auto-calculated from your other credit accounts.")
                }
            }
        }
    }
    
    
    func submitStartingAmount () {
        calModel.calculateTotalForMonth(month: calModel.sMonth)
        
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
        @AppStorage("useWholeNumbers") var useWholeNumbers = false

        let amount: Double?
        let alertText: String
                
        var body: some View {
            Text(amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "0.0")
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
    
    
    //@Binding var searchText: String
    //@Binding var searchWhat: CalendarSearchWhat
    var focusedField: FocusState<Int?>.Binding
    //@FocusState var focusedField: Int?
        
    let set5050: () -> Void
    
    var isInWindow: Bool
    
    @State private var showResetMonthAlert = false
    @State private var showResetOptionsSheet = false
    @State private var showAnalysisSheet = false
    @State private var showFitTransactions = false
    
    var body: some View {
        @Bindable var calModel = calModel
        HStack {
            Spacer()
            if !isInWindow {
                if AppState.shared.longPollFailed { longPollButton }
                
                if !calModel.fitTrans.filter({ !$0.isAcknowledged }).isEmpty {
                    Button {
                        openWindow(id: "pendingFitTransactions")
                        //showFitTransactions = true
                    } label: {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundStyle(.orange)
                    }
                    .toolbarBorder()
                }
                
                Button {
                    openWindow(id: "analysisSheet")
                    //showAnalysisSheet = true
                } label: {
                    Image(systemName: "brain")
                }
                .toolbarBorder()
                
                displayModePicker
                
                if viewMode == .split && calendarSplitViewPercentage != 50 {
                    Button("50/50", action: set5050)
                        .toolbarBorder()
                        .help("Reset the calendar and chart view ratios")
                }
                
                Divider()
                
                resetButton
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
        
        .alert("Reset \(calModel.sMonth.name) \(String(calModel.sMonth.year))", isPresented: $showResetMonthAlert) {
            Button("Options", role: .destructive) {
                showResetOptionsSheet = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will be able to choose what to reset on the next page.")
        }
        .help("Select options to reset the month")
        .sheet(isPresented: $showResetOptionsSheet) {
            ResetMonthOptionSheet()
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
        }
//        .sheet(isPresented: $showAnalysisSheet) {
//            AnalysisSheet(showAnalysisSheet: $showAnalysisSheet)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//        }
        
        .sheet(isPresented: $showFitTransactions) {
            FitTransactionOverlay(showFitTransactions: $showFitTransactions)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
        }
        
        
        
        
        
        
        
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
        .toolbarBorder()
    }
    
    
    var displayModePicker: some View {
        Picker(selection: $viewMode) {
            Image(systemName: "calendar")
                .tag(CalendarViewMode.details)
                .help("View calendar")
//            Image(systemName: "chart.pie.fill")
//                .tag(CalendarViewMode.budget)
            Image(systemName: "chart.pie.fill")
//            Image(systemName: "square.split.2x1.fill")
                .tag(CalendarViewMode.split)
                .help("View calendar and chart side-by-side")
            
        } label: {
            Text("View")
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .toolbarBorder()
        .help("Choose between the calendar and chart views")
    }
    
    
    var resetButton: some View {
        Button {
            showResetMonthAlert = true
        } label: {
            Image("calendar.days.reset")
                .scaleEffect(1.5)
                .padding(.horizontal, 5)
            //Image(systemName: "arrow.triangle.2.circlepath")
                //.foregroundStyle(.red)
//            Image(systemName: "calendar.badge.exclamationmark")
//                .symbolRenderingMode(.palette)
//                .foregroundStyle(.red, .gray)
        }
        .toolbarBorder()
        //.disabled(calModel.refreshTask != nil)
        .help("Reset all data for this month")
    }
    
    
    var infoButton: some View {
        Button {
            
        } label: {
            Image(systemName: "info.circle")
        }
        .toolbarBorder()
    }
}
#endif
