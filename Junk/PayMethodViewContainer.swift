////
////  PayMethodViewContainer.swift
////  MakeItRain
////
////  Created by Cody Burnett on 5/15/25.
////
//
//import SwiftUI
//
//struct PayMethodViewContainer: View {
//    @Local(\.incomeColor) var incomeColor
//    @AppStorage("monthlyAnalyticChartVisibleYearCount") var chartVisibleYearCount: MonthlyAnalyticChartRange = .year1
//
//    @Environment(PayMethodModel.self) private var payModel
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var payMethod: CBPaymentMethod
//    
//    @State private var editPaymentMethod: CBPaymentMethod?
//    @State private var paymentMethodEditID: CBPaymentMethod.ID?
//    
//    @State private var viewModel = PayMethodViewModel()
//    
//    var freeCashFlowText: String { payMethod.isCredit ? "Available Balance": "Free Cash Flow" }
//    var incomeText: String { payMethod.isCredit ? "Income / Refunds": "Income / Refunds / Deposits" }
//    
//    var visibleYearCount: Int {
//        return chartVisibleYearCount.rawValue == 0 ? 1 : chartVisibleYearCount.rawValue
//    }
//    
//    var title: String {
//        payMethod.title
//    }
//    
//    var configType: PayMethodChartDataType {
//        switch payMethod.accountType {
//        case .checking:
//            .debitPaymentMethod
//        case .credit:
//            .creditPaymentMethod
//        case .cash:
//            .debitPaymentMethod
//        case .unifiedChecking:
//            .unifiedDebitPaymentMethod
//        case .unifiedCredit:
//            .unifiedCreditPaymentMethod
//        default:
//            .other
//        }
//    }
//    
//    var body: some View {
//        Group {
//            if payMethod.action == .add {
//                ContentUnavailableView("Insights are not available when adding a new payment method", systemImage: "square.stack.3d.up.slash.fill")
//            } else {
//                StandardContainer {
//                    let chartConfig = PayMethodChartConfig(
//                        type: configType,
//                        incomeConfig: (title: "Income", enabled: true, color: Color.fromName(incomeColor)),
//                        expensesConfig: (title: "Expenses", enabled: true, color: .red),
//                        paymentsConfig: (title: "Payments", enabled: payMethod.isCredit, color: .purple),
//                        startingAmountsConfig: (title: "Starting Balance", enabled: true, color: .orange),
//                        freeCashFlowConfig: (title: freeCashFlowText, enabled: true, color: .green),
//                        color: payMethod.color,
//                        headerLingo: "Insights"
//                    )
//                                        
//                    PayMethodChart(viewModel: viewModel, payMethod: payMethod, config: chartConfig)
//                } header: {
//                    Text(payMethod.title)
//                }
//                .listStyle(.plain)
//                #if os(iOS)
//                .listSectionSpacing(50)
//                #endif
//                .opacity(viewModel.isLoadingHistory ? 0 : 1)
//                .overlay {
//                    ProgressView("Loading Insights…")
//                        .tint(.none)
//                        .opacity(viewModel.isLoadingHistory ? 1 : 0)
//                }
//                .focusable(false)
//            }
//        }
//        .task { await prepareView() }
//        
//        .sheet(item: $editPaymentMethod, onDismiss: {
//            paymentMethodEditID = nil
//            payModel.determineIfUserIsRequiredToAddPaymentMethod()
//        }, content: { meth in
//            PayMethodView2(payMethod: meth, editID: $paymentMethodEditID)
//            #if os(iOS)
//            .presentationSizing(.page)
//            //.presentationDetents([.medium, .large])
//            #endif
//        })
//        .onChange(of: paymentMethodEditID) { oldValue, newValue in
//            if let newValue {
//                let payMethod = payModel.getPaymentMethod(by: newValue)
//                
////                if payMethod.accountType == .unifiedChecking || payMethod.accountType == .unifiedCredit {
////                    paymentMethodEditID = nil
////                    AppState.shared.showAlert("Combined payment methods cannot be edited.")
////                } else {
////                    editPaymentMethod = payMethod
////                }
//                
//                editPaymentMethod = payMethod
//                
//            } else {
//                payModel.savePaymentMethod(id: oldValue!, calModel: calModel)
//                payModel.determineIfUserIsRequiredToAddPaymentMethod()
//            }
//        }
//    }
//    
////    var header: some View {
////        Group {
////            if payMethod.accountType == .credit && payMethod.dueDate != nil {
////                SheetHeader(
////                    title: title,
////                    close: { editID = nil; dismiss() },
////                    view1: { refreshButton },
////                    view2: { notificationButton.disabled(payMethod.isUnified) },
////                    view3: { deleteButton.disabled(payMethod.isUnified) }
////                )
////            } else {
////                SheetHeader(
////                    title: title,
////                    close: { editID = nil; dismiss() },
////                    view1: { refreshButton },
////                    view3: { deleteButton.disabled(payMethod.isUnified) }
////                )
////            }
////        }
////    }
//        
//    
//    
////    var deleteButton: some View {
////        Button {
////            showDeleteAlert = true
////        } label: {
////            Image(systemName: "trash")
////        }
////        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
////    }
////    
////    var notificationButton: some View {
////        Button {
////            payMethod.notifyOnDueDate.toggle()
////        } label: {
////            Image(systemName: payMethod.notifyOnDueDate ? "bell.slash.fill" : "bell.fill")
////        }
////    }
////    
////    var refreshButton: some View {
////        Button {
////            payMethod.breakdowns.removeAll()
////            payMethod.breakdownsRegardlessOfPaymentMethod.removeAll()
////            Task {
////                viewModel.fetchYearStart = AppState.shared.todayYear - 10
////                viewModel.fetchYearEnd = AppState.shared.todayYear
////                viewModel.payMethods.removeAll()
////                viewModel.isLoadingHistory = true
////                await viewModel.fetchHistory(for: payMethod, payModel: payModel, setChartAsNew: true, visibleYearCount: chartVisibleYearCount.rawValue)
////            }
////        } label: {
////            Image(systemName: "arrow.triangle.2.circlepath")
////        }
////    }
//    
//    func prepareView() async {
//        if payMethod.action != .add {
//            await viewModel.fetchHistory(for: payMethod, payModel: payModel, setChartAsNew: true, visibleYearCount: chartVisibleYearCount.rawValue)
//        } else {
//            paymentMethodEditID = UUID().uuidString
//        }
//    }
//}
