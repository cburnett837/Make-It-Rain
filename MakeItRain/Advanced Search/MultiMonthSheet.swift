//
//  MultiMonthSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/7/25.
//

import SwiftUI

struct MultiMonthSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @Binding var months: Array<CBMonth>
    
    var monthOptions: [CBMonth] = [
        CBMonth(num: 1),
        CBMonth(num: 2),
        CBMonth(num: 3),
        CBMonth(num: 4),
        CBMonth(num: 5),
        CBMonth(num: 6),
        CBMonth(num: 7),
        CBMonth(num: 8),
        CBMonth(num: 9),
        CBMonth(num: 10),
        CBMonth(num: 11),
        CBMonth(num: 12)
    ]
    
    var body: some View {
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
    }
    
    
    var content: some View {
        ForEach(monthOptions) { month in
            HStack {
                Text(month.name)
                Spacer()
                Image(systemName: "checkmark")
                    .opacity(months.contains(month) ? 1 : 0)
            }
            .contentShape(Rectangle())
            .onTapGesture { doIt(month) }
        }
    }
    
    
    var selectButton: some View {
        Button {
            months = months.isEmpty ? monthOptions : []                        
        } label: {
            Text(months.isEmpty  ? "Select All" : "Deselect All")
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
        if months.contains(month) {
            months.removeAll(where: { $0.num == month.num })
        } else {
            months.append(month)
        }
    }
}
