//
//  CategoryOverView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/3/25.
//

import SwiftUI
/// On iPad, we need a special view with its own navPath since this view will be presented in a sheet.
/// The reason being is without it, when you navigate to the charts, the account list will also navigate to nothing since we could be bound back to its navPath.
struct CategoryOverViewWrapperIpad: View {
    @State private var navPath = NavigationPath()
    @Bindable var category: CBCategory
    @Bindable var calModel: CalendarModel
    @Bindable var catModel: CategoryModel
    
    var body: some View {
        NavigationStack(path: $navPath) {
            CategoryOverView(category: category, navPath: $navPath, calModel: calModel, catModel: catModel)
        }
    }
}

struct CategoryOverView: View {
    //@AppStorage("monthlyAnalyticChartVisibleYearCount") var chartVisibleYearCount: CategoryAnalyticChartRange = .year1
    //@AppStorage("selectedCategoryTab") var selectedTab: DetailsOrInsights = .details
    //@AppStorage("showAllCategoryChartData") var showAllChartData = false
    
    //@Local(\.incomeColor) var incomeColor
    //@Local(\.useWholeNumbers) var useWholeNumbersz
    //@AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false
    @Environment(\.dismiss) var dismiss
    //@Environment(\.dismiss) var dismiss
    //@Environment(\.colorScheme) var colorScheme
    //@Environment(CalendarModel.self) private var calModel
    //@Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @Bindable var calModel: CalendarModel
    @Bindable var catModel: CategoryModel
    
    @Bindable var category: CBCategory
    @Binding var navPath: NavigationPath

    @State private var editCategory: CBCategory?
    @State private var categoryEditID: CBCategory.ID?
    
    @State private var transEditID: String?
    @State private var transDay: CBDay?
    
    //@FocusState private var focusedField: Int?
    
    
    @State private var model: CatChartViewModel
    
    init(
        category: CBCategory,
        navPath: Binding<NavigationPath>,
        calModel: CalendarModel,
        catModel: CategoryModel
    ) {
        self.category = category
        self._navPath = navPath
        self.calModel = calModel
        self.catModel = catModel
        self._model = State(wrappedValue: .init(
            isForGroup: false,
            category: category,
            categoryGroup: nil,
            calModel: calModel,
            catModel: catModel
        ))
    }
    
    
        
    var title: String {
        category.action == .add ? "New Category" : category.title
    }
    
    var body: some View {
        StandardContainerWithToolbar(.list) {
            if category.action == .add {
                ContentUnavailableView("Insights are not available when adding a new category", systemImage: "square.stack.3d.up.slash.fill")
            } else {
                CatAnalyticView(
                    isForGroup: false,
                    category: category,
                    navPath: $navPath,
                    model: model,
                    calModel: calModel,
                    catModel: catModel
                )
                TransactionList(category: category, transEditID: $transEditID, transDay: $transDay)
            }
        }
        .if(category.appSuiteKey == .christmas) {
            $0
            .scrollContentBackground(.hidden)
            .background(SnowyBackground(blurred: true, withSnow: true))
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await prepareView() }
        .refreshable {
            model.fetchHistoryTime = Date()
            model.fetchHistory(setChartAsNew: true)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CatChartRefreshButton(model: model)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    categoryEditID = category.id
                }
                .schemeBasedForegroundStyle()
            }
            
            if AppState.shared.isIpad {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
        }
        .onChange(of: categoryEditID) { oldValue, newValue in
            if let newValue {
                editCategory = catModel.getCategory(by: newValue)
            } else {
                catModel.saveCategory(id: oldValue!, calModel: calModel, keyModel: keyModel)
                
                /// Close if deleting since it will be gone.
                /// Also close if adding, since the server will send back the real ID, and cause the list to redraw, which would cause the sheet to dismiss itself and reopen.
                /// iPhone: pop from nav.
                /// iPad: dismiss sheet.
                if category.action == .delete || category.action == .add {
                    if AppState.shared.isIphone {
                        navPath.removeLast()
                    } else {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $editCategory, onDismiss: {
            categoryEditID = nil
            
//            if calModel.categoryFilterWasSetByCategoryPage {
//                calModel.sCategories.removeAll()
//                calModel.categoryFilterWasSetByCategoryPage = false
//            }
            
        }) { cat in
            CategoryEditView(category: cat, editID: $categoryEditID)
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 700)
                .presentationSizing(.fitted)
                #else
                //.presentationSizing(.page) // big sheet
                //.presentationSizing(.fitted) // small sheet - resizable - doesn't work on iOS
                //.presentationSizing(.form) // seems to be the same as a regular sheet
                #endif
        }
        .transactionEditSheetAndLogic(transEditID: $transEditID, selectedDay: $transDay, extraDismissLogic: { didSave in
            if didSave {
                Task { await prepareView() }
            }
        })
        .onChange(of: navPath) {
            if $1.isEmpty {
                //print("killing refresh task")
                model.refreshTask?.cancel()
            }
        }
        
    }
    
    
    /// Only for iPad.
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    func prepareView() async {
        if category.action == .add {
            //catModel.upsert(category)
            categoryEditID = category.id
        }
        
        await model.prepareView()
    }
}



fileprivate struct TransactionList: View {
    //@Local(\.transactionSortMode) var transactionSortMode
    //@Local(\.categorySortMode) var categorySortMode
    //@Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var category: CBCategory
    @Binding var transEditID: String?
    @Binding var transDay: CBDay?
    
    var month: CBMonth? {
        calModel.months.filter({ $0.actualNum == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }).first
    }
    
    var transactions: [CBTransaction] {
        guard let month = month else { return [] }
        let trans = calModel
            .getTransactions(months: [month], cats: [category])
            .filter { $0.dateComponents?.day ?? 0 <= AppState.shared.todayDay }
        return trans
    }
    
    var noTransReasonText: String {
        calModel.sYear == AppState.shared.todayYear ? "No Transactions" : "Transactions will only show here for \(AppState.shared.todayYear)"
    }

    var body: some View {
        Group {
            if let month = month, !transactions.isEmpty {
                let days = month.legitDays.filter { $0.id <= AppState.shared.todayDay }.reversed()
                ForEach(days) { day in
                    let trans = getTransactions(day: day)
                    if !trans.isEmpty {
                        Section {
                            transLoop(with: trans)
                        } header: {
                            sectionHeader(for: day)
                        }
                    }
                }
            } else {
                Section {
                    ContentUnavailableView(noTransReasonText, systemImage: "square.slash.fill")
                }
            }
        }
    }
    
    
    @ViewBuilder
    func transLoop(with transactions: Array<CBTransaction>) -> some View {
        ForEach(transactions) { trans in
            TransactionListLine(trans: trans, withDate: false)
                .onTapGesture {
                    let day = month?.days.filter { $0.id == trans.dateComponents?.day }.first
                    self.transDay = day
                    self.transEditID = trans.id
                }
        }
    }
    
    
    @ViewBuilder
    func sectionHeader(for day: CBDay) -> some View {
        if let date = day.date, date.isToday {
            todayIndicatorLine
        } else {
            Text(day.date?.string(to: .monthDayShortYear) ?? "")
        }
    }
    
    
    var todayIndicatorLine: some View {
        HStack {
            Text("TODAY")
                .foregroundStyle(Color.theme)
            VStack {
                Divider()
                    .overlay(Color.theme)
            }
        }
    }
    
    
    func getTransactions(day: CBDay) -> Array<CBTransaction> {
        transactions
            .filter { $0.dateComponents?.day == day.id }
            .sorted { $0.date ?? Date() < $1.date ?? Date() }
    }
}
