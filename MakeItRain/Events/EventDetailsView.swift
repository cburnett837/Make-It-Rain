//
//  EventDetailsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/27/25.
//

import SwiftUI

struct EventDetailsView: View {
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
       
    @Environment(\.dismiss) var dismiss
    @Environment(EventModel.self) private var eventModel
        
    @Bindable var event: CBEvent
    
    @FocusState private var focusedField: Int?
    
    var body: some View {
        StandardContainer(.list) {
            titleTextField
            budgetTextField
            startDatePicker
            endDatePicker
        } header: {
            SheetHeader(title: "Edit Details", close: { dismiss() })
        }
        .task {
            focusedField = 0
        }
    }
    
    
    
    
    
    // MARK: - Subviews
    var titleTextField: some View {
        HStack {
            Text("Title")
            Spacer()
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Event Title", text: $event.title, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(0)
            .uiTextAlignment(.right)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            #else
            TextField("Event Title", text: $event.title)
                .multilineTextAlignment(.trailing)
            #endif
        }
        .focused($focusedField, equals: 0)
    }
    
    
    var budgetTextField: some View {
        HStack {
            Text("Budget")
            Spacer()
            
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Event Budget", text: $event.amountString ?? "", toolbar: {
                KeyboardToolbarView(
                    focusedField: $focusedField,
                    accessoryImage3: "plus.forwardslash.minus",
                    accessoryFunc3: {
                        Helpers.plusMinus($event.amountString ?? "")
                    })
            })
            .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
            .uiTag(1)
            .uiTextAlignment(.right)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            #else
            TextField("Budget", text: $event.amountString ?? "")
                .multilineTextAlignment(.trailing)
            #endif
            
        }
        .focused($focusedField, equals: 1)
    }

    
    var startDatePicker: some View {
        HStack {
            Text("Starts")
                .frame(maxWidth: .infinity, alignment: .leading)
                        
            #if os(iOS)
            UIKitDatePicker(date: $event.startDate, alignment: .trailing) // Have to use because of reformatting issue
            #else
            DatePicker("", selection: $event.startDate ?? Date(), displayedComponents: [.date])
                .labelsHidden()
            #endif
        
        }
    }
    
    
    var endDatePicker: some View {
        HStack {
            Text("Ends")
                .frame(maxWidth: .infinity, alignment: .leading)
        
            #if os(iOS)
            UIKitDatePicker(date: $event.endDate, alignment: .trailing) // Have to use because of reformatting issue
            #else
            DatePicker("", selection: $event.endDate ?? Date(), displayedComponents: [.date])
                .labelsHidden()
            #endif
        }
    }
}
