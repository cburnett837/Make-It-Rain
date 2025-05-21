//
//  SmartTransactionsWithIssuesOverlay.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/24/25.
//

import SwiftUI

struct SmartTransactionsWithIssuesOverlay: View {
    @Local(\.colorTheme) var colorTheme
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @Binding var bottomPanelContent: BottomPanelContent?
    @Binding var transEditID: String?
    @Binding var findTransactionWhere: WhereToLookForTransaction
    @Binding var bottomPanelHeight: CGFloat
    @Binding var scrollContentMargins: CGFloat
    
    var body: some View {
        let _ = Self._printChanges()
        
        StandardContainer(AppState.shared.isIpad ? .sidebarScrolling : .bottomPanel) {
            content
        } header: {
            if AppState.shared.isIpad {
                sidebarHeader
            } else {
                sheetHeader
            }
        }
    }
    
    
    var content: some View {
        Group {
            if calModel.tempTransactions.filter({ $0.isSmartTransaction ?? false }).isEmpty {
                ContentUnavailableView("No Smart Transactions With Issues", systemImage: "bag.fill.badge.questionmark")
            } else {
                VStack(spacing: 0) {
                    ForEach(calModel.tempTransactions.filter {$0.isSmartTransaction ?? false}) { trans in
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 0) {
                                    
                                    Text(trans.title)
                                    
                                    Group {
                                        if trans.smartTransactionIssue?.enumID == .missingPaymentMethod {
                                            Text("Missing Payment Method")
                                                .foregroundStyle(.red)
                                            
                                        } else if trans.smartTransactionIssue?.enumID == .missingDate {
                                            Text("Missing Date")
                                                .foregroundStyle(.red)
                                            
                                        } else if trans.smartTransactionIssue?.enumID == .missingPaymentMethodAndDate {
                                            Text("Missing Payment Method and Date")
                                                .foregroundStyle(.red)
                                            
                                        } else if trans.smartTransactionIssue?.enumID == .funkyDate {
                                            Text("Date Seems Weird")
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                    .font(.footnote)
                                    
                                    
                                    HStack(spacing: 0) {
                                        CircleDot(color: trans.payMethod?.color, width: 10)
                                        Text(trans.amountString)
                                            .foregroundStyle(.gray)
                                            .font(.footnote)
                                    }
                                                                                
                                    Text(trans.date?.string(to: .monthDayShortYear) ?? "N/A")
                                        .foregroundStyle(.gray)
                                        .font(.caption2)
                                }
                                
                                Spacer()
                                Button("Fix") {
                                    trans.smartTransactionIsAcknowledged = true
                                    findTransactionWhere = .smartList
                                    transEditID = trans.id
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.fromName(colorTheme))
                                
                                Button("Ignore") {
                                    Task {
                                        await calModel.denySmartTransaction(trans)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.gray)
                            }
                            
                            Divider()
                                .padding(.vertical, 2)
                        }
                        .listRowInsets(EdgeInsets())
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
    }
    
    
    var sheetHeader: some View {
        SheetHeader(
            title: "Pending Smart Transactions",
            close: {
                #if os(iOS)
                withAnimation {
                    bottomPanelContent = nil
                }
                #else
                dismiss()
                #endif
            }
        )
        #if os(iOS)
        .bottomPanelAndScrollViewHeightAdjuster(bottomPanelHeight: $bottomPanelHeight, scrollContentMargins: $scrollContentMargins)
        #endif
    }
    
    
    var sidebarHeader: some View {
        SidebarHeader(
            title: "Pending Smart Transactions",
            close: {
                #if os(iOS)
                withAnimation {
                    bottomPanelContent = nil
                }
                #else
                dismiss()
                #endif
            }
        )
    }
}



