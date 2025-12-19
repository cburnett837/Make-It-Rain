//
//  EditTransactionView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import SwiftUI
import PhotosUI
import SafariServices
import TipKit
import MapKit


struct BabyTransEditView: View {
    @Local(\.lineItemIndicator) var lineItemIndicator
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @AppStorage("transactionTitleSuggestionType") var transactionTitleSuggestionType: TitleSuggestionType = .location

    @Environment(\.dismiss) var dismiss // <--- NO NICE THAT ONE WITH SHEETS IN A SHEET. BEWARE!.
    #if os(macOS)
    @Environment(\.openURL) var openURL
    #endif
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @Bindable var trans: CBTransaction
    @Binding var transEditID: String?
    @Bindable var day: CBDay
    
    var isTemp: Bool
    var transLocation: WhereToLookForTransaction = .normalList
    let symbolWidth: CGFloat = 26
        
    @FocusState private var focusedField: Int?
    @State private var mapModel = MapModel()
    @State private var titleColorButtonHoverColor: Color = .gray
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    @State private var showLogSheet = false
    @State private var showTagSheet = false
    @State private var showPayMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showPaymentMethodChangeAlert = false
    @State private var showDeleteAlert = false
    @State private var blockUndoCommitOnLoad = true
    @State private var blockKeywordChangeWhenViewLoads = true
    @State private var blockSuggestionsFromPopulating = false
    @State private var showTrackingOrderAndUrlFields = false
    @State private var showCamera: Bool = false
    @State private var showPhotosPicker: Bool = false
    @State private var showTopTitles: Bool = false
    @State private var showSplitSheet = false
    @State private var titleChangedTask: Task<Void, Error>?
    @State private var amountChangedTask: Task<Void, Error>?
    @State private var showUndoRedoAlert = false
    @State private var suggestedTitles: Array<CBSuggestedTitle> = []
    @State private var navPath = NavigationPath()
    @State private var isValidToSave = false
    @State private var hasAnimatedBrain = false
    /// These are just to control the animations in the options sheet. The are here so we don't see the option sheet "set up its state" when the view appears.
    @State private var showBadgeBell = false
    @State private var showHiddenEye = false

        
    let changeTransactionTitleColorTip = ChangeTransactionTitleColorTip()
    
    var title: String { trans.action == .add ? "New \(transTypeLingo)" : "Edit \(transTypeLingo)" }
    
    var transTypeLingo: String {
        if trans.payMethod?.accountType == .credit || trans.payMethod?.accountType == .loan {
            trans.amountString.contains("-") ? "Payment" : "Expense"
        } else {
            trans.amountString.contains("-") ? "Expense" : "Income"
        }
    }
    
        
    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var calModel = calModel
        @Bindable var payModel = payModel
        @Bindable var catModel = catModel
        @Bindable var keyModel = keyModel
        @Bindable var appState = AppState.shared
        
