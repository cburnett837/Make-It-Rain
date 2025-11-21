//
//  TransactionEditViewBackuo.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/21/25.
//

import Foundation
import SwiftUI
import PhotosUI
import SafariServices
import TipKit
import MapKit


fileprivate let photoWidth: CGFloat = 125
fileprivate let photoHeight: CGFloat = 200

//@Observable
//class LocationSearchCompleter: NSObject, MKLocalSearchCompleterDelegate {
//    private let completer = MKLocalSearchCompleter()
//    var completions: [MKLocalSearchCompletion] = []
//    
//    override init() {
//        super.init()
//        completer.resultTypes = .address
//        completer.delegate = self
//    }
//    
//    func getAutoCompletions(for text: String) {
//        completer.queryFragment = text
//        completer.resultTypes = MKLocalSearchCompleter.ResultType([.address, .pointOfInterest])
//    }
//    
//    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
//        completions = completer.results.filter{$0.subtitle.contains("United States")}
//    }
//    
//    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
//        print("Error: \(error.localizedDescription)")
//    }
//    
//    @MainActor func getMapItem(from localSearchCompletion: MKLocalSearchCompletion, parentID: String, parentType: XrefEnum) async -> CBLocation? {
//        completions.removeAll()
//        let request = MKLocalSearch.Request(completion: localSearchCompletion)
//        let search = MKLocalSearch(request: request)
//        
//        
//        let response = try? await search.start()
//        let mapItems = response?.mapItems ?? []
//        if mapItems.count > 0 {
//            let viewCord = CLLocationCoordinate2D(latitude: mapItems[0].placemark.coordinate.latitude/* - 0.004*/, longitude: mapItems[0].placemark.coordinate.longitude)
//            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//            let region = MKCoordinateRegion(center: viewCord, span: span)
//            
//            let location = CBLocation(relatedID: parentID, locationType: parentType, title: mapItems[0].name ?? "N/A", mapItem: mapItems[0])
//            return location
//        }
//        return nil
//    }
//    
//    
//    @MainActor func saveCurrentLocation(parentID: String, parentType: XrefEnum) async -> CBLocation? {
//        print("-- \(#function)")
//                
//        if let coordinate = LocationManager.shared.currentLocation {
//            do {
//                let geocoder = CLGeocoder()
//                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
//                let placemarks = try await geocoder.reverseGeocodeLocation(location)
//                if !placemarks.isEmpty {
//                    let mkPlaceMark = MKPlacemark(placemark: placemarks.first!)
//                    let item = MKMapItem(placemark: mkPlaceMark)
//                    let location = CBLocation(relatedID: parentID, locationType: parentType, title: item.name ?? "N/A", mapItem: item)
//                                    
//                    return location
//                } else {
//                    return nil
//                }
//            } catch {
//                print(error.localizedDescription)
//                return nil
//            }
//        } else {
//            return nil
//        }
//    }
//}



struct EventTransactionView: View {
    @Observable
    class ViewModel {
        var hoverPic: CBFile?
        var deletePic: CBFile?
        var isDeletingPic = false
        var showDeletePicAlert = false
    }
    
    //@State private var searchCompleter = LocationSearchCompleter()
    @State private var vm = ViewModel()
    
    @Local(\.lineItemIndicator) var lineItemIndicator
    //@Local(\.colorTheme) var colorTheme
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @State private var mapModel = MapModel()
    @Environment(EventModel.self) private var eventModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    
    @Bindable var trans: CBEventTransaction
    @Bindable var event: CBEvent
    var item: CBEventItem?
    
    @State private var showDeleteAlert = false
    @State private var showPayMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showPaymentMethodMissingAlert = false
    
    @State private var tranEditOption: CBEventTransactionOption?
    @State private var transOptionEditID: String?
    //@State private var transNewItem: CBEventTransactionOption?
    
    @State private var demoTest: String = "Hey there"
    @State private var safariUrl: URL?
    
    @FocusState private var focusedField: Int?
    
    @State private var showPromptForSelectOptionSheet = false
    
    //@State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    
    @State private var position: MapCameraPosition = .userLocation(followsHeading: false, fallback: .userLocation(fallback: .automatic))

    @State private var selectedTab: String = "details"
    @State private var showPhotosPicker = false
    @State private var showCamera = false
        
    //@State private var addPhotoButtonHoverColor: Color = .gray
    //@State private var addPhotoButtonHoverColor2: Color = Color(.tertiarySystemFill)
    
    let symbolWidth: CGFloat = 26
    
    var title: String { trans.action == .add ? "New Transaction" : "Edit Transaction" }
        
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    
    var paymentMethodMissing: Bool {
        trans.status == XrefModel.getItem(from: .eventTransactionStatuses, byEnumID: .claimed) && trans.payMethod == nil
    }
    
    var isOpenByAnotherUser: Bool {
        OpenRecordManager.shared.openOrClosedRecords
            .filter { $0.recordType.enumID == .eventTransaction }
            .filter { $0.recordID == trans.id && $0.user.id != AppState.shared.user?.id }
            .filter { $0.active }
            .map { $0.recordID }
            .contains(trans.id)
    }
    
    var otherViewingUsers: Array<CBUser> {
        OpenRecordManager.shared.openOrClosedRecords
            .filter { $0.recordType.enumID == .eventTransaction }
            .filter { $0.recordID == trans.id && $0.user.id != AppState.shared.user?.id }
            .filter { $0.active }
            .map { $0.user }
            .uniqued(on: \.id)
    }
    
    var transTypeLingo: String {
        trans.amountString.contains("-") ? "Expense" : "Income"
    }
    
    
    var header: some View {
        SheetHeader(
            title: title,
            close: {
                if paymentMethodMissing {
                    showPaymentMethodMissingAlert = true
                } else {
                    dismiss()
                }
            },
            view3: { deleteButton }
        )
    }
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            details
                .tabItem { Label("Details", systemImage: "list.bullet") }
                .tag("details")
                #if os(iOS)
                .toolbarBackground(.visible, for: .tabBar)
                #endif
            
