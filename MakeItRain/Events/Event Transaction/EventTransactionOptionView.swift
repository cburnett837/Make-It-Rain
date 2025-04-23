//
//  EventTransactionOptionView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/30/25.
//

import SwiftUI
import MapKit

struct EventTransactionOptionView: View {
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    
    @State private var mapModel = MapModel()
    @Environment(EventModel.self) private var eventModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    
    @Bindable var transOption: CBEventTransactionOption
    @Bindable var trans: CBEventTransaction
    
    @State private var showDeleteAlert = false
    @FocusState private var focusedField: Int?
    
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var position: MapCameraPosition = .userLocation(followsHeading: false, fallback: .userLocation(fallback: .automatic))
    
    let symbolWidth: CGFloat = 26
    
    var title: String { transOption.action == .add ? "New Option" : "Edit Option" }
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    var isOpenByAnotherUser: Bool {
        OpenRecordManager.shared.openOrClosedRecords
            .filter { $0.recordType.enumID == .eventTransactionOption }
            .filter { $0.recordID == transOption.id && $0.user.id != AppState.shared.user?.id }
            .filter { $0.active }
            .map { $0.recordID }
            .contains(transOption.id)
    }
    
    var otherViewingUsers: Array<CBUser> {
        OpenRecordManager.shared.openOrClosedRecords
            .filter { $0.recordType.enumID == .eventTransactionOption }
            .filter { $0.recordID == transOption.id && $0.user.id != AppState.shared.user?.id }
            .filter { $0.active }
            .map { $0.user }
            .uniqued(on: \.id)
    }
    
    var header: some View {
        SheetHeader(
            title: title,
            close: { dismiss() },
            view3: { deleteButton }
        )
    }
    
    var body: some View {
        StandardContainer() {
            StandardTitleTextField(symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 0, showSymbol: true, parentType: .eventTransactionOption, obj: transOption)
            StandardAmountTextField(symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 1, showSymbol: true, obj: transOption)
            StandardDivider()
               
            StandardUrlTextField(url: $transOption.url, symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 3, showSymbol: true)
            StandardDivider()
            
            HStack(alignment: .top) {
                Image(systemName: "map.fill")
                    .foregroundColor(.gray)
                    .frame(width: symbolWidth)
                                     
                StandardMiniMap(locations: $transOption.locations, parent: transOption, parentID: transOption.id, parentType: .eventTransactionOption, addCurrentLocation: false)
                .cornerRadius(8)
            }
            .padding(.bottom, 6)
            
            StandardPhotoSection(
                pictures: $transOption.pictures,
                photoUploadCompletedDelegate: eventModel,
                parentType: .eventTransactionOption,
                showCamera: $showCamera,
                showPhotosPicker: $showPhotosPicker
            )
            StandardDivider()
            
            StandardNoteTextEditor(notes: $transOption.notes, symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 4, showSymbol: true)
        } header: {
            header
        } footer: {
            currentlyViewingParticipants
        }
        
        .task { await viewTask() }
        .environment(mapModel)
        //.onChange(of: mapModel.position) { self.position = $1 }
        .confirmationDialog("Delete \"\(transOption.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                trans.deleteOption(id: transOption.id)
                dismiss()
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(trans.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
    }
    
    
    
    
    var currentlyViewingParticipants: some View {
        Group {
            if isOpenByAnotherUser {
                VStack(spacing: 2) {
                    HStack(alignment: .circleAndTitle, spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(spacing: 2) {
                            Text("This transaction is currently being viewed by another user.")
                            Text("Certain situations may cause data to be overwritten.")
                        }
                    }
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    
                    
                    Text("Currently Viewed By:")
                        .font(.caption2)
                                            
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(otherViewingUsers) { user in
                                Text(user.name)
                                    .bold()
                                    .font(.caption2)
                                    .foregroundStyle(Color.fromName(appColorTheme))
                            }
                        }
                    }
                    .defaultScrollAnchor(.center)
                }
            }
        }
    }
    
    
    func viewTask() async {
        if transOption.action == .add {
            trans.upsert(transOption)
        }
        
        if transOption.action == .add && transOption.title.isEmpty {
            focusedField = 0
        }
        
        setPhotoModelId()
        
        /// Copy it so we can compare for smart saving.
        transOption.deepCopy(.create)
        
        if transOption.action != .add {
            let recordType = XrefModel.getItem(from: .openRecords, byEnumID: .eventTransactionOption)
            let mode = CBOpenOrClosedRecord(recordID: transOption.id, recordType: recordType, openOrClosed: .open)
            let _ = await OpenRecordManager.shared.markRecordAsOpenOrClosed(mode)
        }
    }
    
    
    func setPhotoModelId() {
        PhotoModel.shared.pictureParent = PictureParent(id: transOption.id, type: XrefModel.getItem(from: .photoTypes, byEnumID: .eventTransactionOption))
    }
}
