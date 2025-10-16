//
//  MultiCategorySheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/3/25.
//

import SwiftUI

struct MultiCategorySheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Local(\.colorTheme) var colorTheme
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @Binding var categories: Array<CBCategory>
    
    var showAnalyticSpecificOptions = false
                
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    @State private var labelWidth: CGFloat = 20.0
    @State private var newGroupTitle = ""
    @State private var showDeleteAlert = false
    
    @State private var deleteGroup: CBCategoryGroup?
    @State private var editGroup: CBCategoryGroup?
    @State private var groupEditID: CBCategoryGroup.ID?
    
    
    var filteredCategories: Array<CBCategory> {
        catModel.categories
            .filter { !$0.isNil }
            .filter { !$0.isHidden }
            .filter { searchText.isEmpty ? true : $0.title.localizedStandardContains(searchText) }
            .sorted {
                categorySortMode == .title
                ? $0.title.lowercased() < $1.title.lowercased()
                : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
            }
    }
    
    
    var filteredCategoryGroups: Array<CBCategoryGroup> {
        catModel.categoryGroups
            .filter { !$0.title.isEmpty }
            .filter { searchText.isEmpty ? true : $0.title.localizedStandardContains(searchText) }
            .sorted { $0.title.lowercased() < $1.title.lowercased() }
    }
    
    
    var selectedCategoryIds: [String] {
        categories
            .filter { $0.active }
            .filter { !$0.isHidden }
            .sorted { $0.id > $1.id }
            .compactMap(\.id)
    }
    
    var showCategoryGroups: Bool {
        (!searchText.isEmpty && !filteredCategoryGroups.isEmpty) || searchText.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                if filteredCategories.isEmpty {
                    ContentUnavailableView("No categories found", systemImage: "exclamationmark.magnifyingglass")
                } else {
                    if showCategoryGroups {
                        Section("Category Groups") {
                            ForEach(filteredCategoryGroups) { group in
                                CategoryGroupLine(
                                    categories: $categories,
                                    group: group,
                                    deleteGroup: $deleteGroup,
                                    showDeleteAlert: $showDeleteAlert,
                                    groupEditID: $groupEditID,
                                    selectedCategoryIds: selectedCategoryIds,
                                    labelWidth: labelWidth,
                                    getReversedColors: getReversedColors
                                )
                                .confirmationDialog("Delete \"\(deleteGroup == nil ? "N/A" : deleteGroup!.title)\"?", isPresented: $showDeleteAlert, actions: {
                                    Button("Yes", role: .destructive) {
                                        if let deleteGroup = deleteGroup {
                                            Task {
                                                await catModel.delete(deleteGroup, andSubmit: true)
                                            }
                                        }
                                    }
                                    
                                    Button("No", role: .cancel) {
                                        deleteGroup = nil
                                        showDeleteAlert = false
                                    }
                                }, message: {
                                    #if os(iOS)
                                    Text("Delete \"\(deleteGroup == nil ? "N/A" : deleteGroup!.title)\"?")
                                    #endif
                                })
                            }
                            
                            if searchText.isEmpty {
                                allExpenseCategoriesButton
                                
                                if !catModel.categories.filter({$0.isIncome}).isEmpty {
                                    allIncomeCategoriesButton
                                }
                                
                                if showAnalyticSpecificOptions {
                                    anythingWithAnAmountButton
                                }
                                
                                addNewGroupButton
                            }
                        }
                        
                        if searchText.isEmpty {
                            noneSection
                        }
                    }
                    
                    
                    Section("Your Categories") {
                        ForEach(filteredCategories) { cat in
                            MultiCategoryPickerLineItem(cat: cat, categories: $categories, labelWidth: labelWidth, selectFunction: { doit(cat) })
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text("Search Categories"))
            .navigationTitle("Categories")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { selectButton }
                ToolbarSpacer(.fixed, placement: .topBarLeading)
                ToolbarItem(placement: .topBarLeading) { sortMenu }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        
        .onChange(of: groupEditID) { oldValue, newValue in
            if let newValue {
                editGroup = catModel.getCategoryGroup(by: newValue)
            } else {
                catModel.saveCategoryGroup(id: oldValue!)
            }
        }
        
        .sheet(item: $editGroup, onDismiss: {
            groupEditID = nil
        }, content: { group in
            CategoryGroupView(group: group, editID: $groupEditID)
            #if os(macOS)
                .frame(minWidth: 500, minHeight: 700)
                .presentationSizing(.fitted)
            #endif
        })
        
        .confirmationDialog("Delete \"\(deleteGroup == nil ? "N/A" : deleteGroup!.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                if let deleteGroup = deleteGroup {
                    Task {
                        await catModel.delete(deleteGroup, andSubmit: true)
                    }
                }
            }
            
            Button("No", role: .cancel) {
                deleteGroup = nil
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(deleteGroup == nil ? "N/A" : deleteGroup!.title)\"?")
            #endif
        })
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
        
    }
    
    var noneSection: some View {
        let theNil = catModel.categories.filter { $0.isNil }.first!
        return Section("None") {
            Button {
                doit(theNil)
            } label: {
                HStack {
                    Text("None")
                        .strikethrough(true)
                    Spacer()
                    
                    Image(systemName: "checkmark")
                        .opacity(categories.filter{ $0.active }.contains(theNil) ? 1 : 0)
                }
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .contentShape(Rectangle())
            }
            #if os(macOS)
            .buttonStyle(.plain)
            #endif
        }
    }
    
    
    var allExpenseCategoriesButton: some View {
        /// Sort order is reversed to account for the offset of the circles
        let categories = catModel.categories
            .filter ({ $0.active })
            .filter ({ !$0.isHidden })
            .filter ({ !$0.isIncome })
            .sorted {
                categorySortMode == .title
                ? $0.title.lowercased() > $1.title.lowercased()
                : $0.listOrder ?? 1000000000 > $1.listOrder ?? 1000000000
            }
        
        return Button {
            withAnimation { self.categories = categories }
        } label: {
            HStack {
                Group {
                    Circle()
                        .fill(AngularGradient(gradient: Gradient(stops: getReversedColors(categories)), center: .center))
                        .frame(width: 20, height: 20)
                }
                .frame(minWidth: labelWidth, alignment: .center)
                
                Text("Expenses")
                Spacer()
                
                if selectedCategoryIds == categories.compactMap(\.id) {
                    Image(systemName: "checkmark")
                }
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .contentShape(Rectangle())
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
    }
    
    
    var allIncomeCategoriesButton: some View {
        /// Sort order is reversed to account for the offset of the circles
        let categories = catModel.categories
            .filter { $0.active }
            .filter({ $0.isIncome })
            .filter { !$0.isHidden }
            .sorted {
                categorySortMode == .title
                ? $0.title.lowercased() > $1.title.lowercased()
                : $0.listOrder ?? 1000000000 > $1.listOrder ?? 1000000000
            }
        
        return Button {
            withAnimation { self.categories = categories }
        } label: {
            HStack {
                Group {
                    Circle()
                        .fill(AngularGradient(gradient: Gradient(stops: getReversedColors(categories)), center: .center))
                        .frame(width: 20, height: 20)
                }
                .frame(minWidth: labelWidth, alignment: .center)
                
                Text("Income")
                Spacer()
                
                if selectedCategoryIds == categories.compactMap(\.id) {
                    Image(systemName: "checkmark")
                }
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .contentShape(Rectangle())
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
    }
    
    
    var anythingWithAnAmountButton: some View {
        let categories = calModel.sMonth.justTransactions
            .filter ({ $0.active })
            .filter ({ $0.amount != 0 && $0.category != nil })
            .compactMap ({ $0.category })
            .filter ({ !$0.isIncome })
            .sorted(by: {$0.id > $1.id})
            .uniqued(on: \.id)
        
        return Button {
            withAnimation { self.categories = categories }
        } label: {
            HStack {
                Group {
                    Image(systemName: "dollarsign.circle")
                }
                .frame(minWidth: labelWidth, alignment: .center)
                
                Text("Any expense category that has transactions")
                Spacer()
                
                if selectedCategoryIds == categories.compactMap(\.id) {
                    Image(systemName: "checkmark")
                }
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .contentShape(Rectangle())
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
    }
    
    
//    var anythingWithAnAmountButton: some View {
//        return Button {
//            withAnimation {
//                self.categories = calModel.sMonth.justTransactions
//                    .filter ({ $0.active })
//                    .filter ({ $0.amount != 0 && $0.category != nil })
//                    .compactMap ({ $0.category })
//                    .sorted(by: {$0.id > $1.id})
//                    .uniqued(on: \.id)
//            }
//        } label: {
//            HStack {
//                Group {
//                    Image(systemName: "dollarsign.circle")
//                }
//                .frame(minWidth: labelWidth, alignment: .center)
//                
//                Text("Any category that has transactions")
//                Spacer()
//                
//                if selectedCategoryIds == calModel.sMonth.justTransactions
//                    .filter ({ $0.active })
//                    .filter ({ $0.amount != 0 && $0.category != nil })
//                    .compactMap ({ $0.category })
//                    .sorted(by: {$0.id > $1.id})
//                    .uniqued(on: \.id)
//                    .compactMap(\.id)
//                {
//                    Image(systemName: "checkmark")
//                }
//            }
//            .foregroundStyle(colorScheme == .dark ? .white : .black)
//            .contentShape(Rectangle())
//        }
//        #if os(macOS)
//        .buttonStyle(.plain)
//        #endif
//    }
    
    
    
    
    
    var addNewGroupButton: some View {
        Button("New Group") {
            groupEditID = UUID().uuidString
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
    }
    
    
    var sortMenu: some View {
        Menu {
            Button {
                categorySortMode = .title
            } label: {
                Label {
                    Text("Title")
                } icon: {
                    Image(systemName: categorySortMode == .title ? "checkmark" : "textformat.abc")
                }
            }
            
            Button {
                categorySortMode = .listOrder
            } label: {
                Label {
                    Text("Custom")
                } icon: {
                    Image(systemName: categorySortMode == .listOrder ? "checkmark" : "list.bullet")
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
        //.buttonStyle(.glassProminent)
        //.tint(confirmButtonTint)
        //.background(confirmButtonTint)
        //.foregroundStyle(confirmButtonTint)
        //}
    }
    
    
    var groupMenu: some View {
        Menu {
            ForEach(catModel.categoryGroups) { group in
                Button(group.title) {
                    self.categories = []
                    for each in group.categories {
                        self.categories.append(each)
                    }
                }
            }
            Section {
                Button("Save As Group") {
                    let alertConfig = AlertConfig(
                        title: "Create New Group",
                        subtitle: "Enter a title for the group",
                        symbol: .init(name: "rectangle.3.group", color: Color.fromName(colorTheme)),
                        primaryButton:
                            AlertConfig.AlertButton(closeOnFunction: false, showSpinnerOnClick: false, config: .init(text: "Create", role: .primary, function: {
                                Task {
                                    let group = CBCategoryGroup()
                                    group.title = newGroupTitle
                                    for each in categories {
                                        group.categories.append(each)
                                    }
                                    
                                    catModel.upsert(group)
                                    let _ = await catModel.submit(group)
                                }
                                
                                AppState.shared.closeAlert()
                            })),
                        views: [
                            AlertConfig.ViewConfig(content: AnyView(textField))
                        ]
                    )
                    
                    AppState.shared.showAlert(config: alertConfig)
                }
            }
        } label: {
            Image(systemName: "checklist.checked")
        }
    }
    
    
    var textField: some View {
        TextField("Title", text: $newGroupTitle)
            .multilineTextAlignment(.center)
    }
    
    
    var selectButton: some View {
        Button {
            withAnimation {
                categories = categories.isEmpty ? catModel.categories : []
            }
        } label: {
            Image(systemName: categories.isEmpty ? "checklist.checked" : "checklist.unchecked")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    func doit(_ category: CBCategory) {
        if categories.map({ $0.id }).contains(category.id) {
            categories.removeAll(where: { $0.id == category.id })
        } else {
            categories.append(category)
        }
    }
    
    
    func getReversedCategories(for group: CBCategoryGroup) -> Array<CBCategory> {
         group.categories
            .filter({ $0.active })
            .sorted {
                categorySortMode == .title
                ? $0.title.lowercased() > $1.title.lowercased()
                : $0.listOrder ?? 1000000000 > $1.listOrder ?? 1000000000
            }
    }
    
    
    func getReversedColors(_ categories: Array<CBCategory>) -> Array<Gradient.Stop> {
         let colors = categories
            .filter({ $0.active })
            .sorted {
                categorySortMode == .title
                ? $0.title.lowercased() > $1.title.lowercased()
                : $0.listOrder ?? 1000000000 > $1.listOrder ?? 1000000000
            }
            .map {$0.color}
        
        
        let count = colors.count
        let step = 1.0 / Double(count)
        let epsilon = 0.00001

        // For sharp edges, we give each color two stops: start and end.
        let stops: [Gradient.Stop] = colors.enumerated().flatMap { index, color in
            let start = Double(index) * step
            let end = start + step - epsilon // Slightly before the next color's start
            return [
                Gradient.Stop(color: color, location: start),
                Gradient.Stop(color: color, location: end)
            ]
        }
        
        return stops
    }
    
    struct CategoryGroupLine: View {
        @Environment(\.colorScheme) var colorScheme
        
        @Binding var categories: Array<CBCategory>
        @Bindable var group: CBCategoryGroup
        @Binding var deleteGroup: CBCategoryGroup?
        @Binding var showDeleteAlert: Bool
        @Binding var groupEditID: String?
        var selectedCategoryIds: [String]
        var labelWidth: CGFloat
        
        var getReversedColors: (_ for: Array<CBCategory>) -> Array<Gradient.Stop>
        
        var body: some View {
            Button {
                withAnimation {
                    self.categories = group.categories.filter({ $0.active })
                }
            } label: {
                HStack {
                    Group {
                        Circle()
                            .fill(AngularGradient(gradient: Gradient(stops: getReversedColors(group.categories)), center: .center))
                            .frame(width: 20, height: 20)
                    }
                    .frame(minWidth: labelWidth, alignment: .center)
                    
                    
                    Text(group.title)
                    Spacer()
                    if selectedCategoryIds == group.categories.sorted(by: {$0.id > $1.id}).compactMap(\.id) {
                        Image(systemName: "checkmark")
                    }
                }
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .contentShape(Rectangle())
            }
            #if os(macOS)
            .buttonStyle(.plain)
            #endif
            .swipeActions(allowsFullSwipe: false) {
                DeleteGroupButton(group: group, deleteGroup: $deleteGroup, showDeleteAlert: $showDeleteAlert)
                EditGroupButton(group: group, groupEditID: $groupEditID)
            }
        }
    }
    
    
    struct DeleteGroupButton: View {
        @Bindable var group: CBCategoryGroup
        @Binding var deleteGroup: CBCategoryGroup?
        @Binding var showDeleteAlert: Bool
        
        var body: some View {
            Button {
                deleteGroup = group
                showDeleteAlert = true
            } label: {
                Label {
                    Text("Delete")
                } icon: {
                    Image(systemName: "trash")
                }
            }
            .tint(.red)
        }
    }
    
    
    struct EditGroupButton: View {
        @Bindable var group: CBCategoryGroup
        @Binding var groupEditID: String?
        
        var body: some View {
            Button {
                groupEditID = group.id
            } label: {
                Label {
                    Text("Edit")
                } icon: {
                    Image(systemName: "pencil")
                }
            }
        }
    }
}


struct MultiCategoryPickerLineItem: View {
    @Environment(\.colorScheme) var colorScheme

    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    
    var cat: CBCategory
    @Binding var categories: [CBCategory]
    var labelWidth: CGFloat
    var selectFunction: () -> Void
    
    var body: some View {
        Button {
            withAnimation { selectFunction() }
        } label: {
            HStack {
                Image(systemName: lineItemIndicator == .dot ? "circle.fill" : (cat.emoji ?? "circle.fill"))
                    .foregroundStyle(cat.color.gradient)
                    .frame(minWidth: labelWidth, alignment: .center)
                    .maxViewWidthObserver()
                Text(cat.title)
                Spacer()
                Image(systemName: "checkmark")
                    .opacity(categories.filter{ $0.active }.contains(cat) ? 1 : 0)
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .contentShape(Rectangle())
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
    }
}


