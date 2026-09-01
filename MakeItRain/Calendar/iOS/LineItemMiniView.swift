//
//  LineItemViewPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI


#if os(iOS)
struct LineItemMiniView: View {
    private enum TransactionHighlightState {
        case highlight, blur, nothing
    }
    
    @Local(\.showDebuggingInfo) var showDebuggingInfo
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarProps.self) private var calProps
    @Environment(AppStore.self) private var store
        
    @Bindable var trans: CBTransaction
    @Bindable var day: CBDay
    
    /// These 2 are @AppStorage properties, that have been lifted up to the grandparent view to help with performance.
    var lineItemIndicator: LineItemIndicator
    var phoneLineItemDisplayItem: PhoneLineItemDisplayItem
            
    @State private var transEditID: String?
    @State private var labelWidth: CGFloat = 20.0
    @State private var showDeleteAlert = false
    @State private var highlightMe = false
    @State private var highlightState: TransactionHighlightState = .nothing
    
//    @State private var showPayMethodSheet = false
//    @State private var showCategorySheet = false
    
    var amountColor: Color {
        if trans.payMethod?.isCreditOrLoan == true {
            trans.amount < 0 ? AppSettings.shared.incomeColor : colorScheme == .dark ? .gray : .totalDarkGray
        } else {
            trans.amount > 0 ? AppSettings.shared.incomeColor : colorScheme == .dark ? .gray : .totalDarkGray
        }
    }
    
//    var lineColor: Color {
//        if calModel.isInMultiSelectMode {
//            if calModel.multiSelectTransactions.map({ $0.id }).contains(trans.id) {
//                Color(.secondarySystemFill)
//            } else {
//                Color.clear
//            }
//        } else if highlightMe {
//            Color(.secondarySystemFill)
//            
//        } else if highlightState == .highlight {
//            Color(.secondarySystemFill).opacity(0.8)
//            
//        } else {
//            Color.clear
//        }
//    }
    
    var lineColor: Color {
        if calModel.multiSelectTransactions.map({ $0.id }).contains(trans.id) || highlightMe {
            Color(.secondarySystemFill)
        } else if highlightState == .highlight {
            Color.clear
            //Color(.secondarySystemFill).opacity(0.8)
        } else {
            Color.clear
        }
    }
    
    var titleColor: Color {
        trans.color == Color.white || trans.color == Color.black ? Color.primary : trans.color
    }
    
    var wasUpdatedByAnotherUser: Bool {
        trans.updatedBy.id != AppState.shared.user?.id
    }
    
    var categoryColor: Color {
        (trans.category?.isNil ?? false) ? .gray : trans.category?.color ?? .gray
    }
        
    //#warning("REGARDING HITCH: All I did here was pull the appstorage properties up to the day view, and made the transaction sheet local.")
    
    
    @State private var hideHilight = true
    @State private var animateHilight = false
    @State private var highlightStartDate = Date()
    @State private var stopHilightTask: Task<Void, Never>?
    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var calModel = calModel
        @Bindable var calProps = calProps
        detailsLineItem
            .statusIndicatorOverlay(for: trans.status)
            .padding(.horizontal, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(lineColor))
            .padding(.horizontal, 0)
            .contentShape(.rect)
            .allowsHitTesting(phoneLineItemDisplayItem == .both)
            .draggable(trans) { dragPreview }
            .onTapGesture { selectTrans() }
            .fixedSize(horizontal: false, vertical: true)
            .confirmationDialog("Delete Transaction?", isPresented: $showDeleteAlert) {
                Button("Yes", role: .destructive) {
                    trans.action = .delete
                    Task {
                        await calModel.saveTransaction(id: trans.id)
                    }
                }
                Button("No", role: .close) { showDeleteAlert = false }
            } message: {
                Text("Delete \"\(trans.title)\"?")
            }
            .overlay(
                AiAnimatedBorder(
                    startDate: highlightStartDate,
                    isAnimating: animateHilight,
                    hideHilight: hideHilight
                )
            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 4)
