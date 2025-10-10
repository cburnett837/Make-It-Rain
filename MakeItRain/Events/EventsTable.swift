//
//  EventsTable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/25.
//

import SwiftUI

struct EventsTable: View {
    @Environment(\.dismiss) var dismiss
    @Local(\.colorTheme) var colorTheme
    #if os(macOS)
    @AppStorage("eventsTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBEvent>
    #endif
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(EventModel.self) private var eventModel
    
    @State private var searchText = ""
    
    @State private var leaveEvent: CBEvent?
    @State private var deleteEvent: CBEvent?
    @State private var editEvent: CBEvent?
    @State private var eventEditID: CBEvent.ID?
    
    @State private var sortOrder = [KeyPathComparator(\CBEvent.title)]
    
    @State private var showLeaveAlert = false
    @State private var showDeleteAlert = false
    @State private var showPendingInviteSheet = false
    @State private var labelWidth: CGFloat = 20.0
    
    @State private var newEventTitle = ""
    
    var filteredEvents: [CBEvent] {
        eventModel.events
            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedStandardContains(searchText) }
            //.sorted { $0.event.lowercased() < $1.event.lowercased() }
    }
    
    var body: some View {
        @Bindable var eventModel = eventModel
        
        Group {
            if !eventModel.events.isEmpty {
                Group {
                    #if os(macOS)
                    macTable
                    #else
                    phoneList
                    #endif
                }
            } else {
                ContentUnavailableView("No Events", systemImage: "beach.umbrella", description: Text("Click the plus button above to add a event."))
            }
        }
        //.loadingSpinner(id: .events, text: "Loading Events…")
        #if os(iOS)
        .navigationTitle("Events")
        //.navigationBarTitleDisplayMode(.inline)
        #endif
        /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new event, and then trying to edit it.
        /// When I add a new event, and then update `model.events` with the new ID from the server, the table still contains an ID of 0 on the newly created event.
        /// Setting this id forces the view to refresh and update the relevant event with the new ID.
        .id(eventModel.fuckYouSwiftuiTableRefreshID)
        //.navigationBarBackButtonHidden(true)
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
        
        .searchable(text: $searchText)
        .sheet(isPresented: $showPendingInviteSheet) {
            EventPendingInviteView()
        }
        .onChange(of: sortOrder) { _, sortOrder in
            eventModel.events.sort(using: sortOrder)
        }
        
        // MARK: - Event Sheet        
        .onChange(of: eventEditID) { oldValue, newValue in
            if let newValue {
                //editEvent = eventModel.getEvent(by: newValue)
                let editEvent = eventModel.getEvent(by: newValue)
                if editEvent.action == .add {
                    let alertConfig = AlertConfig(
                        title: "Create New Event",
                        subtitle: "Enter a title below to get started",
                        symbol: .init(name: "beach.umbrella", color: Color.fromName(colorTheme)),
                        primaryButton:
                            AlertConfig.AlertButton(closeOnFunction: false, showSpinnerOnClick: true, config: .init(text: "Create", role: .primary, function: {
                                Task {
                                    if newEventTitle.isEmpty {
                                        AppState.shared.showToast(title: "Title cannot be blank")
                                    } else {
                                        eventModel.events.append(editEvent)
                                        editEvent.title = newEventTitle
                                        editEvent.startDate = .now
                                        editEvent.endDate = .now
                                        let _ = await eventModel.invitePersonViaEmail(event: editEvent, email: AppState.shared.user!.email)
                                        let _ = await eventModel.submit(editEvent)
                                        newEventTitle = ""
                                        AppState.shared.closeAlert()
                                    }
                                }
                            })),
                        views: [
                            AlertConfig.ViewConfig(content: AnyView(textField))
                        ]
                    )
                    
                    AppState.shared.showAlert(config: alertConfig)
                    
                } else {
                    self.editEvent = editEvent
                }
                
            } else {
                /// If the event was being viewed when it was revoked, clear the revoked event object and don't save.
                if let oldValue {
                    if eventModel.revokedEvent?.id == oldValue {
                        eventModel.revokedEvent = nil
                    } else {
                        if !eventModel.saveEvent(id: oldValue, calModel: calModel) {
                            Task {
                                let recordType = XrefModel.getItem(from: .openRecords, byEnumID: .event)
                                let mode = CBOpenOrClosedRecord(recordID: oldValue, recordType: recordType, openOrClosed: .closed)
                                let _ = await OpenRecordManager.shared.markRecordAsOpenOrClosed(mode)
                                
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $editEvent, onDismiss: {
            eventEditID = nil
        }, content: { event in
            EventView(event: event, editID: $eventEditID)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        })
        
        /// If an event gets revoked while being viewed, close the page.
        .onChange(of: eventModel.revokedEvent) { oldValue, newValue in
            if let newValue {
                if editEvent?.id == newValue.id {
                    editEvent = nil
                }
            }
        }
        
        
        .confirmationDialog("Delete event \(deleteEvent == nil ? "N/A" : deleteEvent!.title)?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                if let deleteEvent = deleteEvent {
                    Task {
                        await eventModel.delete(deleteEvent, andSubmit: true)
                    }
                }
            }
            
            Button("No", role: .cancel) {
                deleteEvent = nil
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete event \"\(deleteEvent == nil ? "N/A" : deleteEvent!.title)\"?")
            #endif
        })
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
        
//        .confirmationDialog("Leave event \(leaveEvent == nil ? "N/A" : leaveEvent!.title)?", isPresented: $showLeaveAlert, actions: {
//            Button("Yes", role: .destructive) {
//                if let leaveEvent = leaveEvent {
//                    Task { await eventModel.leave(leaveEvent) }
//                }
//            }
//            
//            Button("No", role: .cancel) {
//                leaveEvent = nil
//                showLeaveAlert = false
//            }
//        }, message: {
//            #if os(iOS)
//            Text("Leave event \"\(leaveEvent == nil ? "N/A" : leaveEvent!.title)\"?")
//            #endif
//        })
        .sensoryFeedback(.warning, trigger: showLeaveAlert) { !$0 && $1 }
        
    }
    #if os(macOS)
    @ToolbarContentBuilder
    func macToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack {
                Button {
                    eventEditID = UUID().uuidString
                } label: {
                    Image(systemName: "plus")
                }
                .toolbarBorder()
                //.disabled(eventModel.isThinking)
                
                ToolbarNowButton()
                ToolbarRefreshButton()
                    .toolbarBorder()
            }
        }
        
        ToolbarItem(placement: .principal) {
            ToolbarCenterView(enumID: .events)
        }
        ToolbarItem {
            Spacer()
        }
    }
            
