//
//  DashboardOptionsSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardOptionsSheet: View {
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @Bindable var model: DashboardModel
    @Binding var showCategorySheet: Bool
    @Binding var showPayMethodSheet: Bool
    var isForSelectedMonth: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section("Filter") {
                    showPaymentMethodSheetButton
                    showCategorySheetButton
                }
                
                if !isForSelectedMonth {
                    Section("Date Range") {
                        DatePicker("Begin Date", selection: $model.beginDate, displayedComponents: [.date])
                        DatePicker("End Date", selection: $model.endDate, in: model.beginDate..., displayedComponents: [.date])
                        
                        ScrollView(.horizontal) {
                            HStack {
                                //                        Button("Selected Month") {
                                //                            model.beginDate = calModel.sMonth.days.first(where: { !$0.isPlaceholder })?.date ?? Date()
                                //                            model.endDate = calModel.sMonth.days.last?.date ?? Date()
                                //                        }
                                
                                let currentMonthName = NavDest.getMonthFromInt(AppState.shared.todayMonth)?.displayName
                                Button("\(currentMonthName ?? "N/A") \(String(AppState.shared.todayYear))") {
                                    let now = Date()
                                    model.beginDate = now.startDateOfMonth
                                    model.endDate = now.endDateOfMonth
                                }
                                
                                Button("YTD") {
                                    let now = Date()
                                    model.beginDate = now.startDateOfYear
                                    model.endDate = now
                                }
                                
                                Button("This Quarter") {
                                    let now = Date()
                                    model.beginDate = now.startDateOfQuarter
                                    model.endDate = now.endDateOfQuarter
                                }
                                
                                Button(String(AppState.shared.todayYear)) {
                                    let now = Date()
                                    model.beginDate = now.startDateOfYear
                                    model.endDate = now.endDateOfYear
                                }
                                
                                ForEach(1...4, id: \.self) { q in
                                    Button("Q\(q)") {
                                        let now = Date()
                                        let range = now.datesForQuarter(q)
                                        model.beginDate = range.start
                                        model.endDate = range.end
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .contentMargins(.bottom, -10, for: .scrollIndicators)
                    }
                }
                
                Section {
                    Picker("Spending Display Type", selection: $model.shouldUseTotalSpending.animation()) {
                        Text("Actual").tag(false)
                        Text("Total").tag(true)
                    }
                } footer: {
                    Text("Choose whether to show the actual spending or the total spending. Actual Spending is your spending, offset by any money that came in.")
                }
                
            }
            //.listStyle(.)
            //.padding()
            .navigationTitle("Dashboard Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            model.showOptionsSheet = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.none)
                }
                #else
                ToolbarItem(placement: .principal) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.none)
                    .buttonStyle(.roundMacButton)
                }
                #endif
            }
            .sheet(isPresented: $showCategorySheet, onDismiss: {
                //model.fetchIfChange(calModel: calModel)
            }) {
                MultiCategorySheet(
                    categories: $model.categories,
                    categoryGroups: $model.groups
                )
                #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                #endif
            }
            .sheet(isPresented: $showPayMethodSheet, onDismiss: {
                model.setMethodIds(payModel: payModel)
                //model.fetchIfChange(calModel: calModel)
            }) {
                PayMethodSheet(
                    payMethod: $model.payMethod,
                    whichPaymentMethods: .all,
                    showStartingAmountOption: false,
                    showNoneOption: true,
                    noneText: "Don't filter by any account and show all data."
                )
            }
        }
    }
    
    var showPaymentMethodSheetButton: some View {
        Button {
            showPayMethodSheet = true
        } label: {
            Label {
                Text(model.payMethod?.title ?? "Select Account")
            } icon: {
                PayMethodLogoMashup(meth: model.payMethod)
            }
            .schemeBasedForegroundStyle()
        }
        .tint(.none)
        .disabled(model.isLoading)
    }
    
    var showCategorySheetButton: some View {
        Button {
            showCategorySheet = true
        } label: {
            Label {
                Text("Select Categories")
            } icon: {
                Image(systemName: "books.vertical")
            }
            .schemeBasedForegroundStyle()
        }
        .if(!model.allCatsSelected) {
            $0.badge(model.categories.count + model.groups.count)
        }
        .tint(.none)
        .disabled(model.isLoading)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
}