//                    .strokeBorder(Color.green, lineWidth: 2)
//                    .opacity(highlightState == .highlight ? 1 : 0)
//                    .padding(-2)
//            )
            /// Control the visibility of the transaction.
            .opacity(highlightState == .blur ? 0.5 : 1)
            .blur(radius: highlightState == .blur ? 3 : 0)
            
            /// Changing back to normal happens in the ``CalendarGridPhone`` task set via  `.onChange(of: calProps.tempHighlightTransId)`
//            .onChange(of: calProps.tempHighlightTransId) { oldId, newId in
//                withAnimation {
//                    if let newId {
//                        if newId == trans.id {
//                            highlightState = .highlight
//                        } else {
//                            highlightState = .blur
//                        }
//                    } else {
//                        highlightState = .nothing
//                    }
//                }
//            }
            .onChange(of: calProps.tempHighlightTransId) { oldId, newId in
                stopHilightTask?.cancel()
                
                if let newId {
                    if newId == trans.id {
                        animateHilight = true
                        
                        withAnimation { highlightState = .highlight }
                        withAnimation(.easeIn(duration: 0.15)) { hideHilight = false }
                        
                    } else {
                        withAnimation { highlightState = .blur }
                    }
                } else {
                    withAnimation { highlightState = .nothing }
                    
                    /// Keep spinning while fading out.
                    withAnimation(.easeOut(duration: 0.5)) { hideHilight = true }
                    
                    stopHilightTask = Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.5))
                        
                        guard !Task.isCancelled else {
                            return
                        }
                        
                        /// Border is now invisible.
                        animateHilight = false
                        
                        /// Reset the next animation to start at 0°.
                        highlightStartDate = Date()
                    }
                }
            }
//            .contextMenu {
//                TransactionContextMenu(
//                    trans: trans,
//                    showDeleteAlert: $showDeleteAlert,
//                    showPayMethodSheet: $showPayMethodSheet,
//                    showCategorySheet: $showCategorySheet
//                )
//                .schemeBasedTint()
//            }
//            .sheet(isPresented: $showPayMethodSheet, onDismiss: {
//                Task {
//                    await calModel.saveTransaction(id: trans.id)
//                    trans.deepCopy(.clear)
//                }
//            }) {
//                PayMethodSheet(payMethod: $trans.payMethod, whichPaymentMethods: .allExceptUnified)
//            }
//            .sheet(isPresented: $showCategorySheet, onDismiss: {
//                Task {
//                    await calModel.saveTransaction(id: trans.id)
//                    trans.deepCopy(.clear)
//                }
//            }) {
//                CategorySheet(category: $trans.category)
//            }
            /// Note about `transactionEditSheetAndLogic()`.
            /// If you move the transaction sheet here, if the date changes via the long poll, the sheet will close.
            /// If performance issues arise due to the `calProps.tranEditID` binding, and the sheet must be moved here, finish fleshing out the `trans.dateChangeViaLongPoll` idea.
            /// That essentially will tell the model that the transaction has to be moved from one day to another when the sheet closes.
    //        .transactionEditSheetAndLogic(
    //            transEditID: $calProps.transEditID,
    //            selectedDay: $calProps.selectedDay,
    //            findTransactionWhere: .constant(.normalList),
    //            resetSelectedDayOnClose: true
    //        )
    }
    
    
    
