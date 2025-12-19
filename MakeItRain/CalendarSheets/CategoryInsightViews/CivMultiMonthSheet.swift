//
//  MultiMonthSheetForCategoryInsights.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/19/25.
//


import SwiftUI
import Charts

struct CivMultiMonthSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: CivViewModel
    @Binding var recalc: Bool
    
    var body: some View {
        @Bindable var calModel = calModel
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                content
            }
            #if os(iOS)
            .navigationTitle("Months")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { selectButton }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        .onChange(of: model.monthsForAnalysis) {
            print("should recalc")
            recalc = true
        }
    }
    
    @ViewBuilder
    var content: some View {
        let lastDecember = calModel.months.filter {$0.enumID == .lastDecember}.first!
        Section(String(lastDecember.year)) {
            label(month: lastDecember)
        }
        
        Section(String(calModel.sYear)) {
            ForEach(calModel.months.filter { ![.lastDecember, .nextJanuary].contains($0.enumID) }, id: \.self) { month in
                label(month: month)
            }
        }
        
        let nextJanuary = calModel.months.filter {$0.enumID == .nextJanuary}.first!
        Section(String(nextJanuary.year)) {
            label(month: nextJanuary)
        }
    }
    
    @ViewBuilder func label(month: CBMonth) -> some View {
        HStack {
            Text(month.name)
                .schemeBasedForegroundStyle(isDisabled: month.showSecondaryLoadingSpinner)
            Spacer()
            if month.showSecondaryLoadingSpinner {
                ProgressView()
                    .tint(.none)
            } else {
                Image(systemName: "checkmark")
                    .opacity(model.monthsForAnalysis.contains(month) ? 1 : 0)
            }
            
        }
        .disabled(month.showSecondaryLoadingSpinner)
        .contentShape(Rectangle())
        .onTapGesture { doIt(month) }
    }
    
    
    var selectButton: some View {
        Button {
            model.monthsForAnalysis = model.monthsForAnalysis.isEmpty ? calModel.months : []
        } label: {
            Text(model.monthsForAnalysis.isEmpty  ? "Select All" : "Deselect All")
            //Image(systemName: months.isEmpty ? "checklist.checked" : "checklist.unchecked")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    func doIt(_ month: CBMonth) {
        if model.monthsForAnalysis.contains(month) {
            model.monthsForAnalysis.removeAll(where: { $0.num == month.num })
        } else {
            model.monthsForAnalysis.append(month)
        }
    }
}