            ideas
                .tabItem { Label("Ideas", systemImage: "brain") }
                .tag("ideas")
                #if os(iOS)
                .toolbarBackground(.visible, for: .tabBar)
                #endif
        }
        .interactiveDismissDisabled(paymentMethodMissing)
        .environment(vm)
        .environment(mapModel)
        .task { await viewTask() }
        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                event.deleteTransaction(id: trans.id)
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
        .onChange(of: trans.paidBy) { oldValue, newValue in
            if let newValue {
                if !AppState.shared.user(is: newValue) {
                    dismiss()
                }
            }
        }
        .alert("Account Missing", isPresented: $showPaymentMethodMissingAlert) {
            Button("OK") {}
        }
        
        
        // MARK: - Select Option Sheet
        .sheet(isPresented: $showPromptForSelectOptionSheet, onDismiss: {
            if trans.optionID == nil && !(trans.options ?? []).isEmpty {
                trans.isIdea = true
            }
        }) {
            ScrollView {
                optionPicker
            }
            .environment(mapModel)
        }
        .onChange(of: trans.isIdea) { oldValue, newValue in
            if !newValue {
                if !(trans.options ?? []).isEmpty {
                    showPromptForSelectOptionSheet = true
                }
                
            } else {
                trans.optionID = nil
                if !trans.originalTitle.isEmpty {
                    trans.title = trans.originalTitle
                }
                
            }
        }
        
        .onChange(of: mapModel.position) { self.position = $1 }
        
        // MARK: - Transaction Option Sheet
        .onChange(of: transOptionEditID) { oldValue, newValue in
            if let newValue {
                print("Creatintg iterm with \(newValue)")
                tranEditOption = trans.getOption(by: newValue)
            } else {
                let option = trans.getOption(by: oldValue!)
                
                if trans.saveOption(id: oldValue!) {
                    option.updatedDate = Date()
                    Task {
                        let _ = await eventModel.submit(option)
                    }
                } else {
                    print("❌Event trans option has no changes")
                    Task {
                        if option.action != .add {
                            print("Marking Trans option as closed for trans \(oldValue!)")
                            let recordType = XrefModel.getItem(from: .openRecords, byEnumID: .eventTransactionOption)
                            let mode = CBOpenOrClosedRecord(recordID: oldValue!, recordType: recordType, openOrClosed: .closed)
                            let _ = await OpenRecordManager.shared.markRecordAsOpenOrClosed(mode)
                        }
                    }
                }
            }
        }
        .sheet(item: $tranEditOption, onDismiss: {
            transOptionEditID = nil
        }, content: { option in
            EventTransactionOptionView(transOption: option, trans: trans)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        })
        
        #if os(iOS)
        .sheet(item: $safariUrl) { SFSafariView(url: $0) }
        #endif
    }
    
    
    var details: some View {
        StandardContainer {
            StandardTitleTextField(symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 0, showSymbol: true, parentType: .eventTransaction, showTitleSuggestions: .constant(false), obj: trans)

            
            if trans.isNotIdea {
                amountTextField
            }
            StandardDivider()
            
            itemMenu
            categoryMenu
            StandardDivider()
                        
            HStack(alignment: .circleAndTitle) {
                Image(systemName: "brain.fill")
                    .foregroundColor(.gray)
                    .frame(width: symbolWidth)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                VStack(alignment: .leading) {
                    Toggle(isOn: $trans.isIdea.animation()) {
                        Text("Just An Idea")
                    }
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    
                    Text("Determine if \(trans.title) is just an idea, or something that will actually happen and be paid for.")
                        .foregroundStyle(.gray)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
            }
            StandardDivider()
            
            HStack(alignment: .circleAndTitle) {
                Image(systemName: "eye.slash.fill")
                    .foregroundColor(.gray)
                    .frame(width: symbolWidth)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                VStack(alignment: .leading) {
                    Toggle(isOn: $trans.isPrivate) {
                        Text("Private Transaction")
                    }
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    
                    Text("If the transaction is private, it will be hidden from others in the group and only factor into your personal insights.")
                        .foregroundStyle(.gray)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
            }
            StandardDivider()
                                    
            if trans.isNotIdea {
                StandardUrlTextField(url: $trans.url, symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 3, showSymbol: true)
                StandardDivider()
                
                HStack(alignment: .top) {
                    Image(systemName: "map.fill")
                        .foregroundColor(.gray)
                        .frame(width: symbolWidth)
                                         
                    StandardMiniMap(locations: $trans.locations, parent: trans, parentID: trans.id, parentType: .eventTransaction, addCurrentLocation: trans.action == .add)
                        .environment(mapModel)
                        .cornerRadius(8)
                }
                .padding(.bottom, 6)
                
                StandardDivider()
                
                paymentMethodSection
                StandardDivider()
            }
            
            datePicker
            StandardDivider()
            
            if trans.isNotIdea {
                StandardFileSection(
                    files: $trans.files,
                    fileUploadCompletedDelegate: eventModel,
                    parentType: .eventTransaction,
                    showCamera: $showCamera,
                    showPhotosPicker: $showPhotosPicker
                )
                StandardDivider()
            }
            
            StandardNoteTextEditor(notes: $trans.notes, symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 4, showSymbol: true)
            StandardDivider()
                                                                                    
        } header: {
            header
        } footer: {
            currentlyViewingParticipants
        }
        
    }
    
    
    var ideas: some View {
        StandardContainer {
            optionSection
        } header: {
            header
        } footer: {
            currentlyViewingParticipants
        }
    }
    
    
    var titleTextField: some View {
        HStack(alignment: .circleAndTitle) {
            Image(systemName: "bag.fill")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack {
                Group {
                    #if os(iOS)
                    StandardUITextField("Title",
                        text: $trans.title,
                        onSubmit: { focusedField = 1 },
                        onClear: { mapModel.completions.removeAll() },
                        toolbar: { KeyboardToolbarView(focusedField: $focusedField) }
                    )
                    .cbClearButtonMode(.whileEditing)
                    .cbFocused(_focusedField, equals: 0)
                    .cbSubmitLabel(.next)
                    #else
                    StandardTextField("Title", text: $trans.title, focusedField: $focusedField, focusValue: 0)
                        .onSubmit { focusedField = 1 }
                    #endif
                }
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                
                if !mapModel.completions.isEmpty {
                    VStack(alignment: .leading) {
                        ForEach(mapModel.completions.prefix(3), id: \.self) { completion in
                            VStack(alignment: .leading) {
                                Text(AttributedString(completion.highlightedTitleStringForDisplay))
                                    .font(.caption2)
                                
                                Text(AttributedString(completion.highlightedSubtitleStringForDisplay))
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            .onTapGesture {
                                Task {
                                    if let location = await mapModel.getMapItem(from: completion, parentID: trans.id, parentType: .eventTransaction) {
                                        trans.upsert(location)
                                        mapModel.focusOnFirst(locations: trans.locations)
                                    }
                                }
                            }
                            
                            Divider()
                        }
                        
                        
                        HStack {
                            Button("Use Current Location") {
                                mapModel.completions.removeAll()
                                Task {
                                    if let location = await mapModel.saveCurrentLocation(parentID: trans.id, parentType: .eventTransaction) {
                                        trans.upsert(location)
                                    }
                                }
                            }
                            .bold(true)
                            .font(.caption)
                            
                            Button("Hide") {
                                mapModel.completions.removeAll()
                            }
                            .bold(true)
                            .font(.caption)
                        }
                        
                        Divider()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        /// Handle search suggestions
        .onChange(of: trans.title) { oldTerm, newTerm in
            mapModel.getAutoCompletions(for: newTerm)
        }
    }
    
    
    var amountTextField: some View {
        HStack(alignment: .circleAndTitle) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    #if os(iOS)
                    StandardUITextField("Amount", text: $trans.amountString, toolbar: {
                        KeyboardToolbarView(
                            focusedField: $focusedField,
                            accessoryImage3: "plus.forwardslash.minus",
                            accessoryFunc3: {
                                Helpers.plusMinus($trans.amountString)
                            })
                    })
                    .cbClearButtonMode(.whileEditing)
                    .cbFocused(_focusedField, equals: 1)
                    .cbKeyboardType(.custom(.numpad))
                    //.cbKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                    #else
                    StandardTextField("Amount", text: $trans.amountString, focusedField: $focusedField, focusValue: 1)
                    #endif
                }
                .formatCurrencyLiveAndOnUnFocus(
                    focusValue: 1,
                    focusedField: focusedField,
                    amountString: trans.amountString,
                    amountStringBinding: $trans.amountString,
                    amount: trans.amount
                )
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                (Text("Transaction Type: ") + Text(transTypeLingo).bold(true).foregroundStyle(Color.theme))
                    .foregroundStyle(.gray)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 6)
                    .disabled(trans.amountString.isEmpty)
                    .onTapGesture {
                        Helpers.plusMinus($trans.amountString)
                    }
            }
        }
    }
    
    
    var datePicker: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                        
            #if os(iOS)
            UIKitDatePicker(date: $trans.date, alignment: .leading) // Have to use because of reformatting issue
                .frame(height: 40)
            #else
            DatePicker("", selection: $trans.date ?? Date(), displayedComponents: [.date])
                .frame(maxWidth: .infinity, alignment: .leading)
                .labelsHidden()
            #endif
        }
    }
    
    
    var itemMenu: some View {
        HStack(alignment: .circleAndTitle) {
            Group {
                Image(systemName: "list.bullet.rectangle.portrait.fill")
                    .foregroundStyle(.gray)
            }
            .frame(width: symbolWidth)
            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack(alignment: .leading, spacing: 0) {
                EventItemSheetButton(item: $trans.item, trans: trans, event: event)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            }
        }
    }
    
    
    var categoryMenu: some View {
        HStack(alignment: .circleAndTitle) {
            Group {
                if lineItemIndicator == .dot {
                    Image(systemName: "books.vertical.fill")
                        .foregroundStyle((trans.category?.color ?? .gray).gradient)
                    
                } else if let emoji = trans.category?.emoji {
                    Image(systemName: emoji)
                        .foregroundStyle((trans.category?.color ?? .gray).gradient)
                    //Text(emoji)
                } else {
                    Image(systemName: "books.vertical.fill")
                        .foregroundStyle(.gray.gradient)
                }
            }
            .frame(width: symbolWidth)
            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack(alignment: .leading, spacing: 0) {
                EventCategorySheetButton(category: $trans.category, trans: trans, event: event)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            }
        }
    }
    
    
    var optionSection: some View {
        VStack(alignment: .leading) {
            if let options = trans.options {
                ForEach(options.filter { $0.active }, id: \.self) { option in
                    StandardRectangle {
                        ItemLineView(trans: trans, option: option, optionEditID: $transOptionEditID, doWhat: .open)
                    }
                }
            }
            
            Button("Add") {
                transOptionEditID = UUID().uuidString
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(.tertiarySystemFill))
            .foregroundStyle(Color.theme)
            .if((trans.options?.filter { $0.active }.count == 0) || trans.options == nil) {
                $0.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            }
        }
    }
    
    
    var optionPicker: some View {
        VStack(alignment: .leading) {
            if let options = trans.options {
                ForEach(0..<options.filter { $0.active }.count, id: \.self) { i in
                    let filtered = options.filter({ $0.active })
                    let option = filtered[i]
                    StandardRectangle {
                        ItemLineView(trans: trans, option: option, optionEditID: $transOptionEditID, doWhat: .assign)
                    }
                    .if(i == 0) {
                        $0.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    }
                }
            }
        }
    }
    
    
    var paymentMethodSection: some View {
        HStack(alignment: .circleAndTitle) {
            Image(systemName: "banknote.fill")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
        
                     
            VStack(alignment: .leading, spacing: 6) {
                if trans.status.enumID == .claimed {
                    //PayMethodSheetButtonMac(payMethod: $trans.payMethod, whichPaymentMethods: .allExceptUnified)
                        //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                }
                
                claimButton
                    .if(trans.status.enumID != .claimed) {
                        $0.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    }
            }
        }
        .padding(.bottom, 6)
    }
    

    var claimButton: some View {
        Button(trans.status.enumID == .claimed ? "Put up for grabs" : "Claim transaction") {
            if trans.status.enumID == .claimed {
                withAnimation {
                    trans.paidBy = nil
                    trans.payMethod = nil
                    trans.status = XrefModel.getItem(from: .eventTransactionStatuses, byEnumID: .pending)
                    trans.isBeingClaimed = false
                    trans.isBeingUnClaimed = true
                }
            } else {
                withAnimation {
                    trans.paidBy = AppState.shared.user!
                    trans.status = XrefModel.getItem(from: .eventTransactionStatuses, byEnumID: .claimed)
                    trans.isBeingClaimed = true
                    trans.isBeingUnClaimed = false
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(.tertiarySystemFill))
        .foregroundStyle(Color.theme)
    }
    
    
    var paymentMethodMenu: some View {
        HStack {
            Text("Account")
            Spacer()
            Button((trans.payMethod == nil ? "Select" : trans.payMethod?.title) ?? "Select") {
                showPayMethodSheet = true
            }
        }
        .sheet(isPresented: $showPayMethodSheet) {
            PayMethodSheet(payMethod: $trans.payMethod, whichPaymentMethods: .allExceptUnified)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
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
                                    .foregroundStyle(Color.theme)
                            }
                        }
                    }
                    .defaultScrollAnchor(.center)
                }
            }
        }
    }
    
    
