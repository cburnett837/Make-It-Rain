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
    @State private var showAlert = false
    @State private var inviteEmail = ""
    
    @FocusState private var focusedField: Int?
    
    var header: some View {
        Group {
            SheetHeader(
                title: "Invite User",
                close: { dismiss() }
            )
            .padding()
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            List {
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
        }
        .task {
            focusedField = 0
        }
        .alert(alertText, isPresented: $showAlert) {
            Button("OK") {}
        }
    }
    
    
    func checkEmail() {
        if inviteEmail.isEmpty {
            showAlert("Email cannot be blank")
            return
        }
        
        Task {
            let dummyParticipantObject = CBEventParticipant(user: AppState.shared.user!, eventID: event.id, email: inviteEmail)
            dummyParticipantObject.status = XrefModel.getItem(from: .eventInviteStatus, byEnumID: .pending)
                                    
            if event.participants
                .filter ({ $0.active && $0.status?.enumID == .accepted })
                .map ({ $0.user })
                .map ({ $0.email.lowercased() })
                .contains(inviteEmail.lowercased()) {
                showAlert("That user is already part of the event")
                return
            }
            
            showLoadingSpinner = true
            let result = await eventModel.verifyInviteEmailExists(dummyParticipantObject)
            showLoadingSpinner = false
            
            if let result {
                switch result.verificationResult {
                case .found:
                    print(result.user!.email)
                    dummyParticipantObject.user = result.user!
                    dummyParticipantObject.inviteTo = result.user!
                    event.participants.append(dummyParticipantObject)
                    dismiss()
                    
                case .notFound:
                    showAlert("That email is not available to invite")
                    
                case .alreadyInvited:
                    showAlert("That person has already been invited")
                }
            }
            
            
        }
    }
    
    func showAlert(_ text: String) {
        alertText = text
        showAlert = true
    }
}
