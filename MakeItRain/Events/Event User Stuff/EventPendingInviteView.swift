//
//  EventPendingInviteView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/22/25.
//

import SwiftUI

struct EventPendingInviteView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(EventModel.self) private var eventModel
    
    var header: some View {
        Group {
            SheetHeader(
                title: "Pending Invites",
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
            List(eventModel.invitations.filter { $0.status?.enumID == .pending }) { part in
                InviteLine(part: part)
            }
        }
    }
}


struct InviteLine: View {
    @Environment(\.dismiss) var dismiss
    @Environment(EventModel.self) private var eventModel
    
    @Bindable var part: CBEventParticipant
    
    @State private var showLoadingSpinner = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(part.eventName ?? "N/A")
            Text(part.inviteFrom?.name ?? "N/A")
                .foregroundStyle(.gray)
                .font(.footnote)
            
            HStack {
                Button("Accept") {
                    showLoadingSpinner = true
                    let response =  CBEventInviteResponse(eventID: part.eventID, participantID: part.id, isAccepted: true)
                    Task {
                        if await eventModel.respondToInvitation(response) {
                            withAnimation {
                                eventModel.invitations.removeAll(where: { $0.id == part.id })
                            }
                        }
                        
                        await eventModel.fetchEvents()
                        
                        if eventModel.invitations.isEmpty {
                            dismiss()
                        }
                        showLoadingSpinner = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Spacer()
                
                Button("Decline") {
                    showLoadingSpinner = true
                    let response =  CBEventInviteResponse(eventID: part.eventID, participantID: part.id, isAccepted: false)
                    Task {
                        if await eventModel.respondToInvitation(response) {
                            withAnimation {
                                eventModel.invitations.removeAll(where: { $0.id == part.id })
                            }
                        }
                        
                        if eventModel.invitations.isEmpty {
                            dismiss()
                        }
                        showLoadingSpinner = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .disabled(showLoadingSpinner)
            .opacity(showLoadingSpinner ? 0 : 1)
            .overlay {
                HStack(spacing: 5) {
                    ProgressView()
                    Text("Sending Response…")
                    Spacer()
                }
                .opacity(showLoadingSpinner ? 1 : 0)
                .tint(.none)
            }
            
            
        }
    }
}
