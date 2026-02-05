//
//  TransactionSplitSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/1/25.
//


import SwiftUI
import PhotosUI
import SafariServices
import TipKit
import MapKit

struct TevSplitSheet: View {
    @Local(\.lineItemIndicator) var lineItemIndicator
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    
    //@Local(\.colorTheme) var colorTheme

    
    @Bindable var trans: CBTransaction
    @Binding var showSplitSheet: Bool
    
    @State private var additionalTrans: Array<CBTransaction> = []
    @FocusState private var focusedField: Int?

    @State private var originalAmount = 0.0
    
    var isValidToSave: Bool {
        if additionalTrans.isEmpty {
            return false
        }
        
        if !additionalTrans.isEmpty {
            for each in additionalTrans {
                if each.amount == 0 || each.amountString.isEmpty {
                    return false
                }
            }
            return true
        }
        
        return true
    }
    
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                HStack{
                    Text("Original Total")
                    Spacer()
                    Text(originalAmount.currencyWithDecimals())
                }
                     
                TransactionLine(title: "Original Transaction", trans: trans, additionalTrans: $additionalTrans)
                                                
                ForEach(additionalTrans) { newTrans in
                    TransactionLine(trans: newTrans, additionalTrans: $additionalTrans, showRemoveButton: true)
                }
                
                Button(action: addTrans) {
                    Text("Add Transaction")
                }
                
                //splitButton
            }
            #if os(iOS)
            .navigationTitle("Split Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { addTransButton }
                ToolbarItem(placement: .topBarTrailing) {
                    if isValidToSave {
                        closeButton
                            #if os(iOS)
                            //.tint(Color.theme)
                            //.buttonStyle(.glassProminent)
                            #endif
                    } else {
                        closeButton
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    if isValidToSave {
                        splitButton
                            #if os(iOS)
                            .tint(Color.theme)
                            .buttonStyle(.glassProminent)
                            #endif
                    } else {
                        splitButton
                            .disabled(true)
                    }
                }
            }
            #endif
        }
