//
//  SmartTransactionsWithIssuesOverlay.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/24/25.
//

import SwiftUI

struct SmartTransactionsWithIssuesOverlay: View {
    @Local(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) private var colorScheme
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
//    @Binding var bottomPanelContent: BottomPanelContent?
//    @Binding var transEditID: String?
//    @Binding var findTransactionWhere: WhereToLookForTransaction
//    @Binding var bottomPanelHeight: CGFloat
//    @Binding var scrollContentMargins: CGFloat
    
    @Binding var showInspector: Bool
    
    var body: some View {
        //let _ = Self._printChanges()
                
        if AppState.shared.isIphone {
            StandardContainer(.bottomPanel) {
                content
            } header: {
                sheetHeader
            }
        } else {
            NavigationStack {
                StandardContainerWithToolbar(.list) {
                    content
                }
                .navigationTitle("Pending Smart Transactions")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { closeButton }
                }
                #endif
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
                                Button("Fix & Save") {
                                    trans.smartTransactionIsAcknowledged = true
                                    calProps.findTransactionWhere = .smartList
                                    calProps.transEditID = trans.id
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.fromName(colorTheme))
                                
                                Button("Discard") {
                                    Task {
                                        await calModel.denySmartTransaction(trans)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.gray)
                            }
                            
                            if AppState.shared.isIphone {
                                Divider()
                                    .padding(.vertical, 2)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
    }
    
    var closeButton: some View {
        Button {
            #if os(iOS)
                if AppState.shared.isIphone {
                    withAnimation { calProps.bottomPanelContent = nil }
                } else {
                    showInspector = false
                }
            #else
                dismiss()
            #endif
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    @ViewBuilder
    var sheetHeader: some View {
        @Bindable var calProps = calProps
        SheetHeader(
            title: "Pending Smart Transactions",
            close: {
                #if os(iOS)
                withAnimation {
                    calProps.bottomPanelContent = nil
                }
                #else
                dismiss()
                #endif
            }
        )
//        #if os(iOS)
//        .bottomPanelAndScrollViewHeightAdjuster(bottomPanelHeight: $calProps.bottomPanelHeight, scrollContentMargins: $calProps.scrollContentMargins)
//        #endif
    }
}



