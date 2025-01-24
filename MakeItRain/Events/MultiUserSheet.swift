//
//  EventParticipantSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/25.
//

import SwiftUI


struct MultiUserSheet: View {
    
    private struct StatusItem {
        var color: Color
        var icon: String
    }
    
    @Environment(\.dismiss) var dismiss
    @Environment(EventModel.self) private var eventModel
    
    @Binding var users: Array<CBUser>
    var availableUsers: Array<CBUser>
    var showInviteButton: Bool
    @Bindable var event: CBEvent
                
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    @State private var labelWidth: CGFloat = 20.0
    
    @State private var showInviteSheet = false    
    
    var filteredUsers: Array<CBUser> {
        if searchText.isEmpty {
            return availableUsers
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        } else {
            return availableUsers
                .filter { $0.name.localizedStandardContains(searchText) }
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        }
    }

    
    var body: some View {
        SheetHeader(
            title: "Users",
            close: { dismiss() },
            view1: { selectButton }
        )
        .padding(.bottom, 12)
        .padding(.horizontal, 20)
        .padding(.top)
        
        StandardTextField("Search Users", text: $searchText, isSearchField: true, focusedField: $focusedField, focusValue: 0)
            //.focused($focusedField, equals: .search)
            .padding(.horizontal, 20)
        
        List {
            Section("Available Users") {
                ForEach(filteredUsers) { user in
                    EventParticipantSheetLineItem(user: user, users: $users, event: event, labelWidth: labelWidth)
                }
            }
            
            if showInviteButton {
                Section("Invited Users") {
                    ForEach(event.participants.filter {$0.status?.enumID == .pending}) { invite in
                        
                        var statusPieces: StatusItem {
                            switch invite.status?.enumID {
                            case .pending: return StatusItem(color: .orange, icon: "person.crop.circle.badge.questionmark")
                            case .accepted: return StatusItem(color: .green, icon: "person.crop.circle.badge.checkmark")
                            case .rejected: return StatusItem(color: .red, icon: "person.crop.circle.badge.xmark")
                            default: return StatusItem(color: .gray, icon: "questionmark")
                            }
                        }
                                                
                        HStack {
                            Image(systemName: statusPieces.icon)
                                .foregroundStyle(statusPieces.color)
                            Text(invite.email ?? "N/A")
                            Spacer()
                        }
                    }
                    
                    Button("Create Invite") {
                        showInviteSheet = true
                    }
                }
            }
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .sheet(isPresented: $showInviteSheet) {
            EventInviteView(event: event)
        }
    }
            
    var selectButton: some View {
        Button {
            users = users.isEmpty ? availableUsers : []
        } label: {
            Image(systemName: users.isEmpty ? "checklist.checked" : "checklist.unchecked")
        }
    }
}


fileprivate struct EventParticipantSheetLineItem: View {
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    
    var user: CBUser
    @Binding var users: [CBUser]
    @Bindable var event: CBEvent
    var labelWidth: CGFloat
    
    @State private var showConfirmationAlert = false
    
    
    var body: some View {
        HStack {
            Text(user.name)
            Spacer()
            Image(systemName: "checkmark")
                .opacity(users.contains(user) ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { doIt(user) }
        .alert("Remove this person?", isPresented: $showConfirmationAlert) {
            Button("Yes", role: .destructive) {
                //event.participants.removeAll(where: { $0.user.id == user.id })
                if let index = event.participants.firstIndex(where: { $0.user.id == user.id }) {
                    
                    print("Kicking participant id \(event.participants[index].id)")
                    event.participants[index].active = false
                }
                users.removeAll(where: { $0.id == user.id })
            }
            
            Button("No", role: .cancel) {
                
            }
        }
    }
    
    func doIt(_ user: CBUser) {
        print("-- \(#function)")
        if users.contains(user) {
            if user.accountID != AppState.shared.user?.accountID {
                showConfirmationAlert = true
            } else {
                users.removeAll(where: { $0.id == user.id })
            }
            
        } else {
            users.append(user)
        }
    }
}


