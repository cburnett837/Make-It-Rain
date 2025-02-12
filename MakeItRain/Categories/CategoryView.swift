//
//  CategoryViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI

struct CategoryView: View {
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description

    @Environment(\.dismiss) var dismiss
    @Bindable var category: CBCategory
    @Bindable var catModel: CategoryModel
    @Bindable var calModel: CalendarModel
    @Bindable var keyModel: KeywordModel
    
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
    
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    
    var title: String { category.action == .add ? "New Category" : "Edit Category" }
    
    @FocusState private var focusedField: Int?
    @State private var showSymbolPicker = false
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    var header: some View {
        Group {
            SheetHeader(
                title: title,
                close: { editID = nil; dismiss() },
                view3: { deleteButton }
            )
            .padding()
            
            Divider()
                .padding(.horizontal)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            if !AppState.shared.isLandscape { header }
            #else
            header
            #endif
            ScrollView {
                #if os(iOS)
                if AppState.shared.isLandscape { header }
                #endif
                VStack(spacing: 6) {
                    LabeledRow("Name", labelWidth) {
                        #if os(iOS)
                        StandardUITextField("Title", text: $category.title, toolbar: {
                            KeyboardToolbarView(focusedField: $focusedField)
                        })
                        .cbFocused(_focusedField, equals: 0)
                        .cbClearButtonMode(.whileEditing)
                        #else
                        StandardTextField("Title", text: $category.title, focusedField: $focusedField, focusValue: 0)
                        #endif
                    }
                    
                    LabeledRow("Budget", labelWidth) {
                        #if os(iOS)
                        StandardUITextField("Monthly Amount", text: $category.amountString ?? "", toolbar: {
                            KeyboardToolbarView(focusedField: $focusedField, accessoryImage3: "plus.forwardslash.minus", accessoryFunc3: {
                                Helpers.plusMinus($category.amountString ?? "")
                            })
                        })
                        .cbFocused(_focusedField, equals: 1)
                        .cbClearButtonMode(.whileEditing)
                        .cbKeyboardType(.decimalPad)
                        #else
                        StandardTextField("Monthly Amount", text: $category.amountString ?? "", focusedField: $focusedField, focusValue: 1)
                        #endif
                    }
                                        
                    StandardDivider()
                    
                    LabeledRow("Type", labelWidth) {
                        Picker("", selection: $category.isIncome) {
                            Text("Expense")
                                .tag(false)
                            Text("Income")
                                .tag(true)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    
                    StandardDivider()
                    
                    LabeledRow("Symbol", labelWidth) {
                        #if os(macOS)
                        HStack {
                            Button {
                                //                    Task {
                                //                        focusedField = .emoji
                                //                        try? await Task.sleep(for: .milliseconds(100))
                                //                        NSApp.orderFrontCharacterPalette($category.emoji)
                                //                    }
                                showSymbolPicker = true
                            } label: {
                                Image(systemName: category.emoji ?? "questionmark.circle.fill")
                                    .foregroundStyle(category.color)
                            }
                            .buttonStyle(.codyStandardWithHover)
                            Spacer()
                        }
                        
                        #else
                        HStack {
                            Image(systemName: category.emoji ?? "questionmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(category.color)
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showSymbolPicker = true
                        }
                        #endif
                    }
                    
                    StandardDivider()
                    
                    LabeledRow("Color", labelWidth) {
                        //ColorPickerButton(color: $category.color)
                        HStack {
                            ColorPicker("", selection: $category.color, supportsOpacity: false)
                                .labelsHidden()
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.immediately)
            .transaction { $0.animation = .none } /// stops a floater view above the keyboard toolbar            
        }
        #if os(macOS)
        .padding(.bottom, 10)
        #endif
//        #if os(iOS)
//        .keyboardToolbar(amountString: $category.amountString ?? "", focusedField: _focusedField, fields: [.title, .amount, .emoji])
//        #endif        
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        //.frame(maxWidth: .infinity)
        
        .task {
            category.deepCopy(.create)
            /// Just for formatting.
            category.amountString = category.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
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
        .confirmationDialog("Delete \"\(category.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                Task {
                    dismiss()
                    await catModel.delete(category, andSubmit: true, calModel: calModel, keyModel: keyModel)
                }
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(category.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })                        
        
        /// Just for formatting.
        .onChange(of: focusedField) { oldValue, newValue in
            if newValue == 1 {
                if category.amount == 0.0 {
                    category.amountString = ""
                }
            } else {
                if oldValue == 1 {
                    category.amountString = category.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                }
            }
        }
        .sheet(isPresented: $showSymbolPicker) {
            SymbolPicker(selected: $category.emoji)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                //.frame(width: 300)
            #endif
        }
    }
}