        Group {
            NavigationStack(path: $navPath) {
                StandardContainerWithToolbar(.list) {
                    content
                }
                .navigationTitle(title)
                .if(trans.relatedTransactionID != nil) { $0.navigationSubtitle("(Linked)") }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .navigationDestination(for: TransNavDestination.self) { dest in
                    switch dest {
                    case .options:
                        TevMoreOptions(
                            trans: trans,
                            showSplitSheet: $showSplitSheet,
                            isTemp: isTemp,
                            navPath: $navPath,
                            showBadgeBell: $showBadgeBell,
                            showHiddenEye: $showHiddenEye
                        )
                        
                    case .logs:
                        LogSheet(title: trans.title, itemID: trans.id, logType: .transaction)
                        
                    case .titleColorMenu:
                        TitleColorList(trans: trans, saveOnChange: false, navPath: $navPath)
                    case .tracking:
                        EmptyView()
                    case .tags:
                        EmptyView()
                    }
                }
            }
        }
        .task {
            prepareTransactionForEditing(isTemp: isTemp)
            ChangeTransactionTitleColorTip.didOpenTransaction.sendDonation()
        }
                                
        
        
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarSpacer(.fixed, placement: .topBarLeading)
        ToolbarItem(placement: .bottomBar) {
            NavigationLink(value: TransNavDestination.logs) {
                EnteredByAndUpdatedByView(enteredBy: trans.enteredBy, updatedBy: trans.updatedBy, enteredDate: trans.enteredDate, updatedDate: trans.updatedDate)
            }
        }
    }

        
    @ViewBuilder
    var content: some View {
        Section {
            titleRow
            TransactionAmountRow(amountTypeLingo: trans.amountTypeLingo, amountString: $trans.amountString) {
                amountRow
            }
        }
                
        Section {
            StandardNoteTextEditor(notes: $trans.notes, symbolWidth: symbolWidth, focusedField: _focusedField, focusID: showTrackingOrderAndUrlFields ? 5 : 2, showSymbol: true)
        }
    }
    
    
    // MARK: - SubViews
   
    @ViewBuilder
    var titleRow: some View {
        VStack {
            HStack(spacing: 0) {
                Label {
                    Text("")
                } icon: {
                    Image(systemName: "t.circle")
                        .foregroundStyle(.gray)
                }
                
                titleTextField
            }
        }
    }
    
    
    @ViewBuilder
    var titleTextField: some View {
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
            #else
            StandardTextField("Title", text: $trans.title, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
            #endif
        }
        .focused($focusedField, equals: 0)
        .overlay {
            Color.red
                .frame(height: 2)
                .opacity(trans.factorInCalculations ? 0 : 1)
        }
        
        /// Suggest top titles associated with a category if the title has not yet been entered when the category is selected.
        .onChange(of: trans.category) {
            if let newValue = $1 {
                if trans.action == .add && trans.title.isEmpty && !newValue.isNil {
                    showTopTitles = true
                }
            }
        }
    }
    
     
    var amountRow: some View {
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
                .uiKeyboardType(.custom(.numpad))
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
            /// Keep the amount in sync with the payment method at the time the payment method was changed.
            .onChange(of: trans.payMethod) { oldValue, newValue in
                if let oldValue, let newValue {
                    if (oldValue.isDebit && newValue.isCreditOrLoan) || (oldValue.isCreditOrLoan && newValue.isDebit) {
                        Helpers.plusMinus($trans.amountString)
                    }
                }
            }
        }
    }
   
        
    func prepareTransactionForEditing(isTemp: Bool) {
        /// Clear undo history.
        UndodoManager.shared.clearHistory()
        UndodoManager.shared.commitChange(trans: trans)
        
        //calModel.hilightTrans = nil
            
        /// Determine the title button color.
        titleColorButtonHoverColor = trans.color == .primary ? .gray : trans.color
        
        /// Set the transaction date to the date of the passed in day.
        if trans.date == nil && !(trans.isSmartTransaction ?? false) {
            trans.date = day.date!
        }
                
        /// Format the dollar amount.
        if trans.action != .add || trans.tempAction != .add {
            trans.amountString = trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        }
                
        /// Set a reference to the transactions ID so photos know where to go.
        FileModel.shared.fileParent = FileParent(id: trans.id, type: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction))

        /// If the transaction is new.
        if trans.action == .add && !isTemp {
            trans.amountString = ""
            
            /// Set the dummy nil category to the trans so it's not a real nil.
            trans.category = catModel.getNil()
            
            /// If the unified editing payment method is set, use it.
            if calModel.sPayMethod?.accountType == .unifiedChecking && payModel.editingDefaultAccountType == .checking {
                trans.payMethod = payModel.getEditingDefault()
            
            /// If the unified editing payment method is set, use it.
            } else if calModel.sPayMethod?.accountType == .unifiedCredit && [.credit, .loan].contains(payModel.editingDefaultAccountType) {
                trans.payMethod = payModel.getEditingDefault()
                
            } else {
                /// Add the selected viewing payment method to the transaction.
                trans.payMethod = calModel.sPayMethod
            }
                        
            #if os(iOS)
            Task {
                /// Wait a split second before adding to the day so we don't see it happen.
                try await Task.sleep(for: .seconds(0.5))
                /// Pre-add the transaction to the day so we can add photos to it before saving. Get's removed on cancel if title and payment method are blank.
                day.upsert(trans)
            }
            #else
            /// Pre-add the transaction to the day so we can add photos to it before saving. Get's removed on cancel if title and payment method are blank.
            day.upsert(trans)
            #endif
            
            
        } else if trans.tempAction == .add && isTemp {
            /// Set the dummy nil category to the trans so it's not a real nil.
            trans.category = catModel.getNil()
            
            calModel.tempTransactions.append(trans)
            trans.amountString = ""
            trans.payMethod = payModel.getEditingDefault()
            trans.action = .add
        }
        
        /// Show the tracking / url fields if there is a value in them.
        if !trans.trackingNumber.isEmpty || !trans.orderNumber.isEmpty || !trans.url.isEmpty {
            showTrackingOrderAndUrlFields = true
        }
                        
        /// Copy it so we can compare for smart saving.
        trans.deepCopy(.create)
                
        #if os(macOS)
        /// Focus on the title textfield.
        focusedField = 0
        #else
        if (trans.action == .add && !isTemp) || (trans.tempAction == .add && isTemp) {
            Task {
                /// Wait a split second so the view isn't clunky.
                //try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
                try? await Task.sleep(for: .seconds(0.5))
                focusedField = 0
            }
        }
        #endif
        
        //checkIfTransactionIsValidToSave()
        
        
        /// Remove the date from the deepCopy if editing from a smart transaction that has a date as a problem.
        /// Today's date gets assigned by default when the trans date is nil, so if the date is the only issue, the save function won't see the trans as being valid to save.
        /// By removing the date from the deepCopy, it causes the trans and it's deep copy to fail the equatble check, which will make the app save the transaction.
//        if (trans.isSmartTransaction ?? false) && (trans.smartTransactionIssue?.enumID == .missingDate || trans.smartTransactionIssue?.enumID == .missingPaymentMethodAndDate)  {
//            trans.deepCopy?.date = nil
//        }
        
        /// Protect the transaction from being updated via scene changes if it is open.
        /// Ignore this transaction if it's open and you're coming back to the app from another app (ie if bouncing back and forth between this app and a banking app).
        //calModel.transEditID = transEditID
        
        /// These are just to control the animations in the options sheet. The are here so we don't see the option sheet "set up its state" when the view appears.
        if !trans.factorInCalculations { showHiddenEye = true }
        if trans.notifyOnDueDate { showBadgeBell = true }
    }
}




