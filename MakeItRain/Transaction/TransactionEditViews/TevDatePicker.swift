//
//  TransactionEditViewDatePicker.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/2/25.
//

import SwiftUI

struct TevDatePicker: View {
    @Bindable var trans: CBTransaction
    @Bindable var day: CBDay
    var focusedField: FocusState<Int?>.Binding
    @State private var dateFixerTicker = 0

    var body: some View {
        datePickerRow
            .listRowInsets(EdgeInsets())
            .padding(.horizontal, 16)
        
        if (trans.isSmartTransaction ?? false) &&
            (trans.smartTransactionIssue?.enumID == .missingDate
             || trans.smartTransactionIssue?.enumID == .missingPaymentMethodAndDate
             || trans.smartTransactionIssue?.enumID == .funkyDate)
            && !(trans.smartTransactionIsAcknowledged ?? true) {
            
            dateFixerRow
                .listRowInsets(EdgeInsets())
                .padding(.horizontal, 16)
        }
    }
    
    
    @ViewBuilder
    var datePickerRow: some View {
        HStack {
            Label {
                Text("Date")
            } icon: {
                Image(systemName: trans.date != nil ? "calendar" : "exclamationmark.circle.fill")
                    .foregroundColor(trans.date != nil ? .gray : Color.theme == Color.red ? Color.orange : Color.red)
                    //.frame(width: symbolWidth)
            }

            Spacer()
            if trans.date == nil && (trans.isSmartTransaction ?? false) {
                Button("A Date Is Required") {
                    trans.date = day.date!
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.theme == Color.red ? Color.orange : Color.red)
                
            } else {
                #if os(iOS)
//                UIKitDatePicker(date: $trans.date, alignment: .trailing) // Have to use because of reformatting issue
//                    .frame(height: 40)
                
                DatePicker("", selection: $trans.date ?? Date(), displayedComponents: [.date])
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .labelsHidden()
                
                
                #else
                DatePicker("", selection: $trans.date ?? Date(), displayedComponents: [.date])
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .labelsHidden()
                #endif
            }
        }
        .onChange(of: trans.date) { old, new in
            if old != nil { /// Date is nil when creating a new transaction.
                focusedField.wrappedValue = nil /// Clear any focused text field when changing the date.
                UndodoManager.shared.processChange(trans: trans)
            }
        }
    }
    
    
    var dateFixerRow: some View {
        HStack {
            Label {
                Text("Fix Date")
            } icon: {
                Image(systemName: "calendar.badge.exclamationmark")
                    .foregroundColor(Color.theme == Color.red ? Color.orange : Color.red)
            }

            Spacer()
            
            
            ControlGroup {
                Button {
                    dateFixerTicker -= 1
                    trans.date = Calendar.current.date(byAdding: DateComponents(day: dateFixerTicker), to: Date())
                } label: {
                    Image(systemName: "chevron.left")
                }
                
                Button("Today") {
                    dateFixerTicker = 0
                    trans.date = Date()
                }
                
                Button {
                    dateFixerTicker += 1
                    trans.date = Calendar.current.date(byAdding: DateComponents(day: dateFixerTicker), to: Date())
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            
            
            .buttonStyle(.borderedProminent)
        }
    }
}


