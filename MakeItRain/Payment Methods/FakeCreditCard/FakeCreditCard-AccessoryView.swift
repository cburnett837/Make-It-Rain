//
//  CardAccessoryView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//


import SwiftUI
import LocalAuthentication

struct FakeCreditCardAccessoryView: View {
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Bindable var meth: CBPaymentMethod
    @Bindable var model: PayMethodsTable.ViewModel
    @Binding var blur: CGFloat
    @Binding var scale: CGFloat
    @Binding var navPath: NavigationPath
    
    @State private var transactions: [CBTransaction] = []
    
    var filteredTransactions: [CBTransaction] {
        transactions.filter {
            model.transSearchText.isEmpty ? true : String($0.title).localizedStandardContains(model.transSearchText)
        }
        .sorted(by: { $0.date ?? Date() > $1.date ?? Date() })
    }
    
    var month: CBMonth? {
        calModel.months.filter({ $0.actualNum == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }).first
    }
        
    var noTransReasonText: String {
        calModel.sYear == AppState.shared.todayYear ? "No Transactions" : "Transactions will only show here for \(AppState.shared.todayYear)"
    }

    var body: some View {
        VStack {
            List {
//                NavigationLink(value: "chart-page") {
//                    Label("Insights", systemImage: "chart.xyaxis.line")
//                        .schemeBasedForegroundStyle()
//                }
                
                if let month = month, !transactions.isEmpty {
                    Section("Recent Transactions") {
                        ForEach(filteredTransactions) { trans in
                            TransactionListLine(trans: trans, withDate: true, withTags: true, withPhotos: true) {
                                let day = month.days.filter { $0.id == trans.dateComponents?.day }.first
                                model.transDay = day
                                model.transEditID = trans.id
                            }
                            .id(trans.id)
                        }
                    }
                } else {
                    Section {
                        ContentUnavailableView(noTransReasonText, systemImage: "square.slash.fill")
                    }
                }
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.y + $0.contentInsets.top
        } action: { _, newOffset in
            guard model.isCardSelected else { return }

            let collapseDistance: CGFloat = 200
            let raw = 1 - (newOffset / collapseDistance)

            blur = min(newOffset / 16, 8)
            scale = max(min(raw, 1), 0)
        }
        
        .navigationDestination(for: String.self) { _ in chartPage }
        //.scrollPosition(id: $scrollID)
        .scrollContentBackground(.hidden)
        .frame(height: model.info.containerSize.height + model.info.safeArea.bottom)
        .contentMargins(.top, CARD_HEIGHT + 10, for: .scrollContent)
        .contentMargins(.bottom, model.info.safeArea.bottom, for: .scrollContent)
        .task {
            //await prepareView()
            
            guard let month = month, let meth = model.selectedPaymentMethod else { return }
            self.transactions = calModel
                .getTransactions(months: [month], meth: meth)
                .filter { $0.dateComponents?.day ?? 0 <= AppState.shared.todayDay }
                .filter { model.transSearchText.isEmpty ? true : String($0.title).localizedStandardContains(model.transSearchText) }
        }
        /// Make sure this stays under the other modifiers otherwise the frame will get appplied and cause weird scroll offset.
        .transactionEditSheetAndLogic(transEditID: $model.transEditID, selectedDay: $model.transDay, extraDismissLogic: { didSave in
//            if didSave {
//                Task { await prepareView() }
//            }
        })
    }
    
    @ViewBuilder
    var chartPage: some View {
        if meth.action == .add {
            ContentUnavailableView("Insights are not available when adding a new account", systemImage: "square.stack.3d.up.slash.fill")
        }
//        else {
//            PayMethodDashboard(payMethod: meth, navPath: $navPath)
//        }
    }
    
    
//    func prepareView() async {
//        if meth.action == .add {
//            //payModel.upsert(payMethod)
//            model.paymentMethodEditID = meth.id
//            viewModel.isLoadingHistory = false
//        } else {
//            
//            viewModel.fetchHistory(for: meth, payModel: payModel, setChartAsNew: true)
//            
////            /// iPhone: only fetch the new historical if it has been wiped out (by returning to the account list), or if a transaction has been updated since the history was fetched from the server.
////            /// Due to the navigation stack, we can leave the chart open and go elsewhere in the app. Thus, no need to refresh the data unless a transaction changed in the meantime.
////            /// Likewise, when returning to the account list, the viewmodel would be destroyed, and the history would need to be refetched.
////            ///
////            /// iPad: Always fetch the data since everything is inside a sheet, which must be closed before returning to the rest of the app. Thus the viewmodel would be destroyed, and the history would need to be refetched.
////            let needsUpdates = calModel.transactionsUpdatesExistAfter(fetchHistoryTime)
////            if meth.breakdownsRegardlessOfPaymentMethod.isEmpty || needsUpdates || AppState.shared.isIpad {
////                fetchHistoryTime = Date()
////                viewModel.fetchHistory(for: meth, payModel: payModel, setChartAsNew: true)
////            }
//        }
//    }
}
