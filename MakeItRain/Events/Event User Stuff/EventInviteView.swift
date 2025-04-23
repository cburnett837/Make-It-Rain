//
//  EventInviteView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/23/25.
//

import SwiftUI

struct EventInviteView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(EventModel.self) private var eventModel
    @Bindable var event: CBEvent
    
    @State private var showLoadingSpinner = false
    @State private var alertText = ""
    @State private var inviteEmail = ""
    
    @FocusState private var focusedField: Int?
    
    var body: some View {
        StandardContainer(.list) {
            emailTextField
            inviteButton
        } header: {
            SheetHeader(title: "Invite User", close: { dismiss() } )
        }
        .task {
            focusedField = 0
        }
    }
    
    
    
    // MARK: - Subviews
    var emailTextField: some View {
        Group {
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Email", text: $inviteEmail, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField, removeNavButtons: true)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            #else
            TextField("Email", text: $inviteEmail)
            #endif
        }
        .focused($focusedField, equals: 0)
    }
    
    
    var inviteButton: some View {
        Button("Invite", action: checkEmail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(showLoadingSpinner)
            .opacity(showLoadingSpinner ? 0 : 1)
            .overlay {
                HStack(spacing: 5) {
                    ProgressView()
                    Text("Verifying Email…")
                    Spacer()
                }
                .opacity(showLoadingSpinner ? 1 : 0)
                .tint(.none)
            }
    }
    
    
    // MARK: - Functions    
    func checkEmail() {
        if inviteEmail.isEmpty {
            AppState.shared.showAlert("Email cannot be blank")
            return
        }
        
        if event.participants
            .filter ({ $0.active && $0.status?.enumID == .accepted })
            .map ({ $0.user })
            .map ({ $0.email.lowercased() })
            .contains(inviteEmail.lowercased()) {
            AppState.shared.showAlert("That user is already part of the event")
            return
        }
                
        Task {
            showLoadingSpinner = true
            /// This will show validation errors from the server if applicable.
            if await eventModel.invitePersonViaEmail(event: event, email: inviteEmail) {
                dismiss()
            }
            
            showLoadingSpinner = false
        }
    }
}
