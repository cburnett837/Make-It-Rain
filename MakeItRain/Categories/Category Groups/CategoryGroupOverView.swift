//
//  CategoryGroupOverView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/8/25.
//

import SwiftUI

import SwiftUI
/// On iPad, we need a special view with its own navPath since this view will be presented in a sheet.
/// The reason being is without it, when you navigate to the charts, the account list will also navigate to nothing since we could be bound back to its navPath.
struct CategoryGroupOverViewWrapperIpad: View {
    @State private var navPath = NavigationPath()
    @Bindable var group: CBCategoryGroup
    @Bindable var calModel: CalendarModel
    @Bindable var catModel: CategoryModel
    
    var body: some View {
        NavigationStack(path: $navPath) {
            CategoryGroupOverView(group: group, navPath: $navPath, calModel: calModel, catModel: catModel)
        }
    }
}

struct CategoryGroupOverView: View {
    @Environment(\.dismiss) var dismiss
    //@Environment(CalendarModel.self) private var calModel
    //@Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @Bindable var calModel: CalendarModel
    @Bindable var catModel: CategoryModel
    
    @Bindable var group: CBCategoryGroup
    @Binding var navPath: NavigationPath

    @State private var editGroup: CBCategoryGroup?
    @State private var groupEditID: CBCategoryGroup.ID?
    
    @State private var transEditID: String?
    @State private var transDay: CBDay?
    
    @State private var model: CatChartViewModel
    
    init(
        group: CBCategoryGroup,
        navPath: Binding<NavigationPath>,
        calModel: CalendarModel,
        catModel: CategoryModel
    ) {
        self.group = group
        self._navPath = navPath
        self.calModel = calModel
        self.catModel = catModel
        self._model = State(wrappedValue: .init(
            isForGroup: true,
            category: nil,
            categoryGroup: group,
            calModel: calModel,
            catModel: catModel
        ))
    }
    
        
    var title: String {
        group.action == .add ? "New Category Group" : group.title
    }
    
    var body: some View {
        StandardContainerWithToolbar(.list) {
            if group.action == .add {
                ContentUnavailableView("Insights are not available when adding a new category", systemImage: "square.stack.3d.up.slash.fill")
            } else {
                //Text("Content Here")
                CatAnalyticView(
                    isForGroup: true,
                    categoryGroup: group,
                    navPath: $navPath,
                    model: model,
                    calModel: calModel,
                    catModel: catModel
                )
                TransactionList(group: group, transEditID: $transEditID, transDay: $transDay)
            }
        }
        .navigationTitle(group.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await prepareView() }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                CatChartRefreshButton(model: model)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    groupEditID = group.id
                }
                .schemeBasedForegroundStyle()
            }
            
            if AppState.shared.isIpad {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        .refreshable {
            model.fetchHistoryTime = Date()
            model.fetchHistory(setChartAsNew: true)
        }
        .onChange(of: groupEditID) { oldValue, newValue in
            if let newValue {
                editGroup = catModel.getCategoryGroup(by: newValue)
            } else {
                catModel.saveCategoryGroup(id: oldValue!)
                
                if group.action == .delete || group.action == .add {
                    if AppState.shared.isIphone {
                        navPath.removeLast()
                    } else {
                        dismiss()
                    }
                }
            }
        }
        
        .sheet(item: $editGroup, onDismiss: {
            groupEditID = nil
        }, content: { group in
            CategoryGroupEditView(group: group, editID: $groupEditID)
            #if os(macOS)
                .frame(minWidth: 500, minHeight: 700)
                .presentationSizing(.fitted)
            #endif
        })
        .transactionEditSheetAndLogic(transEditID: $transEditID, selectedDay: $transDay, extraDismissLogic: { didSave in
            if didSave {
                Task { await prepareView() }
            }
        })
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
        if group.action == .add {
            //catModel.upsert(category)
            groupEditID = group.id
        }
        
        await model.prepareView()
    }
}



fileprivate struct TransactionList: View {    
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var group: CBCategoryGroup
    @Binding var transEditID: String?
    @Binding var transDay: CBDay?
    
    var month: CBMonth? {
        calModel.months.filter({ $0.actualNum == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }).first
    }
    
    var transactions: [CBTransaction] {
        guard let month = month else { return [] }
        let trans = calModel
            .getTransactions(months: [month], cats: group.categories)
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
            TransactionListLine(trans: trans) {
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