//    @ViewBuilder
//    var overlayView: some View {
//        ZStack {
//            switch trans.status {
//            case nil, .dummy, .editing:
//                EmptyView()
//
//            case .inFlight:
//                //EmptyView()
//                Image(systemName: "circle", variableValue: 0.8)
//                    .symbolRenderingMode(.palette)
//                    .symbolVariableValueMode(.draw)
//                    .foregroundStyle(Color.primary, Color.gray)
//                    .symbolEffect(.rotate, options: .repeat(.continuous).speed(8))
//
//            case .saveSuccess:
//                Image(systemName: "checkmark.circle")
//                    .symbolRenderingMode(.palette)
//                    .foregroundStyle(Color.primary, Color.green.gradient)
//                    .transition(.symbolEffect(.drawOn.individually))
//
//            case .saveFail:
//                Image(systemName: "exclamationmark.triangle")
//                    .symbolRenderingMode(.palette)
//                    .foregroundStyle(Color.primary, Color.orange.gradient)
//                    .transition(.symbolEffect(.drawOn.individually))
//                
//            case .deleteSuccess:
//                Image(systemName: "trash.circle")
//                    .symbolRenderingMode(.palette)
//                    .foregroundStyle(Color.primary, Color.red.gradient)
//                    .transition(.symbolEffect(.drawOn.individually))
//            }
//        }
//        .contentTransition(.symbolEffect(.replace))
//        .animation(.easeInOut, value: trans.status)
//    }
    
    
    var detailsLineItem: some View {
        HStack(spacing: 2) {
            if phoneLineItemDisplayItem != .category {
                accessoryIndicator
            }
            
            if phoneLineItemDisplayItem == .title {
                Text(trans.title)
                    .font(.caption)
                    //.minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .foregroundStyle(trans.action == .add ? .gray : titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
                    .italic(wasUpdatedByAnotherUser || trans.action == .add)
                    .bold(wasUpdatedByAnotherUser)
                                    
            } else if phoneLineItemDisplayItem == .total {
                totalText
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
                    .italic(wasUpdatedByAnotherUser)
                    .bold(wasUpdatedByAnotherUser)
                
            } else if phoneLineItemDisplayItem == .category {
                Capsule()
                    .fill(
                        calModel.isUnifiedPayMethod && lineItemIndicator == .paymentMethod
                        ? (trans.payMethod?.color ?? .gray)
                        : categoryColor
                    )
                    .frame(height: 8)
                    //.frame(maxWidth: .infinity)
                    .padding(.vertical, 1)
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
                                
            } else {
                stackedTitleAndTotal
            }
            
            if phoneLineItemDisplayItem != .both && trans.notifyOnDueDate {
                notificationIndicator
            }
        }
    }
    
    
    var notificationIndicator: some View {
        Image(systemName: "clock")
        //Image(systemName: "bell.badge")
            .foregroundStyle(.secondary)
            //.symbolRenderingMode(.multicolor)
            //.font(.caption2)
            .font(.system(size: 10))
    }
    
    
    var accessoryIndicator: some View {
        Capsule()
            .fill(
                (calModel.isUnifiedPayMethod || calModel.sPayMethod == nil) && lineItemIndicator == .paymentMethod
                ? (trans.payMethod?.color ?? .gray)//.gradient
                : categoryColor//.gradient
            )
            .frame(width: 3)
            //.frame(maxHeight: .infinity)
            .padding(.vertical, 2)
                
        
//        Canvas { context, size in
//            var color: Color {
//                calModel.isUnifiedPayMethod && lineItemIndicator == .paymentMethod
//                ? (trans.payMethod?.color ?? .gray)
//                : (trans.category?.color ?? .gray)
//            }
//
//            let capsuleRect = CGRect(origin: .zero, size: size)
//            let capsulePath = Path(roundedRect: capsuleRect, cornerRadius: size.height / 2) // Full capsule effect
//
//            context.fill(capsulePath, with: .color(color.gradient))
//        }
//        .frame(width: 3)
//        //.frame(maxHeight: .infinity)
//        .padding(.vertical, 2)
    }
    
    
    var stackedTitleAndTotal: some View {
        Group {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    //Text(trans.action == .add ? "(New)" : trans.title)
                    Text(trans.title)
                        .font(.caption2)
                        .lineLimit(1)
                        //.foregroundStyle(trans.action == .add ? .gray : titleColor)
                        .foregroundStyle(titleColor)
                        //.italic(trans.action == .add)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let cunt = trans.condataOriginalCountry, cunt != calModel.sPayMethod?.country, cunt != AppState.shared.country {
                        FlagCircle(code: cunt.code, size: 10)
                        
                    } else if trans.notifyOnDueDate {
                        notificationIndicator
                    }
                }
                .overlay { ExcludeFromTotalsLine(trans: trans) }
                                
                totalText
                    //.font(.system(size: 10))
                    //.font(.custom("AmountFont", size: 10, relativeTo: .caption2))
                    .font(.caption2)
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
                
