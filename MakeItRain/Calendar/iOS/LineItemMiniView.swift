//
//  LineItemViewPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI


#if os(iOS)
struct LineItemMiniView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarProps.self) private var calProps
        
    @Bindable var trans: CBTransaction
    @Bindable var day: CBDay
    var lineItemIndicator: LineItemIndicator
    var phoneLineItemDisplayItem: PhoneLineItemDisplayItem
            
    //@State private var transEditID: String?
    @State private var labelWidth: CGFloat = 20.0
    @State private var showDeleteAlert = false
    @State private var hilightMe = false
    
    var amountColor: Color {
        if trans.payMethod?.accountType == .credit || trans.payMethod?.accountType == .loan {
            trans.amount < 0 ? AppSettings.shared.incomeColor : colorScheme == .dark ? .gray : .totalDarkGray
        } else {
            trans.amount > 0 ? AppSettings.shared.incomeColor : colorScheme == .dark ? .gray : .totalDarkGray
        }
    }
    
    var lineColor: Color {
        if calModel.isInMultiSelectMode {
            if calModel.multiSelectTransactions.map({ $0.id }).contains(trans.id) {
                Color(.secondarySystemFill)
            } else {
                Color.clear
            }
        } else if hilightMe {
            Color(.secondarySystemFill)
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
        
    var opacity: Double {
        switch trans.status {
        case .editing, .none: 1
        case .inFlight, .dummy, .saveSuccess, .saveFail, .deleteSucceess: 0.3
        }
    }
    
    //#warning("REGARDING HITCH: All I did here was pull the appstorage properties up to the day view, and made the transaction sheet local.")
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var calModel = calModel
        @Bindable var calProps = calProps
        Group {
            detailsLineItem
                .opacity(opacity)
                .transition(.scale)
                .overlay(alignment: .center) { overlayView }
                .padding(.horizontal, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(lineColor))
        }
        .padding(.horizontal, 0)
        .contentShape(.rect)
        .allowsHitTesting(phoneLineItemDisplayItem == .both)
//        .if(phoneLineItemDisplayItem == .both) {
//            $0
            .draggable(trans) { dragPreview }
            .onTapGesture { selectTrans() }
        //}
        
//        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert) {
//            Button("Yes", role: .destructive) {
//                trans.action = .delete
//                Task {
//                    await calModel.saveTransaction(id: trans.id)
//                }
//            }
//            Button("No", role: .close) { showDeleteAlert = false }
//        } message: {
//            Text("Delete \"\(trans.title)\"?")
//        }
//        .contextMenu {
//            TransactionContextMenu(trans: trans, transEditID: $transEditID, showDeleteAlert: $showDeleteAlert)
//        }
        
        .fixedSize(horizontal: false, vertical: true)
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
                    .symbolVariableValueMode(.draw)
                    .foregroundStyle(Color.primary, Color.gray)
                    .symbolEffect(.rotate, options: .repeat(.continuous).speed(8))

            case .saveSuccess:
                Image(systemName: "checkmark.circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, Color.green.gradient)
                    .transition(.symbolEffect(.drawOn.individually))

            case .saveFail:
                Image(systemName: "exclamationmark.triangle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, Color.orange.gradient)
                    .transition(.symbolEffect(.drawOn.individually))
                
            case .deleteSucceess:
                Image(systemName: "trash.circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, Color.red.gradient)
                    .transition(.symbolEffect(.drawOn.individually))
            }
        }
        .contentTransition(.symbolEffect(.replace))
        .animation(.easeInOut, value: trans.status)
    }
    
    
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
        Image(systemName: "bell.badge")
            .foregroundStyle(.primary)
            .symbolRenderingMode(.multicolor)
            //.font(.caption2)
            .font(.system(size: 10))
    }
    
    
    var accessoryIndicator: some View {
        Capsule()
            .fill(
                calModel.isUnifiedPayMethod && lineItemIndicator == .paymentMethod
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
                    
                    if trans.notifyOnDueDate {
                        notificationIndicator
                    }
                }
                .overlay { ExcludeFromTotalsLine(trans: trans) }
                                
                totalText
                    .font(.system(size: 10))
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
            }
            .italic(wasUpdatedByAnotherUser)
            .bold(wasUpdatedByAnotherUser)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    var totalText: some View {
        Group {
            if AppSettings.shared.useWholeNumbers && AppSettings.shared.tightenUpEodTotals {
                Text(trans.amount.currencyWithDecimals(0).replacing("$", with: "").replacing(",", with: ""))
                
            } else if AppSettings.shared.useWholeNumbers {
                Text(trans.amount.currencyWithDecimals(0))
                
            } else if !AppSettings.shared.useWholeNumbers && AppSettings.shared.tightenUpEodTotals {
                Text(trans.amount.currencyWithDecimals(2).replacing("$", with: "").replacing(",", with: ""))
                
            } else {
                Text(trans.amount.currencyWithDecimals(2))
            }
        }
        //.minimumScaleFactor(0.8)
        .foregroundStyle(amountColor)
        .lineLimit(1)
    }
      
    
    var dragPreview: some View {
        Text(trans.title)
            .padding(6)
            .background(Capsule().fill(categoryColor))
    }
   
    
    func selectTrans() {
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            trans.status = .editing
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
                if let relatedId = trans.relatedTransactionID {
                    let relatedTrans = calModel.getTransaction(by: relatedId)
                    calModel.multiSelectTransactions.append(relatedTrans)
                }
            }
        } else {
            //calModel.hilightTrans = trans
            hilightMe = true
            calProps.transEditID = trans.id
                         
            /// Remove the hilight so we don't see it animate away when we close the transaction.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                hilightMe = false
            }
        }
    }
}

#endif
