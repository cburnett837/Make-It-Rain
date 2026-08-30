//
//  CalendarMoreMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/3/25.
//

import SwiftUI
#if os(iOS)
struct CalendarMoreMenu: View {
    @Local(\.phoneLineItemDisplayItem) var phoneLineItemDisplayItem
    @Environment(\.colorScheme) var colorScheme
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    
    var body: some View {
        @Bindable var calProps = calProps
        Menu {
            Section("Analytics") {
                ControlGroup {
                    //dashboardSheetButton
                    //analysisSheetButton
                    budgetSheetButton
                    transactionListSheetButton
                }
                //transactionListSheetButton
            }
            
            Section("Transaction Filter") {
                Button {
                    calProps.showCategorySheet = true
                    //TouchAndHoldMonthToFilterCategoriesTip.didSelectCategoryFilter = true
                    //touchAndHoldMonthToFilterCategoriesTip.invalidate(reason: .actionPerformed)
                } label: {
                    Label("Categories", systemImage: "books.vertical")
                }
                
//                Button(calModel.sCategory?.title ?? "Categories") {
//                    
//                }
                
                if !calModel.sCategories.isEmpty || !calModel.sCategoryGroups.isEmpty {
                    Button("Clear Filter", systemImage: "xmark.circle", role: .destructive) {
                        withAnimation {
                            calModel.sCategories.removeAll()
                            calModel.sCategoryGroups.removeAll()
                        }
                    }
                }
            }
            
            
            Section("Tools") {
                multiSelectButton
                exportCsvButton
            }
            
            Section("More") {
                refreshButton
                settingsSheetButton
            }
        } label: {
            Label("More", systemImage: "ellipsis")
            //.schemeBasedTint()
            //.schemeBasedForegroundStyle()

//            Label("More", systemImage: "ellipsis")
//                .schemeBasedTint()
            //Image(systemName: "ellipsis")
                //.schemeBasedForegroundStyle()
                //.symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: funcModel.isLoading)
                //.tint(.none)
        }
        .schemeBasedTint()
//        .sheet(isPresented: $calProps.showDashboardSheet) {
//            CalendarDashboard()
//        }
//        .sheet(isPresented: $calProps.showAnalysisSheet) {
//            CategoryInsightsSheet(showAnalysisSheet: $calProps.showAnalysisSheet, model: categoryAnalysisModel)
//        }
        .sheet(isPresented: $calProps.showTransactionListSheet) {
            TransactionListView(showTransactionListSheet: $calProps.showTransactionListSheet)
        }
        .sheet(isPresented: $calProps.showCalendarOptionsSheet) {
            CalendarOptionsSheet(selectedDay: $calProps.selectedDay)
        }
//        .sheet(isPresented: $calProps.showBudgetSheet) {
//            BudgetTable()
//        }
    }
    
    
    var dashboardSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                /// Sheet is in ``CalendarMoreMenu``.
                //calProps.showDashboardSheet = true
                calProps.navPath.append(NavDest.dashboard)
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .dashboard
                calProps.showInspector = true
            }
        } label: {
            Label("Dashboard", systemImage: "list.bullet.below.rectangle")
        }
    }
    
    
    var budgetSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                /// Sheet is in ``CalendarMoreMenu``.
                //calProps.showBudgetSheet = true
                calProps.navPath.append(NavDest.budgets)
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .budgets
                calProps.showInspector = true
            }
        } label: {
            Label("Budgets", systemImage: "chart.bar")
        }
    }
    
    