    var macTable: some View {
        Table(filteredEvents, selection: $eventEditID, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumn("Event", value: \.title) { event in
                Text(event.title)
            }
            
            TableColumn("Delete") { event in
                Button {
                    deleteEvent = event
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .width(min: 20, ideal: 30, max: 50)
        }
        .clipped()
    }
    #endif
    
    var textField: some View {
        TextField("Title", text: $newEventTitle)
            .multilineTextAlignment(.center)
    }
    
    #if os(iOS)
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !eventModel.invitations.isEmpty {
                Button {
                    showPendingInviteSheet = true
                } label: {
                    Image(systemName: "envelope.badge")
                        .foregroundStyle(.red)
                }
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) { ToolbarLongPollButton() }
        ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton() }
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                eventEditID = UUID().uuidString
            } label: {
                Image(systemName: "plus")
            }
            .tint(.none)
        }
    }
    
    var phoneList: some View {
        List(filteredEvents, selection: $eventEditID) { event in
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(event.title)
                    HStack {
                        let partCount = event.participants.filter { $0.status?.enumID == .accepted && $0.active }.count
                        if partCount > 1 {
                            Image(systemName: "person.2.fill")
                            Text("\(partCount)")
                        }
                        
                        //Text(event.id)
                    }
                    .foregroundStyle(.gray)
                    .font(.footnote)
                }
                
                Spacer()
                
                (
                Text(event.startDate?.string(to: .monthDayShortYear) ?? "N/A") +
                Text(" - ") +
                Text(event.endDate?.string(to: .monthDayShortYear) ?? "N/A")
                ).font(.footnote)
            }
            .swipeActions(allowsFullSwipe: false) {
                if(event.enteredBy.id == AppState.shared.user!.id) {
                    Button {
                        deleteEvent = event
                        showDeleteAlert = true
                    } label: {
                        Label {
                            Text("Delete")
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                    .tint(.red)
                } else {
//                    Button {
//                        leaveEvent = event
//                        showLeaveAlert = true
//                    } label: {
//                        Label {
//                            Text("Leave")
//                        } icon: {
//                            Image(systemName: "hand.raised.fill")
//                        }
//                    }
//                    .tint(.orange)
                }
            }
            
        }
        .listStyle(.plain)
    }
    #endif
}
