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
    
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme

    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(EventModel.self) private var eventModel
    
    @Bindable var event: CBEvent
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
    
    @State private var showDeleteAlert = false
    @State private var showLeaveAlert = false
    //@State private var labelWidth: CGFloat = 20.0
    
    @State private var showDetailsSheet = false
    @State private var showItemsSheet = false
    @State private var showCategoriesSheet = false
    @State private var showParticipantSheet = false
    @State private var showCamera: Bool = false
    @State private var showPhotosPicker: Bool = false
    
    @State private var editTrans: CBEventTransaction?
    @State private var transEditID: CBEventTransaction.ID?
    @State private var transNewItem: CBEventItem?
            
    @State private var editParticipant: CBEventParticipant?
    @State private var participantEditID: CBEventParticipant.ID?
    
    @FocusState private var focusedField: Int?
        
    struct ChartData: Identifiable {
        let id = UUID().uuidString
        var budget: Double = 0.0
        var ideas: Double = 0.0
        var userData: [ChartUserData] = []
    }
    
    struct ChartUserData: Identifiable {
        let id = UUID().uuidString
        let user: CBUser
        var contribution: Double
        var expenses: Double
    }
    
    
    struct PersonalChartData: Identifiable {
        let id = UUID().uuidString
        let user: CBUser = AppState.shared.user!
        var contribution: Double = 0.0
        var expenses: Double = 0.0
        var ideas: Double = 0.0
    }
    
    
    @State private var chartData: ChartData = ChartData()
    @State private var personalChartData: PersonalChartData = PersonalChartData()
    
    var title: String { event.action == .add ? "New Event" : "Edit Event" }
    
    var isAdmin: Bool { event.enteredBy.id == AppState.shared.user!.id }
    
    var isOpenByAnotherUser: Bool {
        OpenRecordManager.shared.openOrClosedRecords
            .filter { $0.recordType.enumID == .event && $0.recordID == event.id && $0.user.id != AppState.shared.user?.id }
            .filter { $0.active }
            .map { $0.recordID }
            .contains(event.id)
    }
    
    var otherViewingUsers: Array<CBUser> {
        OpenRecordManager.shared.openOrClosedRecords
            .filter { $0.recordType.enumID == .event && $0.recordID == event.id && $0.user.id != AppState.shared.user?.id }
            .filter { $0.active }
            .map { $0.user }
            .uniqued(on: \.id)
    }
    
    @State private var selectedTab: String = "details"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            eventDetails
                .tabItem { Label("Details", systemImage: "list.bullet") }
                .tag("details")
                #if os(iOS)
                .toolbarBackground(.visible, for: .tabBar)
                #endif
            
//            eventIdeas
//                .tabItem { Label("Ideas", systemImage: "brain.head.profile") }
//                .tag("ideas")
//                #if os(iOS)
//                .toolbarBackground(.visible, for: .tabBar)
//                #endif
            
            eventPhotos
                .tabItem { Label("Photos", systemImage: "photo") }
                .tag("photos")
                #if os(iOS)
                .toolbarBackground(.visible, for: .tabBar)
                #endif
        }
        
        .task { await viewTask() }
        /// Sync the photos when leaving the photo tab
//        .onChange(of: selectedTab) { oldValue, newValue in
//            if oldValue == "photos" {
//                let _ = eventModel.saveEvent(id: event.id, calModel: calModel)
//            }
//        }
        
        // MARK: - Modifiers to adjust the chart
        .onChange(of: event.amount) { prepareData() }
        .onChange(of: event.participants.filter { AppState.shared.user(is: $0.user) }.first?.personalAmount) { prepareData() }
        .onChange(of: event.participants.map { $0.groupAmount }) { prepareData() }
        .onChange(of: event.participants.map { $0.status }) { prepareData() }
        .onChange(of: event.participants.map { $0.active }) { prepareData() }
        .onChange(of: event.transactions.map { $0.amount }) { prepareData() }
        .onChange(of: event.transactions.map { $0.active }) { prepareData() }
        .onChange(of: event.transactions.map { $0.status }) { prepareData() }
        
        // MARK: - Handling Lifecycles (iPhone)
