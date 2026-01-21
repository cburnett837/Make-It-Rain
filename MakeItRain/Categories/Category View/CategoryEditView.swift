//
//  CategoryViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI
import Charts


struct CategoryEditView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    
    @Bindable var category: CBCategory
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
    
    @FocusState private var focusedField: Int?
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    @State private var showSymbolPicker = false
    @State private var showColorPicker = false

    @Namespace private var namespace
    
    
    var title: String {
        category.action == .add ? "New Category" : "Edit Category"
    }
   
    var isValidToSave: Bool {
        (category.action == .add && !category.title.isEmpty)
        || (category.hasChanges() && !category.title.isEmpty)
    }
    
    
    var body: some View {
        //let _ = Self._printChanges()
        Group {
        #if os(iOS)
            NavigationStack {
                categoryPagePhone
                    .background(Color(.systemBackground))
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) { deleteButton }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            AnimatedCloseButton(isValidToSave: isValidToSave, color: category.color, closeButton: closeButton)
                        }
                        
                        ToolbarItem(placement: .bottomBar) {
                            EnteredByAndUpdatedByView(
                                enteredBy: category.enteredBy,
                                updatedBy: category.updatedBy,
                                enteredDate: category.enteredDate,
                                updatedDate: category.updatedDate
                            )
                        }
                        .sharedBackgroundVisibility(.hidden)
                    }
            }
            #else
            VStack {
                categoryPagePhone
                .frame(maxHeight: .infinity)
                
                //fakeMacTabBar
            }
            #endif
        }
        .task {
            await prepareView()
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        
        /// Just for formatting.
        .onChange(of: focusedField) {
            if $1 == 1 {
                if category.amount == 0.0 {
                    category.amountString = ""
                }
            } else {
                if $0 == 1 {
                    category.amountString = category.amount?.currencyWithDecimals()
                }
            }
        }
        .sheet(isPresented: $showSymbolPicker) {
            SymbolPicker(selected: $category.emoji, color: category.color)
                #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            //.frame(width: 300)
                #endif
        }
    }
    
    
    
    #if os(iOS)
//    @ToolbarContentBuilder
//    func phoneToolbar() -> some ToolbarContent {
//        
//        
//        ToolbarItemGroup(placement: .topBarTrailing) {
//            //HStack(spacing: 20) {
//                deleteButton
//            //ToolbarSpacer(.fixed)
//                Button {
//                    closeSheet()
//                } label: {
//                    Image(systemName: "xmark")
//                }
//            //}
//        }
//    }
    #endif

    
    
//    var fakeMacTabBar: some View {
//        HStack(spacing: 0) {
//            Rectangle()
//                .fill(.clear)
//                .frame(height: 50)
//                .contentShape(Rectangle())
//                .overlay {
//                    Label("Details", systemImage: "list.bullet")
//                        .foregroundStyle(selectedTab == .details ? category.color : .gray)
//                }
//                .onTapGesture {
//                    selectedTab = .details
//                }
//            Rectangle()
//                .fill(.clear)
//                .frame(height: 50)
//                .contentShape(Rectangle())
//                .overlay {
//                    Label("Insights", systemImage: "chart.xyaxis.line")
//                        .foregroundStyle(selectedTab == .insights ? category.color : .gray)
//                }
//                .onTapGesture {
//                    selectedTab = .insights
//                }
//        }
//        //.fixedSize(horizontal: false, vertical: true)
//        .frame(height: 50)
//    }
    
    
    
    
    // MARK: - Category Edit Page Views
    var categoryPageMac: some View {
        StandardContainer {
            titleRow
            budgetRow
            StandardDivider()
            
            typeRow
            StandardDivider()
            
            Section {
                isHiddenRow
            } footer: {
                Text("Hide this category from **my** menus. (This will not delete any data).")
            }
            
            colorRow
            StandardDivider()
            
            symbolRow
            StandardDivider()
            
        } header: {
            SheetHeader(title: title, close: { closeSheet() }, view3: { deleteButton })
        }
    }
    
    
    var categoryPagePhone: some View {
        StandardContainerWithToolbar(.list) {
            Section {
                titleRow
                budgetRow
            } header: {
                Text("Title & Budget")
            } footer: {
                Text("Set a budget to use for each month.")
            }            
                        
            Section("Details") {
                typeRow
                symbolRow
            }
             
            Section {
                isHiddenRow
            } footer: {
                Text("Hide this category from **my** menus. (This will not delete any data).")
            }
            
        }
//        header: {
//            SheetHeader(title: title, close: { closeSheet() }, view3: { deleteButton })
//        }
    }
    
    
    var titleRow: some View {
        #if os(iOS)
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "t.circle")
                    .foregroundStyle(.gray)
            }
            
            UITextFieldWrapper(placeholder: "Title", text: $category.title, onSubmit: {
                focusedField = 1
            }, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiReturnKeyType(.next)
            //.uiFont(UIFont.systemFont(ofSize: 24.0))
            //.uiTextColor(.secondaryLabel)
        }
        .focused($focusedField, equals: 0)
        
        #else
        LabeledRow("Name", labelWidth) {
            StandardTextField("Title", text: $category.title, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
        }
        #endif
    }
       
    
    var budgetRow: some View {
        #if os(iOS)
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "chart.pie")
                    .foregroundStyle(.gray)
            }
            
            UITextFieldWrapper(placeholder: "Monthly Amount", text: $category.amountString ?? "", toolbar: {
                KeyboardToolbarView(focusedField: $focusedField, accessoryImage3: "plus.forwardslash.minus", accessoryFunc3: {
                    Helpers.plusMinus($category.amountString ?? "")
                })
            })
            .uiTag(1)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            //.uiReturnKeyType(.next)
            //.uiKeyboardType(.decimalPad)
            .uiKeyboardType(.custom(.numpad))
            //.uiTextColor(.secondaryLabel)
        }
        .focused($focusedField, equals: 1)
        
        #else
        LabeledRow("Budget", labelWidth) {
            StandardTextField("Monthly Amount", text: $category.amountString ?? "", focusedField: $focusedField, focusValue: 1)
        }
        #endif
    }
    
        
    var typeRow: some View {
        #if os(iOS)
        
        Picker(selection: $category.type) {
            Text("Expense")
                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .expense))
            Text("Income")
                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .income))
            Text("Payment")
                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .payment))
            Text("Savings")
                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .savings))
        } label: {
            Label {
                Text("Category Type")
            } icon: {
                Image(systemName: "creditcard")
                    .foregroundStyle(.gray)
            }
        }
        .pickerStyle(.menu)
        .tint(.secondary)

        
        
