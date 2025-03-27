//
//  EventViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI
import Charts

struct EventView: View {
    private struct StatusItem {
        var color: Color
        var icon: String
    }
    
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description

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
    
    @State private var showItemsSheet = false
    @State private var showCategoriesSheet = false
    
    @State private var deleteTrans: CBEventTransaction?
    @State private var editTrans: CBEventTransaction?
    @State private var transEditID: CBEventTransaction.ID?
    @State private var transNewItem: CBEventItem?
    
    
    struct ChartData: Identifiable {
        let id = UUID().uuidString
        var budget: Double = 0.0
        var userData: [ChartUserData] = []
    }
    
    struct ChartUserData: Identifiable {
        let id = UUID().uuidString
        let user: CBUser
        var contribution: Double
        var expenses: Double
    }
    
    @State private var chartData: ChartData = ChartData()
    
    var isAdmin: Bool {
        return event.enteredBy.id == AppState.shared.user!.id
    }
    
    var optionMenu: some View {
        Menu {
            if(isAdmin) {
                Button {
                    showItemsSheet = true
                } label: {
                    Text("Manage Sections")
                }
                
                Button {
                    showCategoriesSheet = true
                } label: {
                    Text("Manage Categories")
                }
            }
            
            Button {
                transEditID = UUID().uuidString
            } label: {
                Text("Add Transaction")
            }
        } label: {
            Image(systemName: "ellipsis")
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
                if(isAdmin) {
                    SheetHeader(
                        title: title,
                        //subtitle: "Created by \(event.enteredBy.name)",
                        close: { validateParticipantsOnDimiss() },
                        view1: { optionMenu },
                        view3: { deleteButton }
                    )
                } else {
                    SheetHeader(
                        title: title,
                        //subtitle: "Created by \(event.enteredBy.name)",
                        close: { validateParticipantsOnDimiss() },
                        view1: { optionMenu }
                    )
                }
            }
            .padding()                        
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
                    UITextFieldWrapper(placeholder: "Event Title", text: $event.title, toolbar: {
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
                .disabled(!isAdmin)
                
                HStack {
                    Text("Budget")
                    Spacer()
                    
#if os(iOS)
                    UITextFieldWrapper(placeholder: "Event Budget", text: $event.amountString ?? "", toolbar: {
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
                .disabled(!isAdmin)
                
                HStack {
                    Text("Starts")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if isAdmin {
#if os(iOS)
                        UIKitDatePicker(date: $event.startDate, alignment: .trailing) // Have to use because of reformatting issue
#else
                        DatePicker("", selection: $event.startDate ?? Date(), displayedComponents: [.date])
                            .labelsHidden()
#endif
                    } else {
                        Spacer()
                        Text(event.startDate?.string(to: .datePickerDateOnlyDefault) ?? "N/A")
                    }
                }
                .disabled(!isAdmin)
                
                HStack {
                    Text("Ends")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    if isAdmin {
#if os(iOS)
                        UIKitDatePicker(date: $event.endDate, alignment: .trailing) // Have to use because of reformatting issue
#else
                        DatePicker("", selection: $event.endDate ?? Date(), displayedComponents: [.date])
                            .labelsHidden()
#endif
                    } else {
                        Spacer()
                        Text(event.endDate?.string(to: .datePickerDateOnlyDefault) ?? "N/A")
                        
                    }
                    
                    //UIKitDatePicker(date: $event.endDate, alignment: .trailing) // Have to use because of reformatting issue
                    
                    //                    DatePicker("", selection: $event.endDate ?? Date(), displayedComponents: [.date])
                    //                        .labelsHidden()
                }
                .disabled(!isAdmin)
                
                chartSection
                
                Section("Participants") {
                    ForEach($event.participants.filter { $0.wrappedValue.status?.enumID == .accepted && $0.wrappedValue.active }) { $part in
                        let focusID = getFocusIndex(for: part)
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .foregroundStyle(.green)
                            
                            Text(part.user.name)
                                .foregroundStyle(part.user.id == AppState.shared.user!.id ? Color.primary : Color.gray)
                            Spacer()
                            
#if os(iOS)
                            UITextFieldWrapper(placeholder: "Contribution", text: $part.amountString ?? "", toolbar: {
                                KeyboardToolbarView(focusedField: $focusedField)
                            })
                            .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                            .uiTag(focusID)
                            .uiTextAlignment(.right)
                            .uiClearButtonMode(.whileEditing)
                            .uiStartCursorAtEnd(true)
                            .uiTextColor(part.user.id == AppState.shared.user!.id ? UIColor(.primary) : UIColor(.gray))
#else
                            TextField("Contribution", text: $part.amountString ?? "")
                                .multilineTextAlignment(.trailing)
#endif
                        }
                        .focused($focusedField, equals: focusID)
                        .disabled(part.user.id != AppState.shared.user!.id)
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
                            VStack(alignment: .leading) {
                                Text(invite.email ?? "N/A")
                                //                                Text(invite.id)
                                //                                    .foregroundStyle(.gray)
                                //                                    .font(.caption2)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    
                    if isAdmin {
                        Button("Add / Remove") {
                            showParticipantSheet = true
                        }
                    }
                }
                
                ForEach(event.items.filter { $0.active }) { item in
                    Section {
                        ForEach(event.transactions.filter { $0.active && $0.item?.id == item.id }) { trans in
                            Button {
                                transEditID = trans.id
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(trans.title)
                                        Spacer()
                                        Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Circle()
                                            .frame(width: 6, height: 6)
                                            .foregroundStyle(trans.category?.color ?? .primary)
                                        
                                        Text(trans.category?.title ?? "N/A")
                                            .foregroundStyle(.gray)
                                            .font(.caption)
                                    }
                                    
                                    
                                    if let paidBy = trans.paidBy {
                                        Text(paidBy.name)
                                            .font(.footnote)
                                            .foregroundStyle(.gray)
                                    }
                                    
                                }
                            }
                            .foregroundStyle(.primary)
                            .disabled(!AppState.shared.user(is: trans.paidBy) && trans.status.enumID == .claimed)
                        }
                        Button("Add") {
                            transNewItem = item
                            transEditID = UUID().uuidString
                        }
                    } header: {
                        HStack {
                            Text(item.title)
                            Spacer()
                        }
                    }
                }
                
                
                Section {
                    ForEach(event.transactions.filter { $0.active && $0.item == nil }) { trans in
                        Button {
                            transEditID = trans.id
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(trans.title)
                                    Spacer()
                                    Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                }
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .frame(width: 6, height: 6)
                                        .foregroundStyle(trans.category?.color ?? .primary)
                                    
                                    Text(trans.category?.title ?? "N/A")
                                        .foregroundStyle(.gray)
                                        .font(.caption)
                                }
                                
                                if let paidBy = trans.paidBy {
                                    Text(paidBy.name)
                                        .font(.footnote)
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                        //.disabled(trans.enteredBy.id != AppState.shared.user!.id)
                        .disabled(!AppState.shared.user(is: trans.paidBy) && trans.status.enumID == .claimed)
                        
                    }
                    Button("Add") {
                        transEditID = UUID().uuidString
                    }
                } header: {
                    HStack {
                        Text("(No Section)")
                        Spacer()
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            
            
            
            if !eventModel.openEvents.isEmpty {
                if eventModel.openEvents.map({$0.eventID}).contains(event.id) {
                    if !eventModel.openEvents.filter({$0.eventID == event.id && $0.user.id != AppState.shared.user?.id}).isEmpty {
                        HStack {
                            Text("Currently Viewed By:")
                                .font(.caption2)
                                                    
                            //ScrollView(.horizontal) {
                                HStack {
                                    ForEach(eventModel.openEvents.filter{$0.eventID == event.id && $0.user.id != AppState.shared.user?.id}, id: \.id) { openEvent in
                                        Text(openEvent.user.name)
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                    }
                                }
                            //}
                        }
                        
                    }
                }
            }
        }
        #if os(macOS)
        .padding(.bottom, 10)
        #endif
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task {
            prepareData()
            
            event.deepCopy(.create)
            /// Just for formatting.
            event.amountString = event.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
            eventModel.upsert(event)
            
            event.participants
            .filter { $0.status?.enumID != .rejected && $0.active }
            .map({ $0.user })
            .forEach { user in
                if !localEventUsers.contains(user) {
                    localEventUsers.append(user)
                }
            }
            
            if event.startDate == nil { event.startDate = Date() }
            if event.endDate == nil { event.endDate = Date() }
            
            
            #if os(macOS)
            /// Focus on the title textfield.
            focusedField = 0
            #endif
            if event.action == .add {
                focusedField = 0
                
                let admin = CBEventParticipant(user: AppState.shared.user!, eventID: event.id, email: AppState.shared.user!.email)
                admin.status = XrefModel.getItem(from: .eventInviteStatus, byID: 8)
                admin.inviteTo = AppState.shared.user!
                event.participants.append(admin)
                localEventUsers.append(AppState.shared.user!)
            }
            
            
            
            
            print("⚠️categories from object")
            for each in event.categories {
                print(each.id)
            }
            print("⚠️categories from deepcopy")
            for each in event.deepCopy!.categories {
                print(each.id)
            }
            
            let _ = await eventModel.markEvent(as: .open, eventID: event.id)
            
            
        }
        .onChange(of: event.participants.count) { oldValue, newValue in
            localEventUsers.removeAll()
            event.participants
            .filter { $0.status?.enumID != .rejected && $0.active }
            .map({ $0.user })
            .forEach { user in
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
            
            EventParticipantView(users: $localEventUsers, availableUsers: users, showInviteButton: true, event: event)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                //.frame(width: 300)
            #endif
        })
        
        
        
        
        .sheet(isPresented: $showItemsSheet) {
            EventItemView(event: event)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        
        .sheet(isPresented: $showCategoriesSheet) {
            EventCategoriesTable(event: event)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        
        
        .sheet(item: $editTrans, onDismiss: {
            transEditID = nil
        }, content: { trans in
            FakeTransEditView(trans: trans, event: event, item: transNewItem)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        })
        
        .onChange(of: transEditID) { oldValue, newValue in
            if let newValue {
                editTrans = event.getTransaction(by: newValue)
            } else {
                transNewItem = nil
                
                let trans = event.getTransaction(by: oldValue!)
                if let paidBy = trans.paidBy {
                    if !AppState.shared.user(is: paidBy) {
                        return
                    }
                }
                
                if trans.hasChanges() {
                    trans.changedDate = Date()
                }
                                                                
                event.saveTransaction(id: oldValue!) /// pretty much just validates right now. 2/5/25               
            }
        }
        .onChange(of: event.amount) {
            prepareData()
        }
        .onChange(of: event.participants.map { $0.amount }) {
            prepareData()
        }
        .onChange(of: event.participants.map { $0.status }) {
            prepareData()
        }
        .onChange(of: event.participants.map { $0.active }) {
            prepareData()
        }
        .onChange(of: event.transactions.map { $0.amount }) {
            prepareData()
        }
        .onChange(of: event.transactions.map { $0.active }) {
            prepareData()
        }
        .onChange(of: event.transactions.map { $0.status }) {
            prepareData()
        }
    }
    
    
    var chartSection: some View {
        Section {
            Chart {
                BarMark(
                    x: .value("Amount", chartData.budget),
                    y: .value("Key", "Budget")
                )
                .foregroundStyle(Color.gray)
                
                ForEach(chartData.userData) { userData in
                    BarMark(
                        x: .value("Contribution", userData.contribution),
                        y: .value("Key", "Contributions")
                    )
                    //.position(by: .value("User", userData.user.id))
                    .foregroundStyle(by: .value("User", userData.user.name))
                    
                    BarMark(
                        x: .value("Name", userData.expenses * -1),
                        y: .value("Key", "Expenses")
                    )
                    .foregroundStyle(by: .value("User", userData.user.name))
                    //.foregroundStyle(by: .value("Name", "Expenses"))
                    //.foregroundStyle(by: .value("Shape Color", metric.user.id))
                    //.foregroundStyle(metric.category.color)
                }
            }
            //.chartLegend(.hidden)
//            .chartForegroundStyleScale([
//                "Budget": .gray,
//                "Contributions": .orange,
//                "Expenses": .green
//            ])
        }
    }
    
//    func graphColors(for data: [ChartData]) -> [Color] {
//        var returnColors = [Color]()
//        for metric in data {
//            returnColors.append(metric.category.color)
//        }
//        return returnColors
//    }
    
    
    func prepareData() {
        //let partCount = event.participants.filter { $0.active && $0.status == XrefModel.getItem(from: .eventInviteStatus, byEnumID: .accepted) }.count
        
        
        chartData = ChartData()
        chartData.budget = event.amount ?? 0.0
        
        
        for part in event.participants.filter({ $0.active && $0.status == XrefModel.getItem(from: .eventInviteStatus, byEnumID: .accepted) }) {
            let expenses =
                event
                .transactions
                .filter { $0.active && $0.paidBy?.id == part.user.id }
                .map { $0.amount }
                .reduce(0.0, +)
                
            chartData.userData.append(ChartUserData(user: part.user, contribution: part.amount ?? 0.0, expenses: expenses))
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
            if !event.participants.filter({ $0.active }).map({ $0.user }).contains(user) {
                print("LOCAL USER not in participants - adding \(user.email)")
                let new = CBEventParticipant(user: user, eventID: event.id, email: user.email)
                event.participants.append(new)
            }
        }
    }
    
}
