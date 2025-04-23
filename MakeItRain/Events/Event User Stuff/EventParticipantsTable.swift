//
//  EventParticipantSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/25.
//

import SwiftUI

fileprivate struct StatusItem {
    var color: Color
    var icon: String
}

struct EventParticipantsTable: View {
    @Environment(\.dismiss) var dismiss
    @Environment(EventModel.self) private var eventModel
    
    //@Binding var users: Array<CBUser>
    //var availableUsers: Array<CBUser>
    //var showInviteButton: Bool
    @Bindable var event: CBEvent
                
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    @State private var labelWidth: CGFloat = 20.0
    
    @State private var showInviteSheet = false    
    
    var filteredAccountUsers: Array<CBUser> {
        if searchText.isEmpty {
            return AppState.shared.accountUsers
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        } else {
            return AppState.shared.accountUsers
                .filter { $0.name.localizedStandardContains(searchText) }
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        }
    }
    
    var filteredAcceptedUsers: Array<CBUser> {
        if searchText.isEmpty {
            return event.participants
                .filter { $0.user.accountID != AppState.shared.user!.accountID }
                .filter { $0.status?.enumID == .accepted }
                .map { $0.user }
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        } else {
            return event.participants
                .filter { $0.user.accountID != AppState.shared.user!.accountID }
                .filter { $0.status?.enumID == .accepted }
                .map { $0.user }
                .filter { $0.name.localizedStandardContains(searchText) }
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        }
    }
        
    var filteredPendingUsers: Array<CBUser> {
        if searchText.isEmpty {
            return event.participants
                .filter { $0.user.accountID != AppState.shared.user!.accountID }
                .filter { $0.status?.enumID == .pending }
                .map { $0.user }
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        } else {
            return event.participants
                .filter { $0.user.accountID != AppState.shared.user!.accountID }
                .filter { $0.status?.enumID == .pending }
                .map { $0.user }
                .filter { $0.name.localizedStandardContains(searchText) }
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        }
    }

    
    var body: some View {
        StandardContainer(.list) {
            Section("Account Users") {
                ForEach(filteredAccountUsers) { user in
                    EventParticipantSheetLineItem(user: user, event: event, labelWidth: labelWidth)
                }
            }
            
            Section("Accepted Users") {
                ForEach(filteredAcceptedUsers) { user in
                    EventParticipantSheetLineItem(user: user, event: event, labelWidth: labelWidth)
                }
            }
            
            Section("Invited Users") {
                ForEach(filteredPendingUsers) { user in
                    EventParticipantSheetLineItem(user: user, event: event, labelWidth: labelWidth)
                }
                
                Button("Create Invite") {
                    showInviteSheet = true
                }
            }
        } header: {
            SheetHeader(title: "Users", close: { dismiss() } )
        } subHeader: {
            SearchTextField(title: "Users", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)
                .padding(.horizontal, -20)
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .sheet(isPresented: $showInviteSheet) {
            EventInviteView(event: event)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
    }
            
//    var selectButton: some View {
//        Button {
//            users = users.isEmpty ? availableUsers : []
//        } label: {
//            Image(systemName: users.isEmpty ? "checklist.checked" : "checklist.unchecked")
//        }
//    }
}


fileprivate struct EventParticipantSheetLineItem: View {
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @Environment(EventModel.self) private var eventModel
    
    var user: CBUser
    //@Binding var users: [CBUser]
    @Bindable var event: CBEvent
    var labelWidth: CGFloat
    
    @State private var showConfirmationAlert = false
    @State private var showAdminErrorAlert = false
    
    var isSelected: Bool {
        event.participants.firstIndex(where: { $0.user.id == user.id }) != nil
    }
    
    var participantObject: CBEventParticipant? {
        event.participants.first(where: { $0.user.id == user.id })
    }
    
    var statusPieces: StatusItem {
        switch participantObject?.status?.enumID {
        case .pending: return StatusItem(color: .orange, icon: "person.crop.circle.badge.questionmark")
        case .accepted: return StatusItem(color: .green, icon: "person.crop.circle.badge.checkmark")
        case .rejected: return StatusItem(color: .red, icon: "person.crop.circle.badge.xmark")
        default: return StatusItem(color: .gray, icon: "person.crop.circle.badge.questionmark")
        }
    }
        
    var body: some View {
        HStack {
            HStack {
                Image(systemName: statusPieces.icon)
                    .foregroundStyle(statusPieces.color)
                Text(user.name)
                Spacer()
            }
            
            Spacer()
            Image(systemName: "checkmark")
                .opacity(isSelected ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !AppState.shared.user(is: user) {
                doIt(user)
            } else {
                showAdminErrorAlert = true
            }
        }
        .alert("Remove \(user.name) for eventID \(event.id)?", isPresented: $showConfirmationAlert) {
            Button("Yes", role: .destructive) {
                
                if event.participants.firstIndex(where: { $0.user.id == user.id }) != nil {
                    withAnimation {
                        event.participants.removeAll(where: {$0.user.id == user.id})
                    }
                    
                    Task {
                        let part = CBEventParticipant(user: user, eventID: event.id)
                        part.inviteTo = user
                        part.inviteFrom = AppState.shared.user!
                        part.status = XrefModel.getItem(from: .eventInviteStatus, byEnumID: .rejected)
                        let _ = await eventModel.leave(part)
                    }
                }
            }
            
            Button("No", role: .cancel) {}
        }
        .alert("The creator of the event cannot be removed", isPresented: $showAdminErrorAlert) {
            Button("OK", role: .cancel) {}
        }
    }
    
    func doIt(_ user: CBUser) {
        if isSelected {
            showConfirmationAlert = true
        } else {
            Task {
                await eventModel.invitePersonViaEmail(event: event, email: user.email)
            }
        }
    }
}


