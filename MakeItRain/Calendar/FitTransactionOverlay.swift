//
//  FitTransactionSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/21/25.
//

import Foundation
import SwiftUI

struct FitTransactionOverlay: View {
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif
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
                    
                    if calModel.fitTrans.filter({ !$0.isAcknowledged }).isEmpty {
                        ContentUnavailableView("No Fit Transactions", systemImage: "bag.fill.badge.questionmark")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(calModel.fitTrans.filter { !$0.isAcknowledged }) { trans in
                                VStack(spacing: 0) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 0) {
                                            
                                            HStack(spacing: 0) {
                                                CircleDot(color: trans.category?.color, width: 10)
                                                Text(trans.title)
                                            }
                                            
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
                                        .tint(.gray
                                        )
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
                #if os(iOS)
                withAnimation {
                    showFitTransactions = false
                }
                #else
                dismiss()
                #endif
            },
            view1: {
                Button {
                    Task { await calModel.fetchFitTransactionsFromServer() }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }

            }
        )
        .padding()
    }
}
