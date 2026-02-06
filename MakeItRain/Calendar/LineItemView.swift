//
//  CalendarLineItem.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import SwiftUI

struct LineItemView: View {
    //@Local(\.colorTheme) var colorTheme
    #warning("These local properties should be moved up the view hierarchy to improve performance")
    @Local(\.updatedByOtherUserDisplayMode) var updatedByOtherUserDisplayMode
    @Local(\.lineItemIndicator) var lineItemIndicator
    //@AppStorage("macCategoryDisplayMode") var macCategoryDisplayMode: MacCategoryDisplayMode = .emoji
    @Local(\.showHashTagsOnLineItems) var showHashTagsOnLineItems
    @Local(\.showPaymentMethodIndicator) var showPaymentMethodIndicator
    //@AppStorage("showCategoryIndicator") var showCategoryIndicator = true
    //@AppStorage("showAccountOnUnifiedView") var showAccountOnUnifiedView = false
    
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @FocusState private var focusedField: Int?
    @State private var transEditID: String?
    @State private var transDeleteID: String?
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0

    @Bindable var trans: CBTransaction
    @Bindable var day: CBDay
    var isOnCalendarView: Bool = true
    
    var amountColor: Color {
        if trans.payMethod?.accountType == .credit || trans.payMethod?.accountType == .loan {
            trans.amount < 0 ? AppSettings.shared.incomeColor : .gray
        } else {
            trans.amount > 0 ? AppSettings.shared.incomeColor : .gray
        }
    }
        
//    var subTextPadding: Double {
//        if lineItemIndicator == .dot {
//            if calModel.isUnifiedPayMethod && showPaymentMethodIndicator {
//                return 22
//            } else {
//                return 12
//            }
//        } else {
//            if lineItemIndicator == .emoji {
//                if calModel.isUnifiedPayMethod && showPaymentMethodIndicator {
//                    return 30
//                } else {
//                    return 20
//                }
//            } else { //categoryIndicator = .none
//                if calModel.isUnifiedPayMethod && showPaymentMethodIndicator {
//                    return 12
//                } else {
//                    return 12
//                }
//            }
//            
//        }
//    }
    
    var lineColor: Color {
        if calModel.isInMultiSelectMode {
            if calModel.multiSelectTransactions.map({ $0.id }).contains(trans.id) {
                Color(.secondarySystemFill)
            } else {
                Color.clear
            }
        } else if /*calModel.hilightTrans == trans || */transEditID == trans.id {
            Color(.secondarySystemFill)
        } else {
            Color.clear
        }
    }
    
    var opacity: Double {
        switch trans.status {
        case .editing, .none: 1
        case .inFlight, .dummy, .saveSuccess, .saveFail, .deleteSucceess: 0.3
        }
    }
        
    var body: some View {
        @Bindable var calProps = calProps
        //let _ = Self._printChanges()
        
        HStack(alignment: lineItemIndicator == .dot ? .center : .circleAndTitle, spacing: 2) {
            categoryIndicator
                .if(lineItemIndicator != .dot) {
                    $0.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                }
                
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    titleView
                    totalView
                }
                .if(lineItemIndicator != .dot) {
                    $0.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    hashTagView
                    notificationView
                    updatedByOtherUserView
                }
            }
        }
        .overlay { ExcludeFromTotalsLine(trans: trans) }
                
