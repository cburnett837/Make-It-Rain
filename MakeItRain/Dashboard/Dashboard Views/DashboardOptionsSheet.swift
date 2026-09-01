//
//  DashboardOptionsSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardOptionsSheet: View {
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    @Environment(AppStore.self) private var store
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @Bindable var model: DashboardModel
    var isForSelectedMonth: Bool
    
    @State private var showPayMethodSheet = false
    @State private var showCategorySheet = false
    
    var categoryFilterTitle: String {
        let titles = model.groups.map(\.title) + model.categories.map(\.title)
        switch titles.count {
        case 0:  return ""
        case 1:  return titles[0]
        case 2:  return "\(titles[0]), \(titles[1])"
        default: return "\(titles[0]), \(titles[1]), \(titles.count - 2)+"
        }
    }
   
    @State private var filterTitle = ""
    @State private var showFilterTitleAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Filter") {
                    showPaymentMethodSheetButton
                    showCategorySheetButton
                }
                
                if !isForSelectedMonth {
                    Section("Date Range") {
                        DatePicker(selection: $model.beginDate, displayedComponents: [.date]) {
                            Label {
                                Text("Begin Date")
                            } icon: {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.gray)
                            }
                        }
                        DatePicker(selection: $model.endDate, in: model.beginDate..., displayedComponents: [.date]) {
                            Label {
                                Text("End Date")
                            } icon: {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.gray)
                            }
                        }
                        
                        dateQuickPickers
                    }
                }
                
                Section {
                    Picker("Spending Display Type", selection: $model.shouldUseTotalSpending.animation()) {
                        Text("Actual").tag(false)
                        Text("Total").tag(true)
                    }
                } footer: {
                    Text("Choose whether to show the actual spending or the total spending. Actual Spending is your spending, offset by any money that came in.")
                }
                
                NavigationLink {
                    DashboardSavedFilterList(model: model)
                } label: {
                    Text("Saved Filters")
                }
                                
                saveFilterButton
                
                Button {
                    model.setDefaultFilter(calModel: calModel)
                } label: {
                    Text("Reset Filter")
                }
            }
            //.listStyle(.)
            //.padding()
            .navigationTitle("Dashboard Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            model.showOptionsSheet = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.none)
                }
                #else
                ToolbarItem(placement: .principal) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.none)
                    .buttonStyle(.roundMacButton)
                }
                #endif
            }
            .sheet(isPresented: $showCategorySheet, onDismiss: {
                //model.fetchIfChange(calModel: calModel)
            }) {
                MultiCategorySheet(
                    categories: $model.categories,
                    categoryGroups: $model.groups
                )
                #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                #endif
            }
            .sheet(isPresented: $showPayMethodSheet, onDismiss: {
                print("Setting new pay method id \(model.payMethod?.id ?? "0")")
                model.setMethodIds(payModel: payModel)
                //model.fetchIfChange(calModel: calModel)
            }) {
                PayMethodSheet(
                    payMethod: $model.payMethod,
                    whichPaymentMethods: .all,
                    showStartingAmountOption: false,
                    showNoneOption: true,
                    noneDescription: "Don't filter by any account and show all data."
                )
            }
        }
    }
    
    
    var saveFilterButton: some View {
        Button {
            showFilterTitleAlert = true
        } label: {
            Text("Save Current Filter")
        }
        .alert("Enter Filter Title", isPresented: $showFilterTitleAlert) {
            TextField("Filter Title", text: $filterTitle)
            Button("Save") {
                let filter = DashboardFilter(
                    title: filterTitle,
                    beginDate: model.beginDate,
                    endDate: model.endDate,
                    categories: model.categories,
                    groups: model.groups,
                    payMethod: model.payMethod
                )
                store.dashboardFilters.append(filter)
                Task {
                    await model.alterFilter(filter: filter)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Add a description of this filter.")
        }
    }
    
    @ViewBuilder
    var dateQuickPickers: some View {
        ScrollView(.horizontal) {
            HStack {
                let currentMonthName = NavDest.getMonthFromInt(AppState.shared.todayMonth)?.displayName
                Button("\(currentMonthName ?? "N/A") \(String(AppState.shared.todayYear))") {
                    let now = Date()
                    model.beginDate = now.startDateOfMonth
                    model.endDate = now.endDateOfMonth
                }
                
                Button("YTD") {
                    let now = Date()
                    model.beginDate = now.startDateOfYear
                    model.endDate = now
                }
                
                Button("This Quarter") {
                    let now = Date()
                    model.beginDate = now.startDateOfQuarter
                    model.endDate = now.endDateOfQuarter
                }
                
                Button(String(AppState.shared.todayYear)) {
                    let now = Date()
                    model.beginDate = now.startDateOfYear
                    model.endDate = now.endDateOfYear
                }
                
                ForEach(1...4, id: \.self) { q in
                    Button("Q\(q)") {
                        let now = Date()
                        let range = now.datesForQuarter(q)
                        model.beginDate = range.start
                        model.endDate = range.end
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .contentMargins(.bottom, -10, for: .scrollIndicators)
    }
    
    
    var showPaymentMethodSheetButton: some View {
        Button {
            showPayMethodSheet = true
        } label: {
            HStack {
                Label {
                    Text("Account")
                } icon: {
                    Image(systemName: "creditcard")
                        .foregroundStyle(.secondary)
//                        ..schemeBasedForegroundStyle()
    //                PayMethodLogoMashup(meth: model.payMethod)
                }
                .schemeBasedForegroundStyle()
                
                Spacer()
                
                HStack(spacing: 4) {
                    if let meth = model.payMethod {
                        HStack {
                            Text(meth.title)
                                .foregroundStyle(.gray)
                            //PayMethodLogoMashup(meth: meth)
                        }
                    } else {
                        Text("Select Account")
                            .foregroundStyle(.gray)
                    }
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .tint(.none)
                #if os(iOS)
                .foregroundStyle(Color(.secondaryLabel))
                #else
                .foregroundStyle(.secondary)
                #endif
                
                
            }
        }
        .tint(.none)
        .disabled(model.isLoading)
    }
    
    
    var showCategorySheetButton: some View {
        Button {
            showCategorySheet = true
        } label: {
            HStack {
                Label {
                    Text("Categories")
                } icon: {
                    Image(systemName: "books.vertical")
                        .foregroundStyle(.secondary)
                }
                .schemeBasedForegroundStyle()
                
                Spacer()
                
                
                HStack(spacing: 4) {
                    TextWithCircleBackground(text: "\(model.categories.count + model.groups.count)")
                        .schemeBasedForegroundStyle()
                        .padding(.trailing, 4)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .tint(.none)
                #if os(iOS)
                .foregroundStyle(Color(.secondaryLabel))
                #else
                .foregroundStyle(.secondary)
                #endif
            }
        }
        .tint(.none)
        .disabled(model.isLoading)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
}


struct DashboardSavedFilterList: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStore.self) private var store
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @Bindable var model: DashboardModel
    
    @State private var isExpanded = false
    
    var body: some View {
        Group {
            if store.dashboardFilters.isEmpty {
                ContentUnavailableView("No Saved Filters", systemImage: "bookmark.slash")
            } else {
                List(store.dashboardFilters) { philter in
                    DisclosureGroup {
                        line("Begin Date", philter.beginDate.string(to: .serverDate))
                            .disabled(model.isForSelectedMonth)
                            .strikethrough(model.isForSelectedMonth)
                        
                        line("End Date", philter.endDate.string(to: .serverDate))
                            .disabled(model.isForSelectedMonth)
                            .strikethrough(model.isForSelectedMonth)
                        
                        categoryRows(philter: philter)
                        groupRows(philter: philter)
                        
                        if let meth = philter.payMethod {
                            line("Payment Method", meth.title)
                        }
                    } label: {
                        HStack {
                            Text(philter.title)
                            Spacer()
                            Button("Apply") {
                                apply(philter: philter)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .swipeActions {
                        Button {
                            withAnimation {
                                philter.action = .delete
                                store.dashboardFilters.removeAll(where: { $0.id == philter.id })
                            }
                            Task { await model.alterFilter(filter: philter) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .tint(.red)
                        }
                    }
                }
            }
        }
        
        
        .navigationTitle("Saved Filters")
    }
    
    
    @ViewBuilder
    func categoryRows(philter: DashboardFilter) -> some View {
        if philter.categories.count > 1 {
            DisclosureGroup {
                ForEach(philter.categories) { cat in
                    CategoryLine(category: cat, labelWidth: 20, withBudget: false)
                }
            } label: {
                HStack {
                    Text("Categories")
                    Spacer()
                    TextWithCircleBackground(text: "\(model.categories.count)")
                        .schemeBasedForegroundStyle()
                }
            }
        } else {
            ForEach(philter.categories) { cat in
                line("Category", cat.title)
            }
        }
    }
    
    
    @ViewBuilder
    func groupRows(philter: DashboardFilter) -> some View {
        if philter.categories.count > 1 {
            DisclosureGroup {
                ForEach(philter.categoryGroups) { group in
                    CategoryGroupLine(group: group, withBudget: false)
                }
            } label: {
                HStack {
                    Text("Groups")
                    Spacer()
                    TextWithCircleBackground(text: "\(model.groups.count)")
                        .schemeBasedForegroundStyle()
                }
            }
        } else {
            ForEach(philter.categoryGroups) { group in
                line("Group", group.title)
            }
        }
    }
    
    
    @ViewBuilder
    func line(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.gray)
        }
    }
    
    func apply(philter: DashboardFilter) {
        if !model.isForSelectedMonth {
            model.beginDate = philter.beginDate
            model.endDate = philter.endDate
        }
        
        model.categories = philter.categories
        model.groups = philter.categoryGroups
        model.payMethod = philter.payMethod
        model.setMethodIds(payModel: payModel)
        //dismiss()
        model.showOptionsSheet = false
    }
}