//        StandardContainer {
//            VStack {
//                VStack {
//                    HStack {
//                        Text("Original Total \(originalAmount.currencyWithDecimals())")
//                        Spacer()
//                    }
//                    HStack {
//                        Text("Original Transaction")
//                        Spacer()
//                    }
//                    StandardTitleTextField(symbolWidth: 26, focusedField: _focusedField, focusID: 0, showSymbol: true, parentType: XrefEnum.transaction, showTitleSuggestions: .constant(false), obj: trans)
//                    
//                    StandardAmountTextField(symbolWidth: 26, focusedField: _focusedField, focusID: 1, showSymbol: true, negativeOnFocusIfEmpty: trans.payMethod?.accountType != .credit, obj: trans)
//                        .disabled(true)
//                    
//                    categoryMenu
//                    
//                    Divider()
//                        .padding(.bottom, 12)
//                }
//                
//                
//                ForEach(additionalTrans) { newTrans in
//                    TransactionLine(trans: newTrans, additionalTrans: $additionalTrans)
//                    Divider()
//                        .padding(.bottom, 12)
//                }
//                
//                splitButton
//            }
//        } header: {
//            SheetHeader(title: "Split Transaction") {
//                trans.amountString = String(originalAmount)
//                showSplitSheet = false
//            } view1: {
//                addTransButton
//            }
//        }
        .task {
            originalAmount = trans.amount            
            addTrans()
        }
        .onChange(of: additionalTrans.map { $0.amount }) {
            let newAmount = originalAmount - $1.reduce(0, +)
            trans.amountString = newAmount.currencyWithDecimals()
        }
    }
    
    
    func addTrans() {
        let newTrans = CBTransaction(uuid: UUID().uuidString)
        newTrans.title = trans.title
        newTrans.date = trans.date
        newTrans.payMethod = trans.payMethod
        newTrans.files = trans.files
        /// Tell the server to copy over any pre-existing file records.
        newTrans.duplicateFileRecordsOnDb = true
        withAnimation {
            additionalTrans.append(newTrans)
        }
    }
    
    
    var addTransButton: some View {
        Button(action: addTrans) {
            Image(systemName: "plus")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var splitButton: some View {
        Button {
            showSplitSheet = false
                            
            if let day = calModel.sMonth.days.filter({ $0.dateComponents?.day == trans.dateComponents?.day }).first {
                for each in additionalTrans {
                    day.upsert(each)
                }
            }
            
            Task {
                await calModel.editMultiple(trans: additionalTrans)
            }
        } label: {
            Text("Perform Split")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var closeButton: some View {
        Button {
            trans.amountString =  originalAmount.currencyWithDecimals()
            showSplitSheet = false
        } label: {
            //Image(systemName: isValidToSave ? "checkmark" : "xmark")
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
        //#if os(iOS)
        //.buttonStyle(.glassProminent)
        //#endif
    }
    
    
            
//    var categoryMenu: some View {
//        HStack {
//            Group {
//                if lineItemIndicator == .dot {
//                    Image(systemName: "books.vertical.fill")
//                        .foregroundStyle((trans.category?.color ?? .gray).gradient)
//                    
//                } else if let emoji = trans.category?.emoji {
//                    Image(systemName: emoji)
//                        .foregroundStyle((trans.category?.color ?? .gray).gradient)
//                    //Text(emoji)
//                } else {
//                    Image(systemName: "books.vertical.fill")
//                        .foregroundStyle(.gray.gradient)
//                }
//            }
//            .frame(width: 26)
//            
//            CategorySheetButton(category: $trans.category)
//        }
//    }
    
    
    private struct TransactionLine: View {
        var title: String?
        @Bindable var trans: CBTransaction
        @Binding var additionalTrans: [CBTransaction]
        var showRemoveButton = false
        
        @FocusState private var focusedField: Int?
        
        var body: some View {
            Section {
                TitleRow(trans: trans)
                TransactionAmountRow(amountTypeLingo: trans.amountTypeLingo, amountString: $trans.amountString) {
                    AmountRow(trans: trans)
                }
                #if os(iOS)
                CategorySheetButtonPhone(category: $trans.category)
                #else
                CategorySheetButtonMac(category: $trans.category)
                #endif
            } header: {
                if let title = title {
                    Text(title)
                }
            } footer: {
                if showRemoveButton {
                    Button("Remove") {
                        withAnimation { additionalTrans.removeAll(where: { $0.id == trans.id }) }
                    }
                    #if os(iOS)
                    .buttonStyle(.borderedProminent)
                    #endif
                    .tint(.red)
                }
            }
        }
    }
    
    
    
    
    struct TitleRow: View {
        @Bindable var trans: CBTransaction
        @FocusState private var focusedField: Int?
        
        var body: some View {
            HStack(spacing: 0) {
                Label {
                    Text("")
                } icon: {
                    Image(systemName: "t.circle")
                        .foregroundStyle(.gray)
                }

                //Spacer()
                Group {
                    #if os(iOS)
                    UITextFieldWrapper(placeholder: "Title", text: $trans.title, onSubmit: {
                        focusedField = 1
                    }, toolbar: {
                        KeyboardToolbarView(focusedField: $focusedField)
                    })
                    .uiTag(0)
                    .uiClearButtonMode(.whileEditing)
                    .uiStartCursorAtEnd(true)
                    .uiTextAlignment(.left)
                    .uiReturnKeyType(.next)
                    .uiTextColor(UIColor(trans.color))

                    //.uiTextColor(.secondaryLabel)
                    //.uiFont(UIFont.systemFont(ofSize: 24.0))
                    #else
                    StandardTextField("Title", text: $trans.title, focusedField: $focusedField, focusValue: 0)
                        .onSubmit { focusedField = 1 }
                    #endif
                }
                .focused($focusedField, equals: 0)
            }
        }
    }
    
    
    struct AmountRow: View {
        

        @Bindable var trans: CBTransaction
        @FocusState private var focusedField: Int?
        
        var body: some View {
            HStack(spacing: 0) {
                Label {
                    Text("")
                } icon: {
                    Image(systemName: "dollarsign.circle")
                        .foregroundStyle(.gray)
                }
                
                Group {
                    #if os(iOS)
                    UITextFieldWrapper(placeholder: "Amount", text: $trans.amountString, toolbar: {
                        KeyboardToolbarView(
                            focusedField: $focusedField,
                            accessoryImage3: "plus.forwardslash.minus",
                            accessoryFunc3: {
                                Helpers.plusMinus($trans.amountString)
                            })
                    })
                    .uiTag(1)
                    .uiClearButtonMode(.whileEditing)
                    .uiStartCursorAtEnd(true)
                    .uiTextAlignment(.left)
                    //.uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                    .uiKeyboardType(.custom(.numpad))
                    //.uiKeyboardType(AppState.shared.isIpad ? .default : useWholeNumbers ? .numberPad : .decimalPad)
                    //.uiTextColor(.secondaryLabel)
                    //.uiFont(UIFont.systemFont(ofSize: 24.0))
                    #else
                    StandardTextField("Amount", text: $trans.amountString, focusedField: $focusedField, focusValue: 1)
                    #endif
                }
                .focused($focusedField, equals: 1)
                .formatCurrencyLiveAndOnUnFocus(
                    focusValue: 1,
                    focusedField: focusedField,
                    amountString: trans.amountString,
                    amountStringBinding: $trans.amountString,
                    amount: trans.amount
                )
                .onChange(of: focusedField) {
                    guard let meth = trans.payMethod else { return }
                    if $1 == 1 && trans.amountString.isEmpty && meth.isDebitOrCash {
                        trans.amountString = "-"
                    }
                }
            }
        }
    }
}
