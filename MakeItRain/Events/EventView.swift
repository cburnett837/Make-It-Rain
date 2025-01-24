//
//  EventViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI

struct EventView: View {
    private struct StatusItem {
        var color: Color
        var icon: String
    }
    
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description

    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(EventModel.self) private var eventModel
    
    @Bindable var event: CBEvent
    
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
    
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    
    var title: String { event.action == .add ? "New Event" : "Edit Event" }
    
    @FocusState private var focusedField: Int?
    @State private var showParticipantSheet = false
    @State private var showNoParticipantAlert = false
    
    @State private var deleteItem: CBEventItem?
    @State private var editItem: CBEventItem?
    @State private var itemEditID: CBEventItem.ID?
    
    @State private var deleteTrans: CBEventTransaction?
    @State private var editTrans: CBEventTransaction?
    @State private var transEditID: CBEventTransaction.ID?
    
    var addItemButton: some View {
        Button {
            itemEditID = UUID().uuidString
        } label: {
            Image(systemName: "plus")
        }
    }
        
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    var header: some View {
        Group {
            Group {
                if(event.enteredBy.id == AppState.shared.user!.id) {
                    SheetHeader(
                        title: title,
                        close: { validateParticipantsOnDimiss() },
                        view1: { addItemButton },
                        view3: { deleteButton }
                    )
                } else {
                    SheetHeader(
                        title: title,
                        close: { validateParticipantsOnDimiss() },
                        view1: { addItemButton }
                    )
                }
            }
            
            .padding()
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    
    @State private var localEventUsers: Array<CBUser> = []
    

    var body: some View {
        VStack(spacing: 0) {
            header
            List {
                HStack {
                    Text("Title")
                    Spacer()
                    #if os(iOS)
                    UITextFieldWrapperFancy(placeholder: "Event Title", text: $event.title, toolbar: {
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
                
                HStack {
                    Text("Budget")
                    Spacer()
                    
                    #if os(iOS)
                    UITextFieldWrapperFancy(placeholder: "Event Budget", text: $event.amountString ?? "", toolbar: {
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
                
                HStack {
                    Text("Starts")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DatePicker("", selection: $event.startDate ?? Date(), displayedComponents: [.date])
                        .labelsHidden()
                }
                HStack {
                    Text("Ends")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DatePicker("", selection: $event.endDate ?? Date(), displayedComponents: [.date])
                        .labelsHidden()
                }
                
                Section("Participants") {
                    ForEach($event.participants.filter { $0.wrappedValue.status?.enumID == .accepted && $0.wrappedValue.active }) { $part in
                        let focusID = getFocusIndex(for: part)
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .foregroundStyle(.green)
                            
                            Text(part.user.name)
                            Spacer()
                            
                            #if os(iOS)
                            UITextFieldWrapperFancy(placeholder: "Contribution", text: $part.amountString ?? "", toolbar: {
                                KeyboardToolbarView(focusedField: $focusedField)
                            })
                            .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                            .uiTag(focusID)
                            .uiTextAlignment(.right)
                            .uiClearButtonMode(.whileEditing)
                            .uiStartCursorAtEnd(true)
                            #else
                            TextField("Contribution", text: $part.amountString ?? "")
                                .multilineTextAlignment(.trailing)
                            #endif
                        }
                        .focused($focusedField, equals: focusID)
                    }
                    
                    ForEach(event.participants.filter { $0.status?.enumID == .pending && $0.user.id != AppState.shared.user?.id}) { invite in
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
                    
                    
                    if AppState.shared.user?.id == event.enteredBy.id {
                        Button("Manage Participants") {
                            showParticipantSheet = true
                        }
                    }
                }
                                
                ForEach(event.items.filter { $0.active }) { item in
                    Section {
                        ForEach(item.transactions.filter { $0.active }) { trans in
                            HStack {
                                Text(trans.title)
                                Spacer()
                                Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                transEditID = trans.id
                            }
                        }
                    } header: {
                        Text(item.title)
                            .onTapGesture {
                                itemEditID = item.id
                            }
                    }
                }
                
                
                
                    
                    
                
            }
            .scrollDismissesKeyboard(.immediately)
                
            Text("Created by \(event.enteredBy.name)")
                .foregroundStyle(.gray)
                .font(.caption2)
        }
        #if os(macOS)
        .padding(.bottom, 10)
        #endif
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task {
            event.deepCopy(.create)
            /// Just for formatting.
            event.amountString = event.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
            eventModel.upsert(event)
            
            
            event.participants.map({ $0.user }).forEach { user in
                if !localEventUsers.contains(user) {
                    localEventUsers.append(user)
                }
            }
            
            if event.startDate == nil { event.startDate = Date() }
            if event.endDate == nil { event.endDate = Date() }
            
            
            #if os(macOS)
            /// Focus on the title textfield.
            focusedField = 0
            #else
            if event.action == .add {
                focusedField = 0
                
                let admin = CBEventParticipant(user: AppState.shared.user!, eventID: event.id, email: AppState.shared.user!.email)
                admin.status = XrefModel.getItem(from: .eventInviteStatus, byID: 8)
                event.participants.append(admin)
                localEventUsers.append(AppState.shared.user!)
            }
            #endif
        }
        .onChange(of: event.participants.count) { oldValue, newValue in
            localEventUsers.removeAll()
            event.participants.map({ $0.user }).forEach { user in
                if !localEventUsers.contains(user) {
                    localEventUsers.append(user)
                }
            }
        }
        .confirmationDialog("Delete \"\(event.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                Task {
                    dismiss()
                    await eventModel.delete(event, andSubmit: true)
                }
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(event.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
        
        /// Just for formatting.
        .onChange(of: focusedField) { oldValue, newValue in
            if newValue == 1 {
                if event.amount == 0.0 {
                    event.amountString = ""
                }
            } else {
                if oldValue == 1 {
                    event.amountString = event.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                }
            }
        }
        .alert("Missing Participants", isPresented: $showNoParticipantAlert, actions: {
            Button("OK") {}
        }, message: {
            Text("At least 1 participant from your account is required.")
        })
        
        .sheet(isPresented: $showParticipantSheet, onDismiss: {
            handleParticipants()
        }, content: {
            let users = AppState.shared.accountUsers + event.participants
                .filter { $0.status?.enumID == .accepted }
                .filter { $0.active }
                .map { $0.user }
                .filter { !AppState.shared.accountUsers.contains($0) }
            
            MultiUserSheet(users: $localEventUsers, availableUsers: users, showInviteButton: true, event: event)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                //.frame(width: 300)
            #endif
        })
        
        
        
        
        .sheet(item: $editItem, onDismiss: {
            itemEditID = nil
        }, content: { item in
            EventItemView(event: event, item: item)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        })
        
        .onChange(of: itemEditID) { oldValue, newValue in
            if let newValue {
                editItem = event.getItem(by: newValue)
            } else {
                event.saveItem(id: oldValue!)
            }
        }
        
        
        .sheet(item: $editTrans, onDismiss: {
            transEditID = nil
        }, content: { trans in
            let item = event.items.filter ({ $0.transactions.map ({ $0.id }).contains(trans.id) }).first!
            
            FakeTransEditView(trans: trans, item: item, event: event)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        })
        
        .onChange(of: transEditID) { oldValue, newValue in
            if let newValue {
                let item = event.items.filter ({ $0.transactions.map ({ $0.id }).contains(newValue) }).first!
                editTrans = item.getTransaction(by: newValue)
            } else {
                let item = event.items.filter ({ $0.transactions.map ({ $0.id }).contains(oldValue!) }).first!
                item.saveTransaction(id: oldValue!)
                
                
                let trans = item.getTransaction(by: oldValue!)
                if trans.status.enumID == .claimed {
                    print("Creating real transaction in event view")
                    let realTrans = trans.realTransaction
                    realTrans.title = trans.title
                    realTrans.amountString = trans.amountString
                    realTrans.date = trans.date
                    realTrans.enteredBy = trans.paidBy!
                    realTrans.updatedBy = trans.paidBy!
                    realTrans.relatedTransactionID = trans.id
                    realTrans.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .eventTransaction)
                    
                    eventModel.pendingTransactionToSave.append(realTrans)
                }
                
                
            }
        }

    }
    
    
    func getFocusIndex(for participant: CBEventParticipant) -> Int {
        return (event.participants.firstIndex(of: participant) ?? 0) + 2
    }
    
    
    func validateParticipantsOnDimiss() {
        if event.action == .add && event.title.isEmpty {
            editID = nil
            dismiss()
        } else {
            if event.participants.filter({ $0.active }).isEmpty {
                showNoParticipantAlert = true
            } else {
                editID = nil
                dismiss()
            }
        }
        
        
    }
    
    
    func handleParticipants() {
        event.participants
        .filter({ $0.active && $0.status?.enumID == .accepted })
        .map({ $0.user })
        .forEach { user in
            print(user.email)
            if !localEventUsers.contains(user) {
                print("user \(user.email) isnt in localList")
                
                //event.participants.removeAll(where: { $0.user.id == user.id })
                let index = event.participants.firstIndex(where: { $0.user.id == user.id })
                if let index {
                    print("updating \(user.email) setting active = false")
                    
                    event.participants[index].action = .delete
                    event.participants[index].active = false
                }
            } else {
                print("user \(user.email) is in localList")
                let index = event.participants.firstIndex(where: { $0.user.id == user.id })
                if let index {
                    print("updating \(user.email) setting active = true")
                    event.participants[index].action = .edit
                    event.participants[index].active = true
                }
            }
        }
                    
        localEventUsers.forEach { user in
            print("LOCAL USER \(user.email)")
            if !event.participants.filter({$0.active}).map({ $0.user }).contains(user) {
                print("LOCAL USER not in participants - adding \(user.email)")
                let new = CBEventParticipant(user: user, eventID: event.id, email: user.email)
                event.participants.append(new)
            }
        }
    }
    
}
