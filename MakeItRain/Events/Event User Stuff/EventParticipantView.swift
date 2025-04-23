//
//  EventParticipantCiew.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/27/25.
//

import SwiftUI

struct EventParticipantView: View {
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
   
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    @Environment(\.dismiss) var dismiss
    @Environment(EventModel.self) private var eventModel
    
    @Bindable var part: CBEventParticipant
    @Bindable var event: CBEvent
    
    /// This is only here to blank out the selection hilight on the iPhone list
    //@Binding var editID: String?
    
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    
    var title: String { part.action == .add ? "New Participant" : "Edit Participant" }
    
    @FocusState private var focusedField: Int?
                        
    var body: some View {
        StandardContainer {
            LabeledRow("Group Amount", labelWidth) {
                #if os(iOS)
                StandardUITextField("Group Amount", text: $part.groupAmountString ?? "", toolbar: {
                    KeyboardToolbarView(
                        focusedField: $focusedField,
                        accessoryImage3: "plus.forwardslash.minus",
                        accessoryFunc3: {
                            Helpers.plusMinus($part.groupAmountString ?? "")
                        })
                })
                .cbClearButtonMode(.whileEditing)
                .cbFocused(_focusedField, equals: 0)
                .cbKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                #else
                StandardTextField("Group Amount", text: $part.groupAmountString ?? "", focusedField: $focusedField, focusValue: 0)
                #endif
            }
            .focused($focusedField, equals: 0)
            
            
            LabeledRow("Personal Amount", labelWidth) {
                #if os(iOS)
                StandardUITextField("Personal Amount", text: $part.personalAmountString ?? "", toolbar: {
                    KeyboardToolbarView(
                        focusedField: $focusedField,
                        accessoryImage3: "plus.forwardslash.minus",
                        accessoryFunc3: {
                            Helpers.plusMinus($part.personalAmountString ?? "")
                        })
                })
                .cbClearButtonMode(.whileEditing)
                .cbFocused(_focusedField, equals: 1)
                .cbKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                #else
                StandardTextField("Personal Amount", text: $part.personalAmountString ?? "", focusedField: $focusedField, focusValue: 1)
                #endif
            }
            .focused($focusedField, equals: 1)
            
            
        } header: {
            SheetHeader(title: title, close: { dismiss() })
        }
        .task {
            part.deepCopy(.create)
            focusedField = 0
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .confirmationDialog("Delete \"\(part.user.name)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                dismiss()
                event.deleteParticipant(id: part.id)
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(part.user.name)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
    }
}


