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
    
    @State private var showLoadingSpinner = false
    
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
            List(eventModel.invitations) { part in
                VStack(alignment: .leading) {
                    Text("\(part.eventID)")
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
                                dismiss()
                                await eventModel.fetchEvents()
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
                                
                                dismiss()
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
                            Text("Thinking…")
                            Spacer()
                        }
                        .opacity(showLoadingSpinner ? 1 : 0)
                        .tint(.none)
                    }
                    
                    
                }
            }
        }
    }
}

#Preview {
    EventPendingInviteView()
}
