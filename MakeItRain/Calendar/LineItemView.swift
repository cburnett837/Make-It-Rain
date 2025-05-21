//
//  CalendarLineItem.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import SwiftUI

struct LineItemView: View {
    @Local(\.colorTheme) var colorTheme
    @Local(\.incomeColor) var incomeColor
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @Local(\.useWholeNumbers) var useWholeNumbers
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    //@AppStorage("macCategoryDisplayMode") var macCategoryDisplayMode: MacCategoryDisplayMode = .emoji
    @AppStorage("showHashTagsOnLineItems") var showHashTagsOnLineItems: Bool = true
    @AppStorage("showPaymentMethodIndicator") var showPaymentMethodIndicator = false
    //@AppStorage("showCategoryIndicator") var showCategoryIndicator = true
    //@AppStorage("showAccountOnUnifiedView") var showAccountOnUnifiedView = false
    
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @State private var transEditID: String?
    @State private var transDeleteID: String?
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0

    @Bindable var trans: CBTransaction
    @Bindable var day: CBDay
    var isOnCalendarView: Bool = true
    
    @FocusState var focusedField: Int?
    
    var amountColor: Color {
        if trans.payMethod?.accountType == .credit {
            trans.amount < 0 ? Color.fromName(incomeColor) : .gray
        } else {
            trans.amount > 0 ? Color.fromName(incomeColor) : .gray
        }
    }
        
    var subTextPadding: Double {
        if lineItemIndicator == .dot {
            if calModel.isUnifiedPayMethod && showPaymentMethodIndicator {
                return 22
            } else {
                return 12
            }
        } else {
            if lineItemIndicator == .emoji {
                if calModel.isUnifiedPayMethod && showPaymentMethodIndicator {
                    return 30
                } else {
                    return 20
                }
            } else { //categoryIndicator = .none
                if calModel.isUnifiedPayMethod && showPaymentMethodIndicator {
                    return 12
                } else {
                    return 12
                }
            }
            
        }
    }
    
    var lineColor: Color {
        if calModel.isInMultiSelectMode {
            if calModel.multiSelectTransactions.map({ $0.id }).contains(trans.id) {
                Color(.secondarySystemFill)
            } else {
                Color.clear
            }
        } else if calModel.hilightTrans == trans || transEditID == trans.id {
            Color(.secondarySystemFill)
        } else {
            Color.clear
        }
    }
        
    var body: some View {
        //let _ = Self._printChanges()
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                categoryIndicator
                titleView
                totalView
            }
            .overlay { ExcludeFromTotalsLine(trans: trans) }
                                                