//    var analysisSheetButton: some View {
//        Button {
//            if AppState.shared.isIphone {
//                /// Sheet is in ``CalendarMoreMenu``.
//                calProps.showAnalysisSheet = true
//            } else {
//                /// Inspector is in ``RootViewPad``.
//                calProps.inspectorContent = .analysisSheet
//                calProps.showInspector = true
//            }
//        } label: {
//            Label("Insights", systemImage: "chart.bar.doc.horizontal")
//        }
//    }
    
    
    var transactionListSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                /// Sheet is in ``CalendarMoreMenu``.
                //calProps.showTransactionListSheet = true
                calProps.navPath.append(NavDest.transactionList)
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .transactionList
                calProps.showInspector = true
            }
        } label: {
            Label("Trans List", systemImage: "list.bullet")
        }
    }
                

    var multiSelectButton: some View {
        Button {
            if phoneLineItemDisplayItem != .both {
                calProps.phoneLineItemDisplayItemWhenMultiSelectWasOpened = phoneLineItemDisplayItem
                withAnimation {
                    phoneLineItemDisplayItem = .both
                }
            }
            
            calModel.sCategoriesForAnalysis.removeAll()
            calModel.multiSelectTransactions.removeAll()
            
             //#error("This causes many bugs with animation and sheet dismissal.")
            calModel.isInMultiSelectMode = true
            
            if AppState.shared.isIphone {
                /// Bottom panel is in ``CalendarViewPhone``.
                withAnimation {
                    calProps.bottomPanelContent = .multiSelectOptions
                }
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .multiSelectOptions
                calProps.showInspector = true
            }
        } label: {
            Label("Multi-Select", systemImage: "rectangle.and.hand.point.up.left.filled")
        }
    }
    
    
    var refreshButton: some View {
        Button {
            funcModel.isLoading = true
            funcModel.refreshTask?.cancel()
            funcModel.refreshTask = Task {
                calModel.prepareForRefresh()
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == AppState.shared.todayDay }.first
                calProps.selectedDay = targetDay
                                
                await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: true, refreshTechnique: .viaButton)
            }
        } label: {
            Label {
                Text(funcModel.isLoading ? "Refreshing…" : "Refresh")
            } icon: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: funcModel.isLoading)
            }
        }
        .disabled(funcModel.isLoading)
    }
    
    @State private var csvURL: URL?
    
    @ViewBuilder
    var exportCsvButton: some View {
        Group {
            if let csvURL = csvURL {
                ShareLink(item: csvURL) {
                    Label("Export CSV", systemImage: "tablecells")
                }
            } else {
                Button {
                    Task { csvURL = await generateCsv() }
                } label: {
                    Label("Generate CSV", systemImage: "tablecells")
                }
            }
        }
        //.buttonStyle(.borderedProminent)
        //.font(.subheadline)
        .task {
            csvURL = await generateCsv()
        }
    }
    
    func generateCsv() async -> URL {
        return await Task.detached {
            let rows = await calModel.sMonth
                .justTransactions
                .filter { $0.active && $0.isPermitted }
                .map { $0.convertToCsvRecord() }
            
            let fileName = "Transactions-\(await calModel.sMonth.name)-\(await calModel.sYear).csv"
            let headers = CBTransaction.getCsvHeaders()
            
            return Helpers.generateCsv(
                fileName: fileName,
                headers: headers,
                rows: rows
            )
        }.value
    }
//    
//    @State private var csvURL: URL?
//    @State private var showCsvShareSheet = false
//    var exportCsvButton: some View {
//        Button {
//            csvURL = generateCsv()
//            showCsvShareSheet = true
//        } label: {
//            Label("Export CSV", systemImage: "tablecells")
//        }
//        .buttonStyle(.borderedProminent)
//        .font(.subheadline)
//        .sheet(isPresented: $showCsvShareSheet) {
//            if let csvURL {
//                ActivityView(items: [csvURL])
//            }
//        }
//    }
//    
    
    var settingsSheetButton: some View {
        Button {
            /// Sheet is in ``CalendarMoreMenu``.
            calProps.showCalendarOptionsSheet = true
        } label: {
            Label("Settings", systemImage: "gear")
        }
    }
}
#endif
//
//#if os(iOS)
//struct ActivityView: UIViewControllerRepresentable {
//    let items: [Any]
//
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        UIActivityViewController(activityItems: items, applicationActivities: nil)
//    }
//
//    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
//}
//#endif