//        Picker("Category Type", selection: $category.type) {
//            Text("Expense")
//                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .expense))
//            Text("Income")
//                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .income))
//            Text("Payment")
//                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .payment))
//            Text("Savings")
//                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .savings))
//        }
//        .pickerStyle(.menu)
//        .tint(.secondary)
        
        #else
        LabeledRow("Type", labelWidth) {
            Picker("", selection: $category.type) {
                Text("Expense")
                    .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .expense))
                Text("Income")
                    .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .income))
                Text("Payment")
                    .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .payment))
                Text("Savings")
                    .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .savings))
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        #endif
        
    }
    
    
    var isHiddenRow: some View {
        #if os(iOS)
        Toggle(isOn: $category.isHidden.animation()) {
            Label {
                Text("Mark as Hidden")
                    .schemeBasedForegroundStyle()
            } icon: {
                Image(systemName: "eye.slash")
                    .foregroundStyle(.gray)
            }
        }
        .tint(category.color == .primary ? Color.theme : category.color)
        
        #else
        LabeledRow("Hidden", labelWidth) {
            Toggle(isOn: $category.isHidden.animation()) {
                Text("Mark as Hidden")
            }
        } subContent: {
            Text("Hide this category from view (This will not delete any data).")
        }
        #endif
        
    }
    
    
    var colorRow: some View {
        #if os(iOS)
        HStack {
            Text("Color")
            Spacer()
            StandardColorPicker(color: $category.color)
        }
        
        #else
        LabeledRow("Color", labelWidth) {
            HStack {
                ColorPicker("", selection: $category.color, supportsOpacity: false)
                    .labelsHidden()
                Capsule()
                    .fill(category.color)
                    .frame(height: 30)
                    .onTapGesture {
                        AppState.shared.showToast(title: "Color Picker", subtitle: "Touch the circle to the left to change the color.", body: nil, symbol: category.emoji ?? "theatermask.and.paintbrush", symbolColor: category.color)
                    }
            }
        }
        #endif
    }
      
    
    var symbolRow: some View {
        #if os(iOS)
        Menu {
            Button("Change Symbol") {
                showSymbolPicker = true
            }
            Button("Change Color") {
                showColorPicker = true
            }
        } label: {
            HStack {
                Label {
                    Text("Symbol")
                        .schemeBasedForegroundStyle()
                } icon: {
                    Image(systemName: "tree")
                        .foregroundStyle(.gray)
                }
                
                //Text("Symbol")
                    //.schemeBasedForegroundStyle()
                Spacer()
                Image(systemName: category.emoji ?? "questionmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(category.color.gradient)
                //Spacer()
            }
        }
        .colorPickerSheet(isPresented: $showColorPicker, selection: $category.color, supportsAlpha: false)

        
        
//        Button {
//            showSymbolPicker = true
//        } label: {
//            HStack {
//                Text("Symbol")
//                    .schemeBasedForegroundStyle()
//                Spacer()
//                Image(systemName: category.emoji ?? "questionmark.circle.fill")
//                    .font(.system(size: 24))
//                    .foregroundStyle(category.color.gradient)
//                //Spacer()
//            }
//        }
        
        #else
        LabeledRow("Symbol", labelWidth) {
            HStack {
                Image(systemName: category.emoji ?? "questionmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(category.color.gradient)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showSymbolPicker = true
            }
        }
        #endif
    }
   
    
    var closeButton: some View {
        Button {
            closeSheet()
        } label: {
            Image(systemName: isValidToSave ? "checkmark" : "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
        .tint(.none)
        .confirmationDialog("Delete \"\(category.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Delete", role: .destructive) { deleteCategory() }
            //Button("No", role: .close) { showDeleteAlert = false }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(category.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
    }
    
    
        
    // MARK: - Functions
    
    func closeSheet() {
        /// Moved to onDismiss of this sheet.
//        if calModel.categoryFilterWasSetByCategoryPage {
//            calModel.sCategories.removeAll()
//            calModel.categoryFilterWasSetByCategoryPage = false
//        }
        editID = nil
        dismiss()
        #if os(macOS)
        dismissWindow(id: "monthlyWindow")
        #endif
    }
    
    
    func prepareView() async {
        category.deepCopy(.create)
        /// Just for formatting.
        category.amountString = category.amount?.currencyWithDecimals()
        catModel.upsert(category)
        
        #if os(macOS)
        /// Focus on the title textfield.
        focusedField = 0
        #else
        if category.action == .add {
            focusedField = 0
        }
        #endif
    }
    
    
    func deleteCategory() {
        //Task {
            category.action = .delete
            dismiss()
            //await catModel.delete(category, andSubmit: true, calModel: calModel, keyModel: keyModel, eventModel: eventModel)
        //}
    }
}
