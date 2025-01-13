//
//  LineItemViewPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI

#if os(iOS)
struct LineItemMiniView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    @AppStorage("incomeColor") var incomeColor: String = Color.blue.description
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    @AppStorage("phoneLineItemTotalPosition") var phoneLineItemTotalPosition: PhoneLineItemTotalPosition = .below
    
    @Environment(CalendarModel.self) private var calModel

    @State private var labelWidth: CGFloat = 20.0
    @Binding var transEditID: String?
    @Bindable var trans: CBTransaction
    @Bindable var day: CBDay
    @Binding var putBackToBottomPanelViewOnRotate: Bool
    @State private var showDeleteAlert = false
    
    var amountColor: Color {
        if trans.payMethod?.accountType == .credit {
            trans.amount < 0 ? Color.fromName(incomeColor) : preferDarkMode ? .gray : .totalDarkGray
        } else {
            trans.amount > 0 ? Color.fromName(incomeColor) : preferDarkMode ? .gray : .totalDarkGray
        }
    }
        
    var lineColor: Color {
        if calModel.hilightTrans == trans {
            Color(.secondarySystemFill)
        } else {
            if preferDarkMode {
                Color.clear
            } else {
                trans.category?.color.opacity(0.1) ?? Color.gray.opacity(0.1)
            }
        }
    }
    
    var titleColor: Color {
        trans.color == Color.white || trans.color == Color.black ? Color.primary : trans.color
    }
    
    
    var body: some View {
        @Bindable var calModel = calModel
        Group {
            detailsLineItem
                .transition(.opacity)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(lineColor)
                        .contentShape(Rectangle())
                }
        }
        .contentShape(Rectangle())
        .draggable(trans) { dragPreview }
        .allowsHitTesting(phoneLineItemDisplayItem != .category)
        .onTapGesture {
            calModel.hilightTrans = trans
            transEditID = trans.id
        }
        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert) {
            Button("Yes", role: .destructive) {
                trans.action = .delete
                calModel.saveTransaction(id: trans.id)
            }
            Button("No", role: .cancel) { showDeleteAlert = false }
        } message: {
            Text("Delete \"\(trans.title)\"?")
        }
        .contextMenu {
            TransactionContextMenu(trans: trans, transEditID: $transEditID, showDeleteAlert: $showDeleteAlert)
        }
    }
    
    
    var detailsLineItem: some View {
        Group {
            let wasUpdatedByAnotherUser = trans.updatedBy.id != AppState.shared.user?.id
            HStack(spacing: 2) {
                if phoneLineItemDisplayItem != .category {
                    accessoryIndicator
                }
                
                if phoneLineItemDisplayItem == .title {
                    Text(trans.title)
                        .font(.caption)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .foregroundStyle(trans.color == .white || trans.color == .black ? .primary : trans.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay { ExcludeFromTotalsLine(trans: trans) }
                        .if(wasUpdatedByAnotherUser) {
                            $0.italic(true).bold(true)
                        }
                                        
                } else if phoneLineItemDisplayItem == .total {
                    totalText
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay { ExcludeFromTotalsLine(trans: trans) }
                        .if(wasUpdatedByAnotherUser) {
                            $0.italic(true).bold(true)
                        }
                    
                } else if phoneLineItemDisplayItem == .category {
                    Capsule()
                        .fill(
                            calModel.isUnifiedPayMethod && lineItemIndicator == .paymentMethod
                            ? (trans.payMethod?.color ?? .gray)
                            : (trans.category?.color ?? .gray)
                        )
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 1)
                        .overlay { ExcludeFromTotalsLine(trans: trans) }
                                    
                } else {
                    if putBackToBottomPanelViewOnRotate {
                        inlineTitleAndTotal
                            .overlay { ExcludeFromTotalsLine(trans: trans) }
                        
                    } else {
                        if AppState.shared.isLandscape {
                            inlineTitleAndTotal
                                .overlay { ExcludeFromTotalsLine(trans: trans) }
                            
                        } else if phoneLineItemTotalPosition == .below {
                            stackedTitleAndTotal
                            
                        } else if phoneLineItemTotalPosition == .inline && [.portrait, .portraitUpsideDown, .faceUp, .faceDown].contains(AppState.shared.orientation) {
                            inlineTitleAndTotal
                                .overlay { ExcludeFromTotalsLine(trans: trans) }
                            
                        } else {
                            inlineTitleAndTotal
                                .overlay { ExcludeFromTotalsLine(trans: trans) }
                        }
                    }
                }
                
                if trans.notifyOnDueDate {
                    Image(systemName: "bell")
                        .foregroundStyle(.primary)
                        //.font(.caption2)
                        .font(.system(size: 10))
                }
            }
        }
    }
    
    
    var accessoryIndicator: some View {
        Capsule()
            .fill(
                calModel.isUnifiedPayMethod && lineItemIndicator == .paymentMethod
                ? (trans.payMethod?.color ?? .gray)
                : (trans.category?.color ?? .gray)
            )
            .frame(width: 3)
            .frame(maxHeight: .infinity)
            .padding(.vertical, 2)
    }
    
    
    var stackedTitleAndTotal: some View {
        Group {
            let wasUpdatedByAnotherUser = trans.updatedBy.id != AppState.shared.user?.id
            VStack(alignment: .leading, spacing: 0) {
                Text(trans.title)
                    .font(.caption2)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    .foregroundStyle(titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
                
                totalText
                    .font(.system(size: 10))
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
            }
            .if(wasUpdatedByAnotherUser) {
                $0.italic(true).bold(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    var inlineTitleAndTotal: some View {
        Group {
            let wasUpdatedByAnotherUser = trans.updatedBy.id != AppState.shared.user?.id
            HStack(spacing: 0) {
                Text(trans.title)
                    .font(.caption2)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    .foregroundStyle(titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                totalText
                    .font(.system(size: 10))
            }
            .if(wasUpdatedByAnotherUser) {
                $0.italic(true).bold(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    var totalText: some View {
        Group {
            if useWholeNumbers && tightenUpEodTotals {
                Text("\(String(format: "%.00f", trans.amount).replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))")
                
            } else if useWholeNumbers {
                Text(trans.amount.currencyWithDecimals(0))
                
            } else if !useWholeNumbers && tightenUpEodTotals {
                Text(trans.amount.currencyWithDecimals(2).replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
                
            } else {
                Text(trans.amount.currencyWithDecimals(2))
            }
        }
        .minimumScaleFactor(0.8)
        .foregroundStyle(amountColor)
        .lineLimit(1)
    }
            
    var dragPreview: some View {
        Text(trans.title)
            .padding(6)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(trans.category?.color ?? .gray)
            }
    }
}
#endif
