//
//  UserPicker.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/21/26.
//

import SwiftUI


struct UserPicker: View {
    @Environment(\.dismiss) var dismiss
    var title: String = "Account Users"
    @Binding var userId: Int?
    
    var users: [CBUser] {
        AppState.shared.accountUsers.sorted(by: { $0.name < $1.name })
    }
    
    var body: some View {
        List {
            Section {
                ForEach(users) { user in
                    Button {
                        userId = user.id
                        dismiss()
                    } label: {
                        HStack {
                            UserAvatar(user: user)
                            Text(user.name)
                            Spacer()
                            
                            Image(systemName: "checkmark")
                                .opacity(userId == user.id ? 1 : 0)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            everyoneButton
        }
        .navigationTitle(title)
    }
    
    @ViewBuilder
    var everyoneButton: some View {
        Section("Everyone") {
            Button {
                userId = nil
                dismiss()
            } label: {
                HStack {
                    ForEach(users) { user in
                        UserAvatar(user: user)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark")
                        .opacity(userId == nil ? 1 : 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}
