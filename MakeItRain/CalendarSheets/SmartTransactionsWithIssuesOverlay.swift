//
//  SmartTransactionsWithIssuesOverlay.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/24/25.
//

import SwiftUI

struct SmartTransactionsWithIssuesOverlay: View {
    //@Local(\.colorTheme) var colorTheme
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
        #if os(iOS)
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
                .navigationTitle("Pending Receipts")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { closeButton }
                }
                #endif
            }
        }
        #else
        sheetHeader
        #endif
    }
    
    
    var content: some View {
        Group {
            if calModel.tempTransactions.filter({ $0.isSmartTransaction ?? false }).isEmpty {
                ContentUnavailableView("No Receipts With Issues", systemImage: "bag.fill.badge.questionmark")
            } else {
                VStack(spacing: 0) {
                    ForEach(calModel.tempTransactions.filter {$0.isSmartTransaction ?? false}) { trans in
                        lineItem(trans)                        
                    }
                }
            }
        }
    }
    
    @ViewBuilder func lineItem(_ trans: CBTransaction) -> some View {
        VStack(spacing: 0) {
            HStack {
                BusinessLogo(config: .init(parent: trans.payMethod, fallBackType: .color))
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(trans.title)
                    
                    Text(trans.amountString)
                        .foregroundStyle(.gray)
                        .font(.footnote)
                                                                
                    Text(trans.prettyDate ?? "N/A")
                        .foregroundStyle(.gray)
                        .font(.footnote)
                    
                    issueText(for: trans)
                }
                
                Spacer()
                
                fixButton(for: trans)
                discardButton(for: trans)
            }
            .padding(.horizontal, 8)
            
            #if os(iOS)
            if AppState.shared.isIphone {
                Divider()
                    .padding(.vertical, 2)
            }
            #endif
        }
        .listRowInsets(EdgeInsets())
    }
    
    
    @ViewBuilder func fixButton(for trans: CBTransaction) -> some View {
        Button("Fix") {
            //trans.smartTransactionIsAcknowledged = true
            calProps.findTransactionWhere = .smartList
            calProps.transEditID = trans.id
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.theme)
    }
    
    
    @ViewBuilder func discardButton(for trans: CBTransaction) -> some View {
        Button("Discard") {
            Task {
                await calModel.denySmartTransaction(trans)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.gray)
    }
    
    
    @ViewBuilder func issueText(for trans: CBTransaction) -> some View {
        Group {
            if trans.smartTransactionIssue?.enumID == .missingPaymentMethod {
                Text("Missing account…")
                    .foregroundStyle(.red)
                
            } else if trans.smartTransactionIssue?.enumID == .missingDate {
                Text("Missing date…")
                    .foregroundStyle(.red)
                
            } else if trans.smartTransactionIssue?.enumID == .missingPaymentMethodAndDate {
                Text("Missing account & date…")
                    .foregroundStyle(.red)
                
            } else if trans.smartTransactionIssue?.enumID == .funkyDate {
                Text("Date seems strange…")
                    .foregroundStyle(.orange)
            }
        }
        .font(.footnote)
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
                .schemeBasedForegroundStyle()
        }
    }
    
    
    @ViewBuilder
    var sheetHeader: some View {
        @Bindable var calProps = calProps
        SheetHeader(
            title: "Pending Receipts",
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