//        #if os(iOS)
//        .onChange(of: scenePhase) { oldPhrase, newPhase in
//            if newPhase == .inactive {
//                print("scenePhase: event Inactive")
//                
//            } else if newPhase == .active {
//                print("scenePhase: event Active")
//                Task {
//                    let recordType = XrefModel.getItem(from: .openRecords, byEnumID: .event)
//                    let mode = CBOpenOrClosedRecord(recordID: event.id, recordType: recordType, openOrClosed: .open)
//                    let _ = await OpenRecordManager.shared.markRecordAsOpenOrClosed(mode)
//                }
//                                                
//            } else if newPhase == .background {
//                print("scenePhase: event Background")
//                Task {
//                    let recordType = XrefModel.getItem(from: .openRecords, byEnumID: .event)
//                    let mode = CBOpenOrClosedRecord(recordID: event.id, recordType: recordType, openOrClosed: .closed)
//                    let _ = await OpenRecordManager.shared.markRecordAsOpenOrClosed(mode)
//                }
//            }
//        }
//        #endif
    }
    
    
    var eventDetails: some View {
        Group {
            StandardContainer(.list) {
                Section("Details") {
                    titleTextField
                    budgetTextField
                    startDatePicker
                    endDatePicker
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isAdmin {
                        showDetailsSheet = true
                    } else {
                        AppState.shared.showAlert("Only the event host can edit event details.")
                    }
                }
                //.disabled(!isAdmin)
                
                groupChartSection
                
                personalChartSection
                
                Section("Participants") {
                    acceptedParticipants
                    invitedParticipants
                                        
                    if isAdmin {
                        Button("Add / Remove") {
                            showParticipantSheet = true
                        }
                    }
                }
                
                transactionsList
            } header: {
                header
            } footer: {
                currentlyViewingParticipants
            }
            #if os(macOS)
            .padding(.bottom, 10)
            #endif
            //.onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }

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
            
            
            // MARK: - Delete Event Confirmation Dialog
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
            
            
            // MARK: - Leave Event Confirmation Dialog
            .confirmationDialog("Leave \"\(event.title)\"?", isPresented: $showLeaveAlert, actions: {
                Button("Yes", role: .destructive) {
                    dismiss()
                    Task {
                        let part = CBEventParticipant(user: AppState.shared.user!, eventID: event.id)
                        part.inviteTo = AppState.shared.user!
                        part.inviteFrom = AppState.shared.user!
                        part.status = XrefModel.getItem(from: .eventInviteStatus, byEnumID: .rejected)
                        let _ = await eventModel.leave(part)
                    }
                }
                
                Button("No", role: .cancel) {
                    showLeaveAlert = false
                }
            }, message: {
                #if os(iOS)
                Text("Leave \"\(event.title)\"?\nYou can be reinvited by the host if you change your mind.")
                #else
                Text("You can be reinvited by the host if you change your mind.")
                #endif
            })
            
              
            
            // MARK: - Item Sheet
            .sheet(isPresented: $showItemsSheet) {
                EventItemsTable(event: event)
                #if os(macOS)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.fitted)
                #endif
            }
            
            // MARK: - Details Sheet
            .sheet(isPresented: $showDetailsSheet, onDismiss: {
                if event.hasChanges() {
                    Task {
                        await eventModel.submit(event)
                    }
                }
            }) {
                EventDetailsView(event: event)
                #if os(macOS)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.fitted)
                #endif
            }
            
            
            // MARK: - Category Sheet
            .sheet(isPresented: $showCategoriesSheet) {
                EventCategoriesTable(event: event)
                #if os(macOS)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.fitted)
                #endif
            }
            
            
            // MARK: - Transaction Sheet
            .onChange(of: transEditID) { oldValue, newValue in
                if let newValue {
                    editTrans = event.getTransaction(by: newValue)
                } else {
                    setFileModelId()
                    transNewItem = nil
                    
                    let trans = event.getTransaction(by: oldValue!)
                    if let paidBy = trans.paidBy {
                        if !AppState.shared.user(is: paidBy) {
                            return
                        }
                    }
                    
                    if event.saveTransaction(id: oldValue!) {
                        trans.updatedDate = Date()
                        trans.changedDate = Date()
                        Task {
                            let _ = await eventModel.submit(trans)
                        }
                    } else {
                        print("❌Event trans has no changes")
                        Task {
                            print("Marking Trans as closed for trans \(oldValue!)")
                            //try? await Task.sleep(nanoseconds: UInt64(2 * Double(NSEC_PER_SEC)))
                            //print("post - timer - Marking Trans as closed for trans \(oldValue!)")
                            
                            if trans.action != .add {
                                let recordType = XrefModel.getItem(from: .openRecords, byEnumID: .eventTransaction)
                                let mode = CBOpenOrClosedRecord(recordID: oldValue!, recordType: recordType, openOrClosed: .closed)
                                let _ = await OpenRecordManager.shared.markRecordAsOpenOrClosed(mode)
                            }
                        }
                    }
                }
            }
            .sheet(item: $editTrans, onDismiss: {
                transEditID = nil
            }, content: { trans in
                EventTransactionView(trans: trans, event: event, item: transNewItem)
                #if os(macOS)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.fitted)
                #endif
            })
            
            
            // MARK: - Participant Sheet and Participant Table Sheet
            .onChange(of: participantEditID) { oldValue, newValue in
                if let newValue {
                    editParticipant = event.getParticipant(by: newValue)
                } else {
                    
                    if let part = event.getParticipant(by: oldValue!) {
                        if part.hasChanges() {
                            if event.saveParticipant(id: oldValue!) {
                                Task {
                                    await eventModel.submit(part)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(item: $editParticipant, onDismiss: {
                participantEditID = nil
            }, content: { part in
                EventParticipantView(part: part, event: event)
                #if os(macOS)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.fitted)
                #endif
            })
            .sheet(isPresented: $showParticipantSheet) {
                EventParticipantsTable(event: event)
                #if os(macOS)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.fitted)
                    //.frame(width: 300)
                #endif
            }
        }
    }
    
    
    var eventPhotos: some View {
        StandardContainer {
            StandardFileSection(
                files: $event.files,
                fileUploadCompletedDelegate: eventModel,
                parentType: .event,
                displayStyle: .grid,
                showInScrollView: false,
                showCamera: $showCamera,
                showPhotosPicker: $showPhotosPicker
            )
        } header: {
            header
        } footer: {
            currentlyViewingParticipants
        }
    }
    
    
    
    // MARK: - Subviews
    var titleTextField: some View {
        HStack {
            Text("Title")
            Spacer()
            Text(event.title)
        }
    }
    
    
    var budgetTextField: some View {
        HStack {
            Text("Budget")
            Spacer()
            Text(event.amountString ?? "")
        }
    }

    
    var startDatePicker: some View {
        HStack {
            Text("Starts")
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(event.startDate?.string(to: .datePickerDateOnlyDefault) ?? "N/A")
        }
    }
    
    
    var endDatePicker: some View {
        HStack {
            Text("Ends")
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(event.endDate?.string(to: .datePickerDateOnlyDefault) ?? "N/A")
        }
    }
    
    
    var groupChartSection: some View {
        Section("Group Insights") {
            Chart {
                BarMark(x: .value("Amount", chartData.budget), y: .value("Key", "Budget"))
                    .foregroundStyle(Color.gray)
                
                ForEach(chartData.userData) { userData in
                    BarMark(x: .value("Contribution", userData.contribution), y: .value("Key", "Contributions"))
                        .foregroundStyle(by: .value("User", userData.user.name))
                }
                                
                ForEach(chartData.userData) { userData in
                    BarMark(x: .value("Name", userData.expenses * -1), y: .value("Key", "Claimed Expenses"))
                        .foregroundStyle(by: .value("User", userData.user.name))
                }
                
                BarMark(x: .value("Amount", chartData.ideas * -1), y: .value("Key", "Expense Ideas") )
                    .foregroundStyle(Color.red)
            }
            .frame(minHeight: 150)
            //.chartLegend(.hidden)
//            .chartForegroundStyleScale([
//                "Budget": .gray,
//                "Contributions": .orange,
//                "Expenses": .green
//            ])
        }
    }
    
    
    
    var personalChartSection: some View {
        Section("Personal Insights") {
            Chart {
                BarMark(x: .value("Budget", personalChartData.contribution), y: .value("Key", "Contributions"))
                    .foregroundStyle(by: .value("User", personalChartData.user.name))
                                                                
                BarMark(x: .value("Name", personalChartData.expenses * -1), y: .value("Key", "Expenses"))
                    .foregroundStyle(by: .value("User", personalChartData.user.name))
                
                BarMark(x: .value("Ideas", personalChartData.ideas * -1), y: .value("Key", "Ideas"))
                    .foregroundStyle(by: .value("User", personalChartData.user.name))
            }
            //.frame(minHeight: 150)
            .chartLegend(.hidden)
//            .chartForegroundStyleScale([
//                "Budget": .gray,
//                "Contributions": .orange,
//                "Expenses": .green
//            ])
        }
    }
    
    
    
    var acceptedParticipants: some View {
        ForEach(event.participants.filter { $0.status?.enumID == .accepted && $0.active }) { part in
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .foregroundStyle(.green)
                
                Text(part.user.name)
                    .foregroundStyle(part.user.id == AppState.shared.user!.id ? Color.primary : Color.gray)
                Spacer()
                Text(part.groupAmountString ?? "")
            }
            .contentShape(Rectangle())
            .onTapGesture {
                participantEditID = part.id
            }
            .disabled(part.user.id != AppState.shared.user!.id)
        }
    }
    
    
    var invitedParticipants: some View {
        ForEach(event.participants.filter { $0.status?.enumID == .pending && $0.active}) { invite in
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
                    Text(invite.user.name)
                }
                
                Spacer()
            }
        }
    }
    
    func transactionsWith(item: CBEventItem) -> [CBEventTransaction] {
        return (event.transactions.filter { $0.isNotPrivate && $0.active && $0.item?.id == item.id }
        + event.transactions.filter { $0.isPrivateAndBelongsToUser && $0.active && $0.item?.id == item.id })
        .sorted { $0.title < $1.title }
    }
    
    func transactionsWithNoItem() -> [CBEventTransaction] {
        return event.transactions.filter { $0.isNotPrivate && $0.active && $0.item == nil }
        + event.transactions.filter { $0.isPrivateAndBelongsToUser && $0.active && $0.item == nil }
        .sorted { $0.title < $1.title }
    }
    
    
    @ViewBuilder var transactionsList: some View {
        //Group {
            ForEach(event.items.filter { $0.active }) { item in
                Section(item.title) {
                    ForEach(transactionsWith(item: item)) { trans in
                        TransLineView(trans: trans, transEditID: $transEditID)
                    }
                                        
                    Button("Add") {
                        transNewItem = item
                        transEditID = UUID().uuidString
                    }
                }
            }
            
//            Button("Print open records") {
//                OpenRecordManager.shared.openOrClosedRecords.forEach {
//                    print($0.user.id)
//                    print($0.recordID)
//                    print($0.recordType.enumID)
//                    print($0.active)
//                    print("----")
//                }
//            }
            
            Section("Misc") {
                ForEach(transactionsWithNoItem()) { trans in
                    TransLineView(trans: trans, transEditID: $transEditID)
                }
                                
                Button("Add") {
                    transEditID = UUID().uuidString
                }
            }
        //}
        
    }
    
    
    var currentlyViewingParticipants: some View {
        Group {
            if isOpenByAnotherUser {
                VStack(spacing: 2) {
                    Text("Currently Viewed By:")
                        .font(.caption2)
                                            
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(otherViewingUsers) { user in
                                Text(user.name)
                                    .bold()
                                    .font(.caption2)
                                    .foregroundStyle(Color.theme)
                            }
                        }
                    }
                    .defaultScrollAnchor(.center)
                }
            }
        }
    }
    
    
    var optionMenu: some View {
        Menu {
            if(isAdmin) {
                Section {
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
            }
            
            Button {
                transEditID = UUID().uuidString
            } label: {
                Text("Add Transaction")
            }
            
            Section {
                Button("Add Photo") {
                    showPhotosPicker = true
                }
                Button("Take Photo") {
                    showCamera = true
                }
            }
            
            if !event.amIAdmin() {
                Section {
                    Button("Leave Event", role: .destructive) {
                        showLeaveAlert = true
                    }
                }
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
    }
    
    
    struct TransLineView: View {
        @Local(\.useWholeNumbers) var useWholeNumbers
        //@Local(\.colorTheme) var colorTheme
        @Environment(EventModel.self) private var eventModel
        
        @Bindable var trans: CBEventTransaction
        @Binding var transEditID: String?
        
        var body: some View {
//            if trans.id == "20" {
//                let _ = Self._printChanges()
//            }
            
            Button {
                transEditID = trans.id
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    if(transIsOpenByAnotherUser) {
                        TransViewingCapsule(trans: trans)
                    }
                    
                    HStack {
                        if trans.isIdea {
                            Image(systemName: "brain.fill")
                                //.foregroundStyle(Color.brainPink)
                        }
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .disabled(!AppState.shared.user(is: trans.paidBy) && trans.status.enumID == .claimed)
            .if(transIsOpenByAnotherUser) {
                $0.listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        #if os(iOS)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        #endif
                        .strokeBorder(Color.theme, lineWidth: 2)
                        .clipShape(Rectangle())
                )
            }
        }
        
        var transIsOpenByAnotherUser: Bool {
            let result = OpenRecordManager.shared.openOrClosedRecords
                .filter { $0.active }
                .filter { $0.recordType.enumID == .eventTransaction && $0.recordID == trans.id && $0.user.isNotLoggedIn }
                .isEmpty == false
                        
            //if trans.id == "20" { print("-- \(#function) -- \(result)") }
            return result
            
        }
    }
    
        
    struct TransViewingCapsule: View {
        @Local(\.useWholeNumbers) var useWholeNumbers
        //@Local(\.colorTheme) var colorTheme
        
        @Environment(EventModel.self) private var eventModel
        var trans: CBEventTransaction
        
        var body: some View {
            HStack(spacing: 2) {
                Image(systemName: "eye")
                Text(transViewingUsers(trans.id) ?? "")
                
                specialMessageForLauraWhenCodyIsViewing
            }
            .padding(2)
            .padding(.horizontal, 4)
            .background(Color.theme, in: Capsule())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        
        func transViewingUsers(_ transID: String) -> String? {
            OpenRecordManager.shared.openOrClosedRecords
                .filter { $0.recordType.enumID == .eventTransaction && $0.recordID == trans.id && $0.user.isNotLoggedIn }
                .filter { $0.active }
                .map { $0.user.name }
                .uniqued()
                .joined(separator: ", ")
        }
        
        
        var specialMessageForLauraWhenCodyIsViewing: some View {
            Group {
                /// Special message for Laura for when I am viewing
                if (OpenRecordManager.shared.openOrClosedRecords
                    .filter ({ $0.recordType.enumID == .eventTransaction && $0.recordID == trans.id && $0.user.isNotLoggedIn })
                    .count == 1)
                    
                && (OpenRecordManager.shared.openOrClosedRecords
                    .filter ({ $0.recordType.enumID == .eventTransaction && $0.recordID == trans.id && $0.user.isNotLoggedIn })
                    .map { $0.user.id }
                    .contains(1))
            
                && AppState.shared.user!.id == 6
                {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.left")
                        Text("Muy Muy Chismoso")
                    }
                    .font(.caption2)
                }
            }
        }
    }
        
    
    
    
    // MARK: - Functions
    func viewTask() async {
        prepareData()
        event.deepCopy(.create)
        /// Just for formatting.
        event.amountString = event.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        eventModel.upsert(event)
        
        if event.startDate == nil { event.startDate = Date() }
        if event.endDate == nil { event.endDate = Date() }
        
        /// NOTE: Sorting must be done here and not in the computed property. If done in the computed property, when reording, they get all messed up.
        event.categories.sort { $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000 }
        event.items.sort { $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000 }
        
                    
        #if os(macOS)
        /// Focus on the title textfield.
        focusedField = 0
        #endif
        if event.action == .add {
            focusedField = 0
            Task {
                await eventModel.invitePersonViaEmail(event: event, email: AppState.shared.user!.email)
            }
        }
                
        setFileModelId()
        
        let recordType = XrefModel.getItem(from: .openRecords, byEnumID: .event)
        let mode = CBOpenOrClosedRecord(recordID: event.id, recordType: recordType, openOrClosed: .open)
        let _ = await OpenRecordManager.shared.markRecordAsOpenOrClosed(mode)
    }
        
    
    func setFileModelId() {
        FileModel.shared.fileParent = FileParent(id: event.id, type: XrefModel.getItem(from: .fileTypes, byEnumID: .event))
    }
    
    
    func prepareData() {
        chartData = ChartData()
        chartData.budget = event.amount ?? 0.0
        chartData.ideas = event.transactions.filter { $0.isNotPrivate && $0.isIdea }.map { $0.amount }.reduce(0.0, +)
        
        for part in event.participants.filter({ $0.active && $0.status == XrefModel.getItem(from: .eventInviteStatus, byEnumID: .accepted) }) {
            let expenses =
                event
                .transactions
                .filter { $0.active }
                //.filter { $0.paidBy?.is(part.user) }
                .filter { part.user.is($0.paidBy) }
                //.filter { $0.paidBy?.id == part.user.id }
                .filter { $0.isNotPrivate && $0.isNotIdea }
                .map { $0.amount }
                .reduce(0.0, +)
                
            chartData.userData.append(ChartUserData(user: part.user, contribution: part.groupAmount ?? 0.0, expenses: expenses))
        }
                
        personalChartData = PersonalChartData()
        personalChartData.contribution = event.participants.filter({ $0.user.isLoggedIn }).first!.personalAmount ?? 0.0
        personalChartData.ideas = event.transactions.filter { $0.active && $0.enteredBy.isLoggedIn && $0.isPrivate && $0.isIdea }.map { $0.amount }.reduce(0.0, +)
        personalChartData.expenses = event.transactions.filter { $0.active && $0.enteredBy.isLoggedIn && $0.isPrivate && $0.isNotIdea }.map { $0.amount }.reduce(0.0, +)
            
    }
    
    
    func validateParticipantsOnDimiss() {
        if event.action == .add && event.title.isEmpty {
            editID = nil
            dismiss()
        } else {
            if event.participants.filter({ $0.active }).isEmpty {
                AppState.shared.showAlert("At least 1 participant from your account is required.")
            } else {
                editID = nil
                dismiss()
            }
        }
    }
}