//        VStack(alignment: .customHorizontalAlignment, spacing: 2) {
//            HStack(spacing: 0) {
//                categoryIndicator
//                HStack(spacing: 0) {
//                    titleView
//                    totalView
//                }
//                .alignmentGuide(.customHorizontalAlignment, computeValue: { $0[HorizontalAlignment.leading] })
//                
//            }
//            .overlay { ExcludeFromTotalsLine(trans: trans) }
//                                                
//            VStack(alignment: .leading, spacing: 2) {
//                hashTagView
//                notificationView
//                updatedByOtherUserView
//            }
//            .alignmentGuide(.customHorizontalAlignment, computeValue: { $0[HorizontalAlignment.leading] })
//            //.padding(.leading, subTextPadding)
//        }
        .opacity(opacity)
        .transition(.scale)
        .overlay(alignment: .center) { overlayView }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        #if os(iOS)
        .padding(.leading, isOnCalendarView ? 8 : 0)
        #else
        .padding(.leading, isOnCalendarView ? 4 : 0)
        #endif
        #if os(iOS)
        .padding(.trailing, isOnCalendarView ? 8 : 0)
        .padding(.vertical, isOnCalendarView ? 4 : 0)
        #else
        .padding(.trailing, isOnCalendarView ? 2 : 0)
        #endif
        .contentShape(.rect)
        .draggable(trans) { dragPreview }
        .background(RoundedRectangle(cornerRadius: 4).fill(lineColor))
        .onTapGesture(count: 1) { transactionTapped() }
        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert) {
            Button("Yes", role: .destructive) {
                trans.action = .delete
                Task {
                    await calModel.saveTransaction(id: trans.id/*, day: day*/)
                }
            }
            #if os(iOS)
            Button("No", role: .close) { showDeleteAlert = false }
            #else
            Button("No") { showDeleteAlert = false }
            #endif
        } message: {
            #if os(iOS)
            Text("Delete \"\(trans.title)\"?")
            #endif
        }
        .transactionEditSheetAndLogic(
            transEditID: $transEditID,
            selectedDay: $calProps.selectedDay,
            overviewDay: $calProps.overviewDay,
            findTransactionWhere: $calProps.findTransactionWhere,
            presentTip: true,
            resetSelectedDayOnClose: true,
        )
        #if os(macOS)
        .contextMenu {
            TransactionContextMenu(trans: trans, transEditID: $transEditID, showDeleteAlert: $showDeleteAlert)
        }
        
        /// This `.popover(item: $transEditID) & .onChange(of: transEditID)` are used for editing existing transactions. They also exist in ``LineItemViewMac``, which are used to add new transactions.
        
//        .popover(item: $transEditID, arrowEdge: .trailing) { id in
//            TransactionEditView(trans: trans, transEditID: $transEditID, day: day, isTemp: false)
//                .frame(minWidth: 320, minHeight: 320)                
//        }
        #else
//        .sheet(item: $transEditID, onDismiss: transactionSheetDismissed) { id in
//            TransactionEditView(trans: trans, transEditID: $transEditID, day: day, isTemp: false)
//                .frame(minWidth: 320)                
//        }
        #endif
        
//        /// This onChange is needed because you can close the popover without actually clicking the close button.
//        /// `popover()` has no `onDismiss()` optiion, so I need somewhere to do cleanup.
//        .onChange(of: transEditID) { oldValue, newValue in
//            if oldValue == nil && newValue != nil {
//                focusedField = nil
//            }
//            
//            if oldValue != nil && newValue == nil {
//                /// FOR iOS...
//                /// Since this view has its own `TransactionEditView` sheet, when you delete this trans, it will destory this view and mess up the animation of the sheet closing.
//                /// So when deleting, retain the id and delete the transaction in the sheets `onDismiss`.
//                #if os(iOS)
//                if trans.action == .delete {
//                    transDeleteID = oldValue!
//                } else {
//                    Task {
//                        await calModel.saveTransaction(id: oldValue!/*, day: day*/)
//                    }
//                }
//                #else
//                calModel.saveTransaction(id: oldValue!/*, day: day*/)
//                #endif
//            }
//        }
        
