//
//  SmartTransactionsWithIssuesOverlay.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/24/25.
//

import SwiftUI

struct SmartTransactionsWithIssuesOverlay: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @Binding var bottomPanelContent: BottomPanelContent?
    @Binding var transEditID: String?
    @Binding var findTransactionWhere: WhereToLookForTransaction
    @Binding var sheetHeight: CGFloat
    
    var body: some View {
        let _ = Self._printChanges()
        VStack {
            #if os(iOS)
            if AppState.shared.isIpad || AppState.shared.isIphoneInPortrait { header }
            #else
            header
            #endif
            ScrollView {
                VStack(spacing: 0) {
                    #if os(iOS)
                    if AppState.shared.isIphoneInLandscape { header }
                    #endif
                    Divider()
                    
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
                                        .tint(Color.fromName(appColorTheme))
                                        
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
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    var header: some View {
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
        .padding()
        .sheetHeightAdjuster(height: $sheetHeight)
    }
}



