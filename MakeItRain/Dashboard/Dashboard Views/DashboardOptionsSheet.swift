//
//  DashboardOptionsSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardOptionsSheet: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    var isForSelectedMonth: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Spending Display Type", selection: $model.shouldUseTotalSpending.animation()) {
                        Text("Actual").tag(false)
                        Text("Total").tag(true)
                    }
                } footer: {
                    Text("Choose whether to show the actual spending or the total spending. Actual Spending is your spending, offset by any money that came in.")
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
                
                
            }
            //.listStyle(.)
            //.padding()
            .navigationTitle("Dashboard Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        #if os(iOS)
                        withAnimation {
                            model.showOptionsSheet = false
                        }
                        #else
                        dismiss()
                        #endif
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.none)
                    #if os(macOS)
                    .buttonStyle(.roundMacButton)
                    #endif
                }
            }
        }
    }
}
