//
//  FitTransactionSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/21/25.
//

import Foundation
import SwiftUI

struct FitTransactionOverlay: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @Binding var showFitTransactions: Bool
    
    var body: some View {
        VStack {
            #if os(iOS)
            if !AppState.shared.isLandscape { header }
            #else
            header
            #endif
            ScrollView {
                #if os(iOS)
                if AppState.shared.isLandscape { header }
                #endif
                
                VStack(spacing: 0) {
                    Divider()
                    
                    if calModel.fitTrans.isEmpty {
                        ContentUnavailableView("No Fit Transactions", systemImage: "bag.fill.badge.questionmark")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(calModel.fitTrans.filter { !$0.isAcknowledged }) { trans in
                                VStack(spacing: 0) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            
                                            HStack(spacing: 0) {
                                                CircleDot(color: trans.payMethod?.color, width: 10)
                                                Text(trans.title)
                                            }
                                            
                                            Text(trans.amountString)
                                                .foregroundStyle(.gray)
                                                .font(.caption2)
                                            Text(trans.date?.string(to: .monthDayShortYear) ?? "N/A")
                                                .foregroundStyle(.gray)
                                                .font(.caption2)
                                        }
                                        
                                        Spacer()
                                        Button("Accept") {
                                            trans.isAcknowledged = true
                                            
                                            if trans.payMethod?.id == "10" {
                                                if trans.amountString.contains("-") {
                                                    trans.amountString = trans.amountString.replacingOccurrences(of: "-", with: "")
                                                } else {
                                                    trans.amountString = "-\(trans.amountString)"
                                                }
                                            }
                                            
                                            let realTrans = CBTransaction(fitTrans: trans)
                                            if let targetDay = calModel
                                                .sMonth
                                                .days
                                                .filter({
                                                    $0.dateComponents?.month == realTrans.date?.month
                                                    && $0.dateComponents?.day == realTrans.date?.day
                                                    && $0.dateComponents?.year == realTrans.date?.year
                                                }).first {
                                                targetDay.upsert(realTrans)
                                            }
                                            
                                            calModel.tempTransactions.append(realTrans)
                                            calModel.saveTransaction(id: realTrans.id, location: .tempList)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.green)
                                        
                                        Button("Ignore") {
                                            trans.isAcknowledged = true
                                            Task {
                                                await calModel.denyFitTransaction(trans)
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.orange)
                                    }
                                    
                                    Divider()
                                }
                                .listRowInsets(EdgeInsets())
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        #if os(iOS)
        .background {
            //Color.darkGray.ignoresSafeArea(edges: .bottom)
            Color(.secondarySystemBackground).ignoresSafeArea(edges: .bottom)
        }
        #endif
        
        
        //            .confirmationDialog("Pending Fit Transactions", isPresented: $showDropActions) {
        //
        //            } message: {
        //                Text("\(calModel.transactionToCopy?.title ?? "N/A")\nDropped on \(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())")
        //            }
                
    }
    
    var header: some View {
        SheetHeader(
            title: "Pending Fit Transactions",
            close: {
                withAnimation { showFitTransactions = false }
            }
        )
        .padding()
    }
}