            VStack(alignment: .leading, spacing: 2) {
                hashTagView
                notificationView
                updatedByOtherUserView
            }
            .padding(.leading, subTextPadding)
            
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .padding(.leading, isOnCalendarView ? 8 : 0)
        #if os(iOS)
        .padding(.trailing, isOnCalendarView ? 8 : 0)
        .padding(.vertical, isOnCalendarView ? 4 : 0)
        #else
        .padding(.trailing, isOnCalendarView ? 2 : 0)
        #endif
        .contentShape(Rectangle())
        .draggable(trans) { dragPreview }
        .background(RoundedRectangle(cornerRadius: 4).fill(lineColor))
        .onTapGesture(count: 1) { transactionTapped() }
        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert) {
            Button("Yes", role: .destructive) {
                trans.action = .delete
                calModel.saveTransaction(id: trans.id, day: day)            
            }
            Button("No", role: .cancel) { showDeleteAlert = false }
        } message: {
            #if os(iOS)
            Text("Delete \"\(trans.title)\"?")
            #endif
        }
        #if os(macOS)
        .contextMenu {
            TransactionContextMenu(trans: trans, transEditID: $transEditID, showDeleteAlert: $showDeleteAlert)
        }
        
        /// This `.popover(item: $transEditID) & .onChange(of: transEditID)` are used for editing existing transactions. They also exist in ``LineItemViewMac``, which are used to add new transactions.
        .popover(item: $transEditID, arrowEdge: .trailing) { id in
            TransactionEditView(trans: trans, transEditID: $transEditID, day: day, isTemp: false)
                .frame(minWidth: 320)
        }
        #else
        .sheet(item: $transEditID, onDismiss: transactionSheetDismissed) { id in
            TransactionEditView(trans: trans, transEditID: $transEditID, day: day, isTemp: false)
                .frame(minWidth: 320)                
        }
        #endif
        
        /// This onChange is needed because you can close the popover without actually clicking the close button.
        /// `popover()` has no `onDismiss()` optiion, so I need somewhere to do cleanup.
        .onChange(of: transEditID) { oldValue, newValue in
            if oldValue == nil && newValue != nil {
                focusedField = nil
            }
            
            if oldValue != nil && newValue == nil {
                /// FOR iOS...
                /// Since this view has its own `TransactionEditView` sheet, when you delete this trans, it will destory this view and mess up the animation of the sheet closing.
                /// So when deleting, retain the id and delete the transaction in the sheets `onDismiss`.
                #if os(iOS)
                if trans.action == .delete {
                    transDeleteID = oldValue!
                } else {
                    calModel.saveTransaction(id: oldValue!, day: day)
                }
                #else
                calModel.saveTransaction(id: oldValue!, day: day)
                #endif
            }
        }
        
        .task {
            /// `calModel.hilightTrans` should always be nil during a task. The only time it shouldn't should be is when a transaction was moved to a new day via a different device.
            /// If that's the case, reopen the transaction that would have been closed due to the view being destroyed and moved to a new day.
            if calModel.hilightTrans?.id == trans.id {
                transEditID = trans.id
            }
        }
    }
    
    
    var categoryIndicator: some View {
        HStack(spacing: 0) {
            /// Show the payment method on unified view/
            if calModel.isUnifiedPayMethod && showPaymentMethodIndicator {
                CircleDot(color: trans.payMethod?.color, width: 10)
            }
                                                    
            /// Show the category color dot or symbol
            if lineItemIndicator == .dot {
                CircleDot(color: trans.category?.color, width: 10)
                    .padding(.trailing, 2)
            } else {
                if let emoji = trans.category?.emoji {
                    Image(systemName: emoji)
                        .foregroundStyle(trans.category?.color ?? .primary)
                        .font(.caption2)
                        .frame(minWidth: labelWidth, alignment: .center)
                        .background {
                            GeometryReader { geo in
                                Color.clear.preference(key: MaxSizePreferenceKey.self, value: geo.size.width)
                            }
                        }
                } else {
                    CircleDot(color: .white, width: labelWidth)
                }
            }
        }
    }
    
    
    var titleView: some View {
        let isNew = trans.title.isEmpty && trans.action == .add
        let wasUpdatedByAnotherUser = trans.updatedBy.id != AppState.shared.user?.id
        
        return Text(isNew ? "New Transaction" : trans.title)
            .foregroundStyle(isNew ? .gray : trans.color)
            .if(wasUpdatedByAnotherUser && updatedByOtherUserDisplayMode == .concise) { $0.italic(true).bold(true) }
            .italic(isNew)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    var totalView: some View {
        Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
            .foregroundStyle(amountColor)
            .lineLimit(1)
    }
    
    
    var hashTagView: some View {
        Group {
            if showHashTagsOnLineItems {
                if !trans.tags.isEmpty {
                    #if os(macOS)
                    ScrollView(.horizontal) {
                        HStack(spacing: 4) {
                            ForEach(trans.tags) { tag in
                                Text("#\(tag.tag)")
                                    .foregroundStyle(.gray)
                                    .bold()
                                    .font(.caption)
                            }
                        }
                    }
                    .scrollIndicators(.never)
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
                    #else
                    TagLayout(alignment: .leading, spacing: 5) {
                        ForEach(trans.tags) { tag in
                            Text("#\(tag.tag)")
                                //.foregroundStyle(Color.fromName(colorTheme))
                                .foregroundStyle(.gray)
                                .bold()
                                .font(.caption)
                        }
                    }
                    #endif
                }
            }
        }
    }
    
    
    var notificationView: some View {
        Group {
            if trans.notifyOnDueDate {
                HStack(spacing: 2) {
                    Image(systemName: "bell")
                    let text = trans.notificationOffset == 0 ? "On day of" : (trans.notificationOffset == 1 ? "The day before" : "2 days before")
                    Text(text)
                        .lineLimit(1)
                }
                .foregroundStyle(.gray)
                .font(.caption2)
                .overlay { ExcludeFromTotalsLine(trans: trans) }
            }
        }
    }
    
    
    var updatedByOtherUserView: some View {
        Group {
            if trans.updatedBy.isNotLoggedIn && updatedByOtherUserDisplayMode == .full {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Image(systemName: "person")
                    Text("\(trans.updatedBy.initials)")
                }
                .lineLimit(1)
                .foregroundStyle(.gray)
                .font(.caption2)
                .overlay { ExcludeFromTotalsLine(trans: trans) }
            }
        }
    }
    
    
    var dragPreview: some View {
        HStack {
            Text(trans.title)
            #if os(macOS)
            Spacer()
            Text(trans.amountString)
            #endif
        }
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(trans.category?.color ?? .gray)
        }
    }
    
    
    func transactionTapped() {
        if calModel.isInMultiSelectMode {
            if calModel.multiSelectTransactions.map({ $0.id }).contains(trans.id) {
                calModel.multiSelectTransactions.removeAll(where: {$0.id == trans.id})
            } else {
                calModel.multiSelectTransactions.append(trans)
            }
        } else {
            calModel.hilightTrans = trans
            transEditID = trans.id
        }
    }
    
    
    func transactionSheetDismissed() {
        /// Only run this if deleteting to preserve animation behavior.
        if let transDeleteID = transDeleteID {
            calModel.saveTransaction(id: transDeleteID, day: day)
        } else {
            /// Just some cleanup to make sure it stays blank
            if transDeleteID != nil {
                transDeleteID = nil
            }
        }
    }
}