//    var currentlyViewingParticipants: some View {
//        Group {
//            if !eventModel.openEventTransactions.isEmpty {
//                if eventModel.openEventTransactions.map({$0.transactionID}).contains(trans.id) {
//                    if !eventModel.openEventTransactions.filter({$0.transactionID == trans.id && $0.user.id != AppState.shared.user?.id}).isEmpty {
//                        HStack {
//                            Text("Currently Viewed By:")
//                                .font(.caption2)
//                                                    
//                            //ScrollView(.horizontal) {
//                                HStack {
//                                    ForEach(eventModel.openEventTransactions.filter{$0.transactionID == trans.id && $0.user.id != AppState.shared.user?.id}, id: \.id) { openTrans in
//                                        Text(openTrans.user.name)
//                                            .font(.caption2)
//                                            .foregroundStyle(.green)
//                                    }
//                                }
//                            //}
//                        }
//                        
//                    }
//                }
//            }
//        }
//    }
    
    enum DoWhatWhenTouchingOption {
        case open, assign
    }
    
    struct ItemLineView: View {
        @Local(\.useWholeNumbers) var useWholeNumbers
        //@Local(\.colorTheme) var colorTheme
        @Environment(\.dismiss) private var dismiss
        @Environment(EventModel.self) private var eventModel
        @Environment(MapModel.self) private var mapModel
        
        @Bindable var trans: CBEventTransaction
        @Bindable var option: CBEventTransactionOption
        @Binding var optionEditID: String?
        var doWhat: DoWhatWhenTouchingOption
        
        var body: some View {
            Button {
                switch doWhat {
                case .open:
                    optionEditID = option.id
                case .assign:
                    print("Assign")
                    
                    let filteredLocations = option.locations.filter { $0.active }
                    
                    mapModel.blockCompletion = true
                    if let lat = filteredLocations.first?.lat, let lon = filteredLocations.first?.lon {
                        let viewCord = CLLocationCoordinate2D(latitude: CLLocationDegrees(floatLiteral: lat), longitude: CLLocationDegrees(floatLiteral: lon))
                        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        let region = MKCoordinateRegion(center: viewCord, span: span)
                        mapModel.position = .region(region)
                        mapModel.visibleRegion = region
                    }
                    trans.setFromOptionInstance(option: option)
                    dismiss()
                    
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    if(transIsOpenByAnotherUser(option.id)) {
                        ItemViewingCapsule(option: option)
                    }
                    
                    StandardMiniMapContainerWithStatePosition(locations: $option.locations, parent: option, parentID: option.id, parentType: .eventTransactionOption, addCurrentLocation: false, openBigMapOnTap: false)
                        .cornerRadius(8)
                        .padding(.top, 6)
                        .padding(8)
                        //.padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.title)
                            .font(.title3)
                        Text(option.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        if trans.optionID == option.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.leading, 8)
                    
                    Divider()
                    
                    
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .if(transIsOpenByAnotherUser(option.id)) {
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
        
        func transIsOpenByAnotherUser(_ transID: String) -> Bool {
            OpenRecordManager.shared.openOrClosedRecords
                .filter { $0.recordType.enumID == .eventTransactionOption && $0.recordID == transID && $0.user.id != AppState.shared.user?.id }
                .filter { $0.active }
                .map { $0.recordID }
                .contains(transID)
        }
    }
    
    
    struct ItemViewingCapsule: View {
        @Local(\.useWholeNumbers) var useWholeNumbers
        //@Local(\.colorTheme) var colorTheme
        
        @Environment(EventModel.self) private var eventModel
        var option: CBEventTransactionOption
        
        var body: some View {
            HStack(spacing: 2) {
                Image(systemName: "eye")
                Text(transViewingUsers(option.id) ?? "")
                
                specialMessageForLauraWhenCodyIsViewing
            }
            .padding(2)
            .padding(.horizontal, 4)
            .background(Color.theme, in: Capsule())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        func transViewingUsers(_ transID: String) -> String? {
            OpenRecordManager.shared.openOrClosedRecords
                .filter { $0.recordType.enumID == .eventTransactionOption && $0.recordID == option.id && $0.user.id != AppState.shared.user?.id }
                .filter { $0.active }
                .map { $0.user.name }
                .uniqued()
                .joined(separator: ", ")
        }
        
        
        var specialMessageForLauraWhenCodyIsViewing: some View {
            Group {
                /// Special message for Laura for when I am viewing
                if (OpenRecordManager.shared.openOrClosedRecords
                    .filter ({ $0.recordType.enumID == .eventTransactionOption && $0.recordID == option.id && $0.user.id != AppState.shared.user?.id })
                    .count == 1)
                    
                && (OpenRecordManager.shared.openOrClosedRecords
                    .filter ({ $0.recordType.enumID == .eventTransactionOption && $0.recordID == option.id && $0.user.id != AppState.shared.user?.id })
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
    

   
    func viewTask() async {
        
//        for loc in trans.locations {
//            Task {
//                loc.mapItem = await mapModel.createMapItemFrom(coordinates: loc.coordinates)
//            }
//        }
//        
//        
        
        
        trans.isBeingClaimed = false
        trans.isBeingUnClaimed = false
        
        if trans.date == nil {
            trans.date = Date()
        }
        
        if item != nil {
            trans.item = item
        }
        event.upsert(trans)
        
        if trans.action == .add && trans.title.isEmpty {
            focusedField = 0
        }
        
        /// Copy it so we can compare for smart saving.
        trans.deepCopy(.create)
        
        FileModel.shared.fileParent = FileParent(id: trans.id, type: XrefModel.getItem(from: .fileTypes, byEnumID: .eventTransaction))
        
        if trans.action != .add {
            let recordType = XrefModel.getItem(from: .openRecords, byEnumID: .eventTransaction)
            let mode = CBOpenOrClosedRecord(recordID: trans.id, recordType: recordType, openOrClosed: .open)
            let _ = await OpenRecordManager.shared.markRecordAsOpenOrClosed(mode)
        }
    }
    
}

//
//
//
//
//struct EventTransactionViewOG: View {
//    @Local(\.lineItemIndicator) var lineItemIndicator
//    //@Local(\.colorTheme) var colorTheme
//    @Local(\.useWholeNumbers) var useWholeNumbers
//    
//    @Environment(EventModel.self) private var eventModel
//    @Environment(\.scenePhase) var scenePhase
//    @Environment(\.dismiss) var dismiss
//    
//    @Bindable var trans: CBEventTransaction
//    @Bindable var event: CBEvent
//    var item: CBEventItem?
//    
//    @State private var showDeleteAlert = false
//    @State private var showPayMethodSheet = false
//    @State private var showCategorySheet = false
//    @State private var showPaymentMethodMissingAlert = false
//    
//    @State private var tranEditOption: CBEventTransactionOption?
//    @State private var transOptionEditID: String?
//    //@State private var transNewItem: CBEventTransactionOption?
//    
//    @State private var demoTest: String = "Hey there"
//    
//    @FocusState private var focusedField: Int?
//    
//    var title: String { trans.action == .add ? "New Transaction" : "Edit Transaction" }
//        
//    var deleteButton: some View {
//        Button {
//            showDeleteAlert = true
//        } label: {
//            Image(systemName: "trash")
//        }
//        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
//    }
//    
//    
//    var paymentMethodMissing: Bool {
//        trans.status == XrefModel.getItem(from: .eventTransactionStatuses, byEnumID: .claimed) && trans.payMethod == nil
//    }
//    
//    var isOpenByAnotherUser: Bool {
//        OpenRecordManager.shared.openOrClosedRecords
//            .filter { $0.recordType.enumID == .eventTransaction }
//            .filter { $0.recordID == trans.id && $0.user.id != AppState.shared.user?.id }
//            .filter { $0.active }
//            .map { $0.recordID }
//            .contains(trans.id)
//    }
//    
//    var otherViewingUsers: Array<CBUser> {
//        OpenRecordManager.shared.openOrClosedRecords
//            .filter { $0.recordType.enumID == .eventTransaction }
//            .filter { $0.recordID == trans.id && $0.user.id != AppState.shared.user?.id }
//            .filter { $0.active }
//            .map { $0.user }
//            .uniqued(on: \.id)
//    }
//    
//    var transTypeLingo: String {
//        trans.amountString.contains("-") ? "Expense" : "Income"
//    }
//    
//    
//    var header: some View {
//        SheetHeader(
//            title: title,
//            close: {
//                if paymentMethodMissing {
//                    showPaymentMethodMissingAlert = true
//                } else {
//                    dismiss()
//                }
//            },
//            view3: { deleteButton }
//        )
//    }
//    
//    
//    var body: some View {
//        SheetContainerView(.list) {
//            Section {
//                titleTextField
//                amountTextField
//                datePicker
//            } header: {
//                Text("Details")
//            } footer: {
//                HStack {
//                    Spacer()
//                    (Text("Transaction Type: ") + Text(transTypeLingo).bold(true).foregroundStyle(Color.theme))
//                        .foregroundStyle(.gray)
//                        .font(.caption)
//                        .disabled(trans.amountString.isEmpty)
//                        .onTapGesture { Helpers.plusMinus($trans.amountString) }
//                }
//            }
//            
//            Section("Section / Category") {
//                itemPicker
//                categoryPicker
//            }
//            
//            Section("Items") {
//                if let options = trans.options {
//                    ForEach(options.filter { $0.active }) { item in
//                        ItemLineView(item: item, itemEditID: $transOptionEditID)
//                    }
//                }
//                
//                Button("Add") {
//                    transOptionEditID = UUID().uuidString
//                }
//            }
//            
//            Section {
//                claimButton
//                
//                if trans.status.enumID == .claimed {
//                    paymentMethodMenu
//                }
//            } header: {
//                Text("Payment")
//            } footer: {
//                if let paidBy = trans.paidBy {
//                    Text("Paid by \(paidBy.name)")
//                }
//            }
//            
////            Section("Date") {
////                datePicker
////            }
//            
//            Section("URL") {
//                urlTextField
//                #if os(iOS)
//                if let url = URL(string: trans.url) {
//                    LinkItemView(url: url)
////                    LinkPreviewView(previewURL: url)
////                        .aspectRatio(contentMode: .fit)
//                }
//                #endif
//            }
//            
//            Section("Notes") {
//                notes
//            }
//        } header: {
//            header
//        } footer: {
//            currentlyViewingParticipants
//        }
//        .interactiveDismissDisabled(paymentMethodMissing)
//        .task {
//            trans.isBeingClaimed = false
//            trans.isBeingUnClaimed = false
//            
//            if trans.date == nil {
//                trans.date = Date()
//            }
//            
//            if item != nil {
//                trans.item = item
//            }
//            event.upsert(trans)
//            
//            if trans.action == .add && trans.title.isEmpty {
//                focusedField = 0
//            }
//            
//            /// Copy it so we can compare for smart saving.
//            trans.deepCopy(.create)
//            
//            FileModel.shared.fileParent = PictureParent(id: trans.id, type: XrefModel.getItem(from: .fileTypes, byEnumID: .eventTransaction))
//            
//            if trans.action != .add {
//                let recordType = XrefModel.getItem(from: .openRecords, byEnumID: .eventTransaction)
//                let mode = CBOpenOrClosedRecord(recordID: trans.id, recordType: recordType, openOrClosed: .open)
//                let _ = await OpenRecordManager.shared.markRecordAsOpenOrClosed(mode)
//            }
//            
//            
//        }
//        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert, actions: {
//            Button("Yes", role: .destructive) {
//                event.deleteTransaction(id: trans.id)
//                dismiss()
//            }
//            
//            Button("No", role: .cancel) {
//                showDeleteAlert = false
//            }
//        }, message: {
//            #if os(iOS)
//            Text("Delete \"\(trans.title)\"?\nThis will not delete any associated transactions.")
//            #else
//            Text("This will not delete any associated transactions.")
//            #endif
//        })
//        .onChange(of: trans.paidBy) { oldValue, newValue in
//            if let newValue {
//                if !AppState.shared.user(is: newValue) {
//                    dismiss()
//                }
//            }
//        }
//        .alert("Payment Method Missing", isPresented: $showPaymentMethodMissingAlert) {
//            Button("OK") {}
//        }
//        
//        
//        
//        // MARK: - Transaction Item Sheet
//        .onChange(of: transOptionEditID) { oldValue, newValue in
//            if let newValue {
//                print("Creatintg iterm with \(newValue)")
//                tranEditOption = trans.getItem(by: newValue)
//            } else {
//                let item = trans.getItem(by: oldValue!)
//                
//                if trans.saveItem(id: oldValue!) && item.hasChanges() {
//                    item.updatedDate = Date()
//                    Task {
//                        let _ = await eventModel.submit(item)
//                    }
//                } else {
//                    print("❌Event trans item has no changes")
//                    Task {
//                        if item.action != .add {
//                            print("Marking Trans item as closed for trans \(oldValue!)")
//                            let recordType = XrefModel.getItem(from: .openRecords, byEnumID: .eventTransactionOption)
//                            let mode = CBOpenOrClosedRecord(recordID: oldValue!, recordType: recordType, openOrClosed: .closed)
//                            let _ = await OpenRecordManager.shared.markRecordAsOpenOrClosed(mode)
//                        }
//                    }
//                }
//            }
//        }
//        .sheet(item: $tranEditOption, onDismiss: {
//            transOptionEditID = nil
//        }, content: { item in
//            EventTransactionOptionView(transItem: item, trans: trans)
//            #if os(macOS)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//            #endif
//        })
//        
//        
//        // MARK: - Handling Lifecycles (iPhone)
//        #if os(iOS)
////        .onChange(of: scenePhase) { oldPhrase, newPhase in
////            if newPhase == .inactive {
////                print("scenePhase: event trans Inactive")
////
////            } else if newPhase == .active {
////                print("scenePhase: event trans Active")
////                Task {
////                    let mode = CBEventViewMode(transactionID: trans.id, eventID: event.id, mode: .open)
////                    let _ = await eventModel.markEventTransaction(viewMode: mode)
////                }
////
////            } else if newPhase == .background {
////                print("scenePhase: event trans Background")
////                Task {
////                    let mode = CBEventViewMode(transactionID: trans.id, eventID: event.id, mode: .close)
////                    let _ = await eventModel.markEventTransaction(viewMode: mode)
////                }
////            }
////        }
//        #endif
//    }
//    
//    
//    var titleTextField: some View {
//        HStack {
//            HStack(spacing: 20) {
//                Image(systemName: "pencil.circle.fill")
//                    .frame(width: 30, height: 30)
//                    .background(.blue, in: .rect(cornerRadius: 7))
//                Text("Title")
//            }
//            
//            Spacer()
//            #if os(iOS)
//            UITextFieldWrapper(placeholder: "Transaction Title", text: $trans.title, toolbar: {
//                KeyboardToolbarView(focusedField: $focusedField)
//            })
//            .uiTag(0)
//            .uiTextAlignment(.right)
//            .uiClearButtonMode(.whileEditing)
//            .uiStartCursorAtEnd(true)
//            #else
//            TextField("Transaction Title", text: $trans.title)
//                .multilineTextAlignment(.trailing)
//            #endif
//        }
//        .focused($focusedField, equals: 0)
//    }
//    
//    
//    var amountTextField: some View {
//        HStack {
//            HStack(spacing: 20) {
//                Image(systemName: "creditcard.fill")
//                    .frame(width: 30, height: 30)
//                    .background(.green, in: .rect(cornerRadius: 7))
//                Text("Amount")
//            }
//            Spacer()
//            
//            Group {
//                #if os(iOS)
//                UITextFieldWrapper(placeholder: "Total", text: $trans.amountString, toolbar: {
//                    KeyboardToolbarView(
//                        focusedField: $focusedField,
//                        accessoryImage3: "plus.forwardslash.minus",
//                        accessoryFunc3: {
//                            Helpers.plusMinus($trans.amountString)
//                        })
//                })
//                .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
//                .uiTag(1)
//                .uiTextAlignment(.right)
//                .uiClearButtonMode(.whileEditing)
//                .uiStartCursorAtEnd(true)
//                #else
//                TextField("Total", text: $trans.amountString)
//                    .multilineTextAlignment(.trailing)
//                #endif
//            }
//            .focused($focusedField, equals: 1)
//            .formatCurrencyLiveAndOnUnFocus(
//                focusValue: 1,
//                focusedField: focusedField,
//                amountString: trans.amountString,
//                amountStringBinding: $trans.amountString,
//                amount: trans.amount
//            )
//        }
//    }
//    
//    
//    var datePicker: some View {
//        HStack {
//            HStack(spacing: 20) {
//                Image(systemName: "calendar")
//                    .frame(width: 30, height: 30)
//                    .background(.red, in: .rect(cornerRadius: 7))
//                Text("Date")
//            }
//            Spacer()
//            #if os(iOS)
//            UIKitDatePicker(date: $trans.date, alignment: .trailing) // Have to use because of reformatting issue
//            #else
//            DatePicker("", selection: $trans.date ?? Date(), displayedComponents: [.date])
//                .labelsHidden()
//            #endif
//        }
//    }
//    
//    
//    var itemPicker: some View {
//        HStack {
//            HStack(spacing: 20) {
//                Image(systemName: "list.bullet.clipboard.fill")
//                    .frame(width: 30, height: 30)
//                    .background(.blue, in: .rect(cornerRadius: 7))
//                Text("Item")
//            }
//            Spacer()
//                        
//            Menu(trans.item?.title ?? "None") {
//                Section {
//                    Button("None") {
//                        trans.item = nil
//                    }
//                }
//                Section {
//                    ForEach(event.items.filter { $0.active }) { item in
//                        Button {
//                            trans.item = item
//                        } label: {
//                            Text(item.title)
//                        }
//                    }
//                }
//            }
//            
//            
//            
////            Picker(selection: $trans.item) {
////                Section {
////                    Text("None")
////                        .tag(nil as CBEventItem?)
////                }
////                Section {
////                    ForEach(event.items.filter { $0.active }) { item in
////                        Text(item.title)
////                            .tag(item as CBEventItem?)
////                    }
////                }
////            } label: {
////                Text(trans.item?.title ?? "Select Item")
////            }
////            .labelsHidden()
////            .pickerStyle(.menu)
//        }
//    }
//    
//    
//    var categoryPicker: some View {
//        HStack {
//            HStack(spacing: 20) {
//                Image(systemName: "carrot.fill")
//                    .frame(width: 30, height: 30)
//                    .background(.orange, in: .rect(cornerRadius: 7))
//                Text("Category")
//            }
//            Spacer()
//            
//            Menu(trans.category?.title ?? "None") {
//                Section {
//                    Button("None") {
//                        trans.category = nil
//                    }
//                }
//                Section {
//                    ForEach(event.categories.filter { $0.active }) { cat in
//                        Button {
//                            trans.category = cat
//                        } label: {
//                            if lineItemIndicator == .dot {
//                                HStack {
//                                    Text(cat.title)
//                                    Image(systemName: "circle.fill")
//                                        .foregroundStyle(cat.color, cat.color, cat.color)
//                                }
//                            } else {
//                                if let emoji = cat.emoji {
//                                    HStack {
//                                        Text(cat.title)
//                                        Image(systemName: emoji)
//                                            .foregroundStyle(cat.color, cat.color, cat.color)
//                                    }
//                                } else {
//                                    Text(cat.title)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            
////            Picker(selection: $trans.category) {
////                Section {
////                    Text("None")
////                        .tag(nil as CBEventCategory?)
////                }
////                Section {
////                    ForEach(event.categories.filter { $0.active }) { cat in
////                        Text(cat.title)
////                            .tag(cat as CBEventCategory?)
////                    }
////                }
////            } label: {
////                Text(trans.category?.title ?? "Select Item")
////            }
////            .labelsHidden()
////            .pickerStyle(.menu)
//        }
//    }
//    
//    
//    var claimButton: some View {
//        Button(trans.status.enumID == .claimed ? "Put up for grabs" : "Claim transaction") {
//            if trans.status.enumID == .claimed {
//                trans.paidBy = nil
//                trans.payMethod = nil
//                trans.status = XrefModel.getItem(from: .eventTransactionStatuses, byEnumID: .pending)
//                trans.isBeingClaimed = false
//                trans.isBeingUnClaimed = true
//            } else {
//                withAnimation {
//                    trans.paidBy = AppState.shared.user!
//                    trans.status = XrefModel.getItem(from: .eventTransactionStatuses, byEnumID: .claimed)
//                    trans.isBeingClaimed = true
//                    trans.isBeingUnClaimed = false
//                }
//            }
//        }
//    }
//    
//    
//    var paymentMethodMenu: some View {
//        HStack {
//            Text("Payment Method")
//            Spacer()
//            Button((trans.payMethod == nil ? "Select" : trans.payMethod?.title) ?? "Select") {
//                showPayMethodSheet = true
//            }
//        }
//        .sheet(isPresented: $showPayMethodSheet) {
//            PayMethodSheet(payMethod: $trans.payMethod, whichPaymentMethods: .allExceptUnified)
//            #if os(macOS)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//            #endif
//        }
//    }
//    
//    
//    var notes: some View {
//        TextEditor(text: $trans.notes)
//            .foregroundStyle(trans.notes.isEmpty ? .gray : .primary)
//            .scrollContentBackground(.hidden)
//            .background(.clear)
//            .frame(minHeight: 100)
//            .focused($focusedField, equals: 2)
//    }
//    
//    
//    var urlTextField: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                #if os(iOS)
//                UITextFieldWrapper(placeholder: "URL", text: $trans.url, onSubmit: {
//                    focusedField = nil
//                }, toolbar: {
//                    KeyboardToolbarView(focusedField: $focusedField)
//                })
//                .uiClearButtonMode(.whileEditing)
//                .uiTag(4)
//                .uiAutoCorrectionDisabled(true)
//                .uiKeyboardType(.URL)
//                #else
//                StandardTextField("URL", text: $trans.url, focusedField: $focusedField, focusValue: 4)
//                    .autocorrectionDisabled(true)
//                    .onSubmit { focusedField = nil }
//                #endif
//                
//                #if os(macOS)
//                if let url = URL(string: trans.url) {
//                    Link(destination: url) {
//                        Image(systemName: "safari")
//                    }
//                    .buttonStyle(.borderedProminent)
//                }
//                #endif
//            }
//            .focused($focusedField, equals: 4)
//        }
//    }
//    
//    var currentlyViewingParticipants: some View {
//        Group {
//            if isOpenByAnotherUser {
//                VStack(spacing: 2) {
//                    HStack(alignment: .circleAndTitle, spacing: 2) {
//                        Image(systemName: "exclamationmark.triangle.fill")
//                            .foregroundStyle(.orange)
//                        VStack(spacing: 2) {
//                            Text("This transaction is currently being viewed by another user.")
//                            Text("Certain situations may cause data to be overwritten.")
//                        }
//                    }
//                    .font(.caption2)
//                    .multilineTextAlignment(.center)
//                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                    
//                    
//                    Text("Currently Viewed By:")
//                        .font(.caption2)
//                                            
//                    ScrollView(.horizontal) {
//                        HStack {
//                            ForEach(otherViewingUsers) { user in
//                                Text(user.name)
//                                    .bold()
//                                    .font(.caption2)
//                                    .foregroundStyle(Color.theme)
//                            }
//                        }
//                    }
//                    .defaultScrollAnchor(.center)
//                }
//            }
//        }
//    }
//    
//    
////    var currentlyViewingParticipants: some View {
////        Group {
////            if !eventModel.openEventTransactions.isEmpty {
////                if eventModel.openEventTransactions.map({$0.transactionID}).contains(trans.id) {
////                    if !eventModel.openEventTransactions.filter({$0.transactionID == trans.id && $0.user.id != AppState.shared.user?.id}).isEmpty {
////                        HStack {
////                            Text("Currently Viewed By:")
////                                .font(.caption2)
////
////                            //ScrollView(.horizontal) {
////                                HStack {
////                                    ForEach(eventModel.openEventTransactions.filter{$0.transactionID == trans.id && $0.user.id != AppState.shared.user?.id}, id: \.id) { openTrans in
////                                        Text(openTrans.user.name)
////                                            .font(.caption2)
////                                            .foregroundStyle(.green)
////                                    }
////                                }
////                            //}
////                        }
////
////                    }
////                }
////            }
////        }
////    }
//    
//    
//    
//    struct ItemLineView: View {
//        @Local(\.useWholeNumbers) var useWholeNumbers
//        //@Local(\.colorTheme) var colorTheme
//        @Environment(EventModel.self) private var eventModel
//        
//        @Bindable var item: CBEventTransactionOption
//        @Binding var itemEditID: String?
//        
//        var body: some View {
//            Button {
//                itemEditID = item.id
//            } label: {
//                VStack(alignment: .leading, spacing: 2) {
//                    if(transIsOpenByAnotherUser(item.id)) {
//                        ItemViewingCapsule(item: item)
//                    }
//                    
//                    HStack {
//                        Text(item.title)
//                        Spacer()
//                        Text(item.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                    }
//                }
//                .contentShape(Rectangle())
//            }
//            .buttonStyle(.plain)
//            .foregroundStyle(.primary)
//            .if(transIsOpenByAnotherUser(item.id)) {
//                $0.listRowBackground(
//                    RoundedRectangle(cornerRadius: 10)
//                        #if os(iOS)
//                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
//                        #endif
//                        .strokeBorder(Color.theme, lineWidth: 2)
//                        .clipShape(Rectangle())
//                )
//            }
//        }
//        
//        func transIsOpenByAnotherUser(_ transID: String) -> Bool {
//            OpenRecordManager.shared.openOrClosedRecords
//                .filter { $0.recordType.enumID == .eventTransactionOption && $0.recordID == transID && $0.user.id != AppState.shared.user?.id }
//                .filter { $0.active }
//                .map { $0.recordID }
//                .contains(transID)
//        }
//    }
//    
//    
//    struct ItemViewingCapsule: View {
//        @Local(\.useWholeNumbers) var useWholeNumbers
//        //@Local(\.colorTheme) var colorTheme
//        
//        @Environment(EventModel.self) private var eventModel
//        var item: CBEventTransactionOption
//        
//        var body: some View {
//            HStack(spacing: 2) {
//                Image(systemName: "eye")
//                Text(transViewingUsers(item.id) ?? "")
//                
//                specialMessageForLauraWhenCodyIsViewing
//            }
//            .padding(2)
//            .padding(.horizontal, 4)
//            .background(Color.theme, in: Capsule())
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        
//        func transViewingUsers(_ transID: String) -> String? {
//            OpenRecordManager.shared.openOrClosedRecords
//                .filter { $0.recordType.enumID == .eventTransactionOption && $0.recordID == item.id && $0.user.id != AppState.shared.user?.id }
//                .filter { $0.active }
//                .map { $0.user.name }
//                .uniqued()
//                .joined(separator: ", ")
//        }
//        
//        
//        var specialMessageForLauraWhenCodyIsViewing: some View {
//            Group {
//                /// Special message for Laura for when I am viewing
//                if (OpenRecordManager.shared.openOrClosedRecords
//                    .filter ({ $0.recordType.enumID == .eventTransactionOption && $0.recordID == item.id && $0.user.id != AppState.shared.user?.id })
//                    .count == 1)
//                    
//                && (OpenRecordManager.shared.openOrClosedRecords
//                    .filter ({ $0.recordType.enumID == .eventTransactionOption && $0.recordID == item.id && $0.user.id != AppState.shared.user?.id })
//                    .map { $0.user.id }
//                    .contains(1))
//            
//                && AppState.shared.user!.id == 6
//                {
//                    HStack(spacing: 2) {
//                        Image(systemName: "arrow.left")
//                        Text("Muy Muy Chismoso")
//                    }
//                    .font(.caption2)
//                }
//            }
//        }
//    }
//    
//}