//        .task {
//            /// `calModel.hilightTrans` should always be nil during a task. The only time it shouldn't should be is when a transaction was moved to a new day via a different device.
//            /// If that's the case, reopen the transaction that would have been closed due to the view being destroyed and moved to a new day.
//            if calModel.hilightTrans?.id == trans.id {
//                transEditID = trans.id
//            }
//        }
    }
    
    
    var categoryIndicator: some View {
        HStack(spacing: 0) {
            /// Show the payment method on unified view or when no payment method is selected.
            if (calModel.isUnifiedPayMethod || calModel.sPayMethod == nil) && showPaymentMethodIndicator {
                CircleDot(color: trans.payMethod?.color, width: 10)
            }
                                                    
            /// Show the category color dot or symbol
            if lineItemIndicator == .dot {
                
                Capsule()
                    .fill(trans.category?.color ?? .primary)
                    .frame(width: 4)
                    .padding(.vertical, 2)
                    .padding(.trailing, 2)
                
//                CircleDot(color: trans.category?.color, width: 10)
//                    .padding(.trailing, 2)
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
        Text(trans.amount.currencyWithDecimals())
            .foregroundStyle(amountColor)
            .lineLimit(1)
    }
    
    
    @ViewBuilder
    var hashTagView: some View {
        if showHashTagsOnLineItems {
            if !trans.tags.isEmpty {
                
                
                TagLayout(alignment: .leading, spacing: 5) {
                    ForEach(trans.tags) { tag in
                        Text("#\(tag.tag)")
                            .foregroundStyle(.gray)
                            .font(.caption)
                            .padding(4)
                            #if os(iOS)
                            .background(Color(.systemGray4))
                            #else
                            .background(Color(.tertiarySystemFill))
                            #endif
                            .cornerRadius(6)
                    }
                }
                //.frame(maxWidth: 50)
                
//                    #if os(macOS)
//                    ScrollView(.horizontal) {
//                        HStack(spacing: 4) {
//                            ForEach(trans.tags) { tag in
//                                Text("#\(tag.tag)")
//                                    .foregroundStyle(.gray)
//                                    .bold()
//                                    .font(.caption)
//                            }
//                        }
//                    }
//                    .scrollIndicators(.never)
//                    .overlay { ExcludeFromTotalsLine(trans: trans) }
//                    #else
//                    TagLayout(alignment: .leading, spacing: 5) {
//                        ForEach(trans.tags) { tag in
//                            Text("#\(tag.tag)")
//                                //.foregroundStyle(Color.theme)
////                                .foregroundStyle(.gray)
////                                .bold()
////                                .font(.caption)
//
//                                .foregroundStyle(.gray)
//                                .font(.caption)
//                                .padding(4)
//                                .background(Color(.systemGray4))
//                                .cornerRadius(6)
//                        }
//                    }
//                    #endif
            }
        }
    }
    
    
    var notificationView: some View {
        Group {
            if trans.notifyOnDueDate {
                HStack(spacing: 2) {
                    Image(systemName: "alarm")
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
    
    
    @ViewBuilder
    var overlayView: some View {
        ZStack {
            switch trans.status {
            case nil, .dummy, .editing:
                EmptyView()

            case .inFlight:
                //EmptyView()
                Image(systemName: "circle", variableValue: 0.8)
                    .symbolRenderingMode(.palette)
                    #if os(iOS)
                    .symbolVariableValueMode(.draw)
                    #endif
                    .foregroundStyle(Color.primary, Color.gray)
                    .symbolEffect(.rotate, options: .repeat(.continuous).speed(8))

            case .saveSuccess:
                Image(systemName: "checkmark.circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, Color.green.gradient)
                    #if os(iOS)
                    .transition(.symbolEffect(.drawOn.individually))
                    #endif

            case .saveFail:
                Image(systemName: "exclamationmark.triangle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, Color.orange.gradient)
                    #if os(iOS)
                    .transition(.symbolEffect(.drawOn.individually))
                    #endif
                
            case .deleteSucceess:
                Image(systemName: "trash.circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, Color.red.gradient)
                    #if os(iOS)
                    .transition(.symbolEffect(.drawOn.individually))
                    #endif
            }
        }
        .contentTransition(.symbolEffect(.replace))
        .animation(.easeInOut, value: trans.status)
    }
    
    
    func transactionTapped() {
        trans.status = .editing
        
        if calModel.isInMultiSelectMode {
            if calModel.multiSelectTransactions.map({ $0.id }).contains(trans.id) {
                calModel.multiSelectTransactions.removeAll(where: { $0.id == trans.id })
            } else {
                calModel.multiSelectTransactions.append(trans)
            }
        } else {
            //calModel.hilightTrans = trans
            transEditID = trans.id
        }
    }
    
    
//    func transactionSheetDismissed() {
//        /// Only run this if deleteting to preserve animation behavior.
//        if let transDeleteID = transDeleteID {
//            Task {
//                await calModel.saveTransaction(id: transDeleteID/*, day: day*/)
//            }
//        } else {
//            /// Just some cleanup to make sure it stays blank
//            if transDeleteID != nil {
//                transDeleteID = nil
//            }
//        }
//    }
}
