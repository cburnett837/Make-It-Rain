////
////  FitTransactionSheet.swift
////  MakeItRain
////
////  Created by Cody Burnett on 2/21/25.
////
//
//import Foundation
//import SwiftUI
//
//struct FitTransactionOverlay: View {
//    //@Local(\.colorTheme) var colorTheme
//    
//    #if os(macOS)
//    @Environment(\.dismiss) private var dismiss
//    #endif
//    @Environment(CalendarModel.self) private var calModel
//    
//    @Environment(PayMethodModel.self) private var payModel
//    
//    @Binding var bottomPanelContent: BottomPanelContent?
//    @Binding var bottomPanelHeight: CGFloat
//    @Binding var scrollContentMargins: CGFloat
//    
//    var body: some View {
//        StandardContainer(AppState.shared.isIpad ? .sidebarScrolling : .bottomPanel) {
//            content
//        } header: {
//            if AppState.shared.isIpad {
//                sidebarHeader
//            } else {
//                sheetHeader
//            }
//        }
//    }
//    
//    
//    var content: some View {
//        Group {
//            if calModel.fitTrans.filter({ !$0.isAcknowledged }).isEmpty {
//                ContentUnavailableView("No Fit Transactions", systemImage: "bag.fill.badge.questionmark")
//            } else {
//                VStack(spacing: 0) {
//                    ForEach(calModel.fitTrans.filter { !$0.isAcknowledged }) { trans in
//                        LineItem(trans: trans)
//                            .padding(.horizontal, 8)
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    var sheetHeader: some View {
//        SheetHeader(
//            title: "Pending Fit Transactions",
//            close: {
//                #if os(iOS)
//                withAnimation {
//                    bottomPanelContent = nil
//                }
//                #else
//                dismiss()
//                #endif
//            },
//            view1: {
//                Button {
//                    Task { await calModel.fetchFitTransactionsFromServer() }
//                } label: {
//                    Image(systemName: "arrow.triangle.2.circlepath")
//                        .contentShape(Rectangle())
//                }
//            }
//        )
//        //.background(Color.red)
//        //#if os(iOS)
//        //.bottomPanelAndScrollViewHeightAdjuster(bottomPanelHeight: $bottomPanelHeight, scrollContentMargins: $scrollContentMargins)
//        //#endif
//    }
//    
//    
//    var sidebarHeader: some View {
//        SidebarHeader(
//            title: "Pending Fit Transactions",
//            close: {
//                #if os(iOS)
//                withAnimation {
//                    bottomPanelContent = nil
//                }
//                #else
//                dismiss()
//                #endif
//            },
//            view1: {
//                Button {
//                    Task { await calModel.fetchFitTransactionsFromServer() }
//                } label: {
//                    Image(systemName: "arrow.triangle.2.circlepath")
//                        .contentShape(Rectangle())
//                }
//            }
//        )
//    }
//    
//    
//    
//    struct LineItem: View {
//        //@Local(\.colorTheme) var colorTheme
//        @Environment(CalendarModel.self) private var calModel
//        
//        var trans: CBFitTransaction
//        
//        var body: some View {
//            VStack(spacing: 0) {
//                HStack {
//                    VStack(alignment: .leading, spacing: 0) {
//                        
//                        HStack(spacing: 0) {
//                            CircleDot(color: trans.category?.color, width: 10)
//                            Text(trans.title)
//                        }
//                        
//                        HStack(spacing: 0) {
//                            CircleDot(color: trans.payMethod?.color, width: 10)
//                            Text(trans.amountString)
//                                .foregroundStyle(.gray)
//                                .font(.footnote)
//                        }
//                        
//                        
//                        Text(trans.prettyDate ?? "N/A")
//                            .foregroundStyle(.gray)
//                            .font(.caption2)
//                    }
//                    
//                    Spacer()
//                    Button("Accept") {
//                        let buttonConfig = AlertConfig.ButtonConfig(text: "Yes", role: .primary) { accept() }
//                        let config = AlertConfig(
//                            title: "Accept \(trans.title)?",
//                            subtitle: trans.prettyDate ?? "N/A",
//                            symbol: .init(name: "checkmark.circle.badge.questionmark", color: .green),
//                            primaryButton: AlertConfig.AlertButton(config: buttonConfig)
//                        )
//                        
//                        AppState.shared.showAlert(config: config)
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(Color.theme)
//                    
//                    Button("Reject") {
//                        let buttonConfig = AlertConfig.ButtonConfig(text: "Yes", role: .destructive) { reject() }
//                        let config = AlertConfig(
//                            title: "Reject \(trans.title)?",
//                            subtitle: trans.prettyDate ?? "N/A",
//                            symbol: .init(name: "checkmark.circle.badge.questionmark", color: .orange),
//                            primaryButton: AlertConfig.AlertButton(config: buttonConfig)
//                        )
//                        
//                        AppState.shared.showAlert(config: config)
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(.gray)
//                }
//                
//                Divider()
//                    .padding(.vertical, 2)
//            }
//            .listRowInsets(EdgeInsets())
//        }
//        
//        
//        func accept() {
//            trans.isAcknowledged = true
//            
//            if trans.payMethod?.id == "10" {
//                if trans.amountString.contains("-") {
//                    trans.amountString = trans.amountString.replacingOccurrences(of: "-", with: "")
//                } else {
//                    trans.amountString = "-\(trans.amountString)"
//                }
//            }
//            
//            let realTrans = CBTransaction(fitTrans: trans)
//            if let targetDay = calModel
//                .sMonth
//                .days
//                .filter({
//                    $0.dateComponents?.month == realTrans.date?.month
//                    && $0.dateComponents?.day == realTrans.date?.day
//                    && $0.dateComponents?.year == realTrans.date?.year
//                }).first {
//                targetDay.upsert(realTrans)
//            }
//            
//            calModel.tempTransactions.append(realTrans)
//            calModel.saveTransaction(id: realTrans.id, location: .tempList)
//        }
//        
//        
//        func reject() {
//            trans.isAcknowledged = true
//            Task {
//                await calModel.denyFitTransaction(trans)
//            }
//        }
//    }
//}
