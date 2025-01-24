//
//  EventsTable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/25.
//

import SwiftUI

struct EventsTable: View {
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
                    #if os(iOS)
                    .standardBackground()
                    #endif
            }
        }
        #if os(iOS)
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        #endif
        /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new event, and then trying to edit it.
        /// When I add a new event, and then update `model.events` with the new ID from the server, the table still contains an ID of 0 on the newly created event.
        /// Setting this id forces the view to refresh and update the relevant event with the new ID.
        .id(eventModel.fuckYouSwiftuiTableRefreshID)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
        .searchable(text: $searchText) {
            #if os(macOS)
            let relevantTitles: Array<String> = eventModel.events
                .compactMap { $0.event }
                .uniqued()
                .filter { $0.localizedStandardContains(searchText) }
                    
            ForEach(relevantTitles, id: \.self) { title in
                Text(title)
                    .searchCompletion(title)
            }
            #endif
        }
        
        .sheet(item: $editEvent, onDismiss: {
            eventEditID = nil
        }, content: { event in
            EventView(event: event, editID: $eventEditID)
                #if os(macOS)
                .frame(minWidth: 700)
                #endif
        })
        .sheet(isPresented: $showPendingInviteSheet) {
            EventPendingInviteView()
        }
        .onChange(of: sortOrder) { _, sortOrder in
            eventModel.events.sort(using: sortOrder)
        }
        .onChange(of: eventEditID) { oldValue, newValue in
            if let newValue {
                editEvent = eventModel.getEvent(by: newValue)
            } else {
                eventModel.saveEvent(id: oldValue!, calModel: calModel)
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
        
        .confirmationDialog("Leave event \(leaveEvent == nil ? "N/A" : leaveEvent!.title)?", isPresented: $showLeaveAlert, actions: {
            Button("Yes", role: .destructive) {
                if let leaveEvent = leaveEvent {
                    Task { await eventModel.leave(leaveEvent) }
                }
            }
            
            Button("No", role: .cancel) {
                leaveEvent = nil
                showLeaveAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Leave event \"\(leaveEvent == nil ? "N/A" : leaveEvent!.title)\"?")
            #endif
        })
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
            ToolbarCenterView()
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
            .customizationID("event")
            
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
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }
    #endif
    
    #if os(iOS)
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                NavigationManager.shared.navPath.removeLast()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                
                if !eventModel.invitations.isEmpty {
                    Button {
                        showPendingInviteSheet = true
                    } label: {
                        Image(systemName: "envelope.badge")
                            .foregroundStyle(.red)
                    }

                }
                
                ToolbarRefreshButton()
                Button {
                    eventEditID = UUID().uuidString
                } label: {
                    Image(systemName: "plus")
                }
                //.disabled(eventModel.isThinking)
            }
            
        }
    }
    
    var phoneList: some View {
        List(filteredEvents, selection: $eventEditID) { event in
            HStack(alignment: .center) {
                Text(event.title)
                Spacer()
            }
            .rowBackgroundWithSelection(id: event.id, selectedID: eventEditID)
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
                    Button {
                        leaveEvent = event
                        showLeaveAlert = true
                    } label: {
                        Label {
                            Text("Leave")
                        } icon: {
                            Image(systemName: "hand.raised.fill")
                        }
                    }
                    .tint(.orange)
                }
            }
            
        }
        .listStyle(.plain)
        .standardBackground()
    }
    #endif
}
