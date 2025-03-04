//
//  CalendarLineItem.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import SwiftUI

struct LineItemView: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    @AppStorage("incomeColor") var incomeColor: String = Color.blue.description
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
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
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0

    @Bindable var trans: CBTransaction
    @Bindable var day: CBDay
    
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
    
//        .padding(.leading, categoryIndicator == .dot ? (calModel.isUnifiedPayMethod && showPaymentMethodIndicator) ? 22 : 12 : (calModel.isUnifiedPayMethod && showPaymentMethodIndicator) ? 30 : 20)
//    
    
    
    var body: some View {
        //let _ = Self._printChanges()
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                // MARK: - Color Dot
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
                
                // MARK: - TITLE
                let isNew = trans.title.isEmpty && trans.action == .add
                let wasUpdatedByAnotherUser = trans.updatedBy.id != AppState.shared.user?.id
                
                Text(isNew ? "New Transaction" : trans.title)
                    .foregroundStyle(isNew ? .gray : trans.color)
                    .if(wasUpdatedByAnotherUser && updatedByOtherUserDisplayMode == .concise) { $0.italic(true).bold(true) }
                    .italic(isNew)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
                // MARK: - TOTAL
                Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .foregroundStyle(amountColor)
                    .lineLimit(1)
                
            }
            .overlay { ExcludeFromTotalsLine(trans: trans) }
                                                
            // MARK: - line 2
            VStack(alignment: .leading, spacing: 2) {
                let wasUpdatedByAnotherUser = trans.updatedBy.id != AppState.shared.user?.id
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
                                    //.foregroundStyle(Color.fromName(appColorTheme))
                                    .foregroundStyle(.gray)
                                    .bold()
                                    .font(.caption)
                            }
                        }
                        #endif
                    }
                }
                
                
                
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
                
                
                if wasUpdatedByAnotherUser && updatedByOtherUserDisplayMode == .full {
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
            .padding(.leading, subTextPadding)
            
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .padding(.leading, 8)
        #if os(iOS)
        .padding(.trailing, 8)
        .padding(.vertical, 4)
        #else
        .padding(.trailing, 2)
        #endif
        .contentShape(Rectangle())
        .draggable(trans) { dragPreview }
        .background {
            RoundedRectangle(cornerRadius: 4)
                #if os(iOS)
                .fill(calModel.hilightTrans == trans ? .gray.opacity(0.2) : .clear)
                #else
                .fill(transEditID == trans.id ? .gray.opacity(0.2) : .clear)
                #endif
        }
        .onTapGesture(count: 1) {
            calModel.hilightTrans = trans
            transEditID = trans.id
        }
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
        .popover(item: $transEditID, arrowEdge: .trailing, content: { id in
            TransactionEditView(trans: trans, transEditID: $transEditID, day: day, isTemp: false)
                .frame(minWidth: 320)
        })
        #else
        .sheet(item: $transEditID, content: { id in
            TransactionEditView(trans: trans, transEditID: $transEditID, day: day, isTemp: false)
                .frame(minWidth: 320)                
        })
        #endif
        
        .task {
            /// `calModel.hilightTrans` should always be nil during a task. The only time it shouldn't should be is when a transaction was moved to a new day via a different device.
            /// If that's the case, reopen the transaction that would have been closed due to the view being destroyed and moved to a new day.
            if calModel.hilightTrans?.id == trans.id {
                transEditID = trans.id
            }
        }
        
        /// This onChange is needed because you can close the popover without actually clicking the close button.
        /// `popover()` has no `onDismiss()` optiion, so I need somewhere to do cleanup.
        .onChange(of: transEditID, { oldValue, newValue in
            if oldValue == nil && newValue != nil {
                focusedField = nil
            }
            
            if oldValue != nil && newValue == nil {
                calModel.saveTransaction(id: oldValue!, day: day)
            }
        })
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
}