//                if showDebuggingInfo {
//                    VStack {
//                        VStack(alignment: .leading) {
//                            Text("unconv")
//                            Text("\(String(describing: trans.originalUnconvertedAmount))")
//                                .foregroundStyle(.secondary)
//                        }
//                        VStack(alignment: .leading) {
//                            Text("amount")
//                            Text("\(String(describing: trans.amount))")
//                                .foregroundStyle(.secondary)
//                        }
//                        VStack(alignment: .leading) {
//                            Text("usd")
//                            Text("\(String(describing: trans.amountUsd))")
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                    .font(.system(size: 10))
//                    //.padding(.top, 10)
//                }
                
            }
            .italic(wasUpdatedByAnotherUser)
            .bold(wasUpdatedByAnotherUser)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    var totalTextString: String {
        let setCur = AppState.shared.country.currencyCode
        let tight = AppSettings.shared.tightenUpEodTotals
        
        func strip(_ string: String) -> String {
            return CurrencyHelpers.cleanAmountString(string, currencyCode: setCur)
        }
        
        let returnMe = trans.amount.magnitude > 10_000
        ? trans.amount.kVersion(AppSettings.shared.useWholeNumbers ? 0 : 2)
        : trans.amount.currencyWithDecimals()
        
        return tight ? strip(returnMe) : returnMe
    }
    
    
    var totalText: some View {
        Text(totalTextString)
            //.minimumScaleFactor(0.8)
            .foregroundStyle(amountColor)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
      
    
    var dragPreview: some View {
        Text(trans.title)
            .padding(6)
            .background(Capsule().fill(categoryColor))
    }
   
    
    func selectTrans() {
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        trans.status = .editing
        /// Force this to `.normalList` since smart transactions will change the variable to look in the temp list.
        /// If you add a smart transaction and have to fix it, close it, and then try and open it before it has completed its trip to the server, the app will try and look in the smart list by the ID, and won't find it, thus returning you a blank transaction. So whenever you touch a line item, force the app to look inside the normal list.
        calProps.findTransactionWhere = .normalList
        //}
        /// Prevent a transaction from being opened while another one is trying to save.
        //if calModel.editLock { return }
                        
        if calModel.isInMultiSelectMode {
            
            if calModel.multiSelectTransactions.map({ $0.id }).contains(trans.id) {
                calModel.multiSelectTransactions.removeAll { $0.id == trans.id }
                
                /// See if the transaction has a related record and remove it if so.
                if let relatedId = trans.relatedTransactionID {
                    calModel.multiSelectTransactions.removeAll { $0.id == relatedId }
                }
            } else {
                calModel.multiSelectTransactions.append(trans)
                
                /// See if the transaction has a related record and add it if so.
                if let relatedId = trans.relatedTransactionID,
                    let relatedTrans = calModel.getTransaction(by: relatedId) {
                    calModel.multiSelectTransactions.append(relatedTrans)
                }
            }
        } else {
            //calModel.hilightTrans = trans
            highlightMe = true
            calProps.transEditID = trans.id
                         
            /// Remove the hilight so we don't see it animate away when we close the transaction.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                highlightMe = false
            }
        }
    }
}

#endif
