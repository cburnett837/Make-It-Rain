//
//  UserSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/22/25.
//

import SwiftUI

struct UserSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @Binding var selectedUser: CBUser?
    var availableUsers: [CBUser]
    
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    
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
            close: { dismiss() }
        )
        .padding(.bottom, 12)
        .padding(.horizontal, 20)
        .padding(.top)
        
        SearchTextField(title: "Users", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)                
        
        List {
            if searchText.isEmpty {
                Section("None") {
                    HStack {
                        Text("None")
                            .strikethrough(true)
                        Spacer()
                        if selectedUser?.id == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { doIt(nil) }
                }
            }
            
            
            Section("Your Categories") {
                ForEach(filteredUsers) { user in
                    HStack {
                        Text(user.name)
                        Spacer()
                        if selectedUser?.id == user.id {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { doIt(user) }
                }
            }
        }
    }
    
    func doIt(_ user: CBUser?) {
        selectedUser = user
        dismiss()
    }
}
