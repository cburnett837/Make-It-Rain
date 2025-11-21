//
//  Settings.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import SwiftUI
import LocalAuthentication
import TipKit
import PhotosUI


@Observable class SettingsModel: CanHandleLogo, FileUploadCompletedDelegate {
    var id: String = UUID().uuidString
    var logo: Data? = nil
    var color: Color = .gray
    
    func addPlaceholderFile(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType) {
        
    }
    func markPlaceholderFileAsReadyForDownload(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType) {
        
    }
    func markFileAsFailedToUpload(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType) {
        
    }
    func displayCompleteAlert(recordID: String, parentType: XrefItem, fileType: FileType) {
        
    }
    func cleanUpPhotoVariables() {
        
    }
    func delete(file: CBFile, parentType: XrefItem, fileType: FileType) async {
        
    }
}

struct SettingsView: View {
    @Local(\.alignWeekdayNamesLeft) var alignWeekdayNamesLeft
    @Local(\.categorySortMode) var categorySortMode
    @Local(\.colorTheme) var colorTheme
    @Local(\.debugPrint) var debugPrint
    @Local(\.incomeColor) var incomeColor
    @Local(\.lineItemIndicator) var lineItemIndicator
    @Local(\.phoneLineItemDisplayItem) var phoneLineItemDisplayItem
    @Local(\.showHashTagsOnLineItems) var showHashTagsOnLineItems
    @Local(\.showIndividualLoadingSpinner) var showIndividualLoadingSpinner
    @Local(\.showPaymentMethodIndicator) var showPaymentMethodIndicator
    @Local(\.startInFullScreen) var startInFullScreen
    @Local(\.threshold) var threshold
    @Local(\.tightenUpEodTotals) var tightenUpEodTotals
    @Local(\.transactionSortMode) var transactionSortMode
    @Local(\.updatedByOtherUserDisplayMode) var updatedByOtherUserDisplayMode
    @Local(\.userColorScheme) var userColorScheme
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(EventModel.self) var eventModel
        
    @Binding var showSettings: Bool
    
    @State private var settingsModel = SettingsModel()
    @State private var showResetAllSettingsAlert = false
    @FocusState private var focusedField: Int?
                
    var body: some View {
        VStack {
            #if os(macOS)
            Form { settingsContent }
                .formStyle(.grouped)
            #else
            List { settingsContent }
                .scrollDismissesKeyboard(.interactively)
            #endif
        }
        .tint(Color.theme)
        .alert("Reset All Settings?", isPresented: $showResetAllSettingsAlert) {
            Button("Reset", role: .destructive, action: resetAllSettings)
            Button("No", role: .close) { showResetAllSettingsAlert = false }
        }
        #if os(iOS)
        .navigationTitle("Settings")
        #endif
    }
    
    
    var settingsContent: some View {
        Group {
            locationErrorView
            myDetailsSections
            additionalUsersSections
            
            #if os(macOS)
            Section("General Settings") {
                alwaysStartInFullScreenToggle
                showIndividualLoadingSpinnersToggle
            }
            #endif
            
            #if os(iOS)
            appThemeSection
            #endif
            
            #if os(macOS)
            alignWeekdayNamesLeftSection
            #endif
                        
            SettingsViewInsert()
            
            deviceInformationSection
            
            //resetAllTipsButton
            
            Button("Reset All Settings") {
                showResetAllSettingsAlert = true
            }
            .tint(.red)
        }
    }
    
    
    @ViewBuilder
    var locationErrorView: some View {
        let globalAuthDeniedError = "Please enable Location Services by going to Settings -> Privacy & Security"
        let authDeniedError = "Please authorize access to Location Services"
        let authRestrictedError = "Can't access location. Do you have Parental Controls enabled?"
        let unknownAuthStatus = "Please contact the developer about an unknown authorization status."
        
        if !LocationManager.shared.authIsAllowed {
            switch LocationManager.shared.manager.authorizationStatus {
            case .notDetermined:
                errorMessage(globalAuthDeniedError)
            case .restricted:
                errorMessage(authRestrictedError)
            case .denied:
                errorMessage(authDeniedError)
            case .authorizedAlways, .authorizedWhenInUse, .authorized:
                EmptyView()
            @unknown default:
                errorMessage(unknownAuthStatus)
            }
        }
    }
    
    
    @ViewBuilder func errorMessage(_ message: String) -> some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom))
                Text(message)
            }
        } footer: {
            Text("Location services are used to find businsses near you when entering a transaction.")
        }
    }
    
    
    var myDetailsSections: some View {
        Section("My Details") {
            HStack {
                myInfo
                Spacer()
                logoutButton
            }
            accountNumberLine
        }
    }
    
    @State private var showCamera: Bool = false
    @State private var showPhotosPicker: Bool = false
    @State private var imagesFromLibrary: Array<PhotosPickerItem> = []
    #if os(iOS)
    @State private var imageFromCamera: UIImage?
    #endif    
    
    var myInfo: some View {
        Label {
            VStack(alignment: .leading) {
                Text("\(AppState.shared.user?.name ?? "N/A")")
                Text("\(AppState.shared.user?.email ?? "N/A")")
                    .foregroundStyle(.gray)
                    .font(.caption2)
            }
        } icon: {
            BusinessLogo(parent: settingsModel, fallBackType: .customImage("person.crop.circle"))
                .onTapGesture {
                    showPhotosPicker = true
                }
            //Image(systemName: "person.crop.circle")
                //.foregroundStyle(.gray)
        }
//        .photoPickerAndCameraSheet(
//            fileUploadCompletedDelegate: settingsModel,
//            parentType: XrefModel.getItem(from: .logoTypes, byEnumID: .userPhoto).enumID,
//            allowMultiSelection: true,
//            showPhotosPicker: $showPhotosPicker,
//            showCamera: $showCamera
//        )
        
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $imagesFromLibrary,
            maxSelectionCount: 1,
            matching: .images,
            photoLibrary: .shared()
        )
        .task {
            /// Fetch the logo out of core data since the encoded strings can be heavy and I don't want to use Async Image for every logo.
            let context = DataManager.shared.createContext()
            if let logo = DataManager.shared.getOne(context: context, type: PersistentLogo.self, predicate: .byId(.string("USER_PHOTO_ID")), createIfNotFound: false) {
                settingsModel.logo = logo.photoData
            } else {
                print("user logo was not found")
            }
        }
            
        /// Upload the picture from the selectedt photos when the photo picker sheet closes.
        .onChange(of: showPhotosPicker) {
            if !$1 {
                if imagesFromLibrary.isEmpty {
                    settingsModel.cleanUpPhotoVariables()
                } else {
                    Task {
                        if let logoData = await FileModel.shared.prepareDataFromPhotoPickerItem(image: imagesFromLibrary[0]) {
                            let context = DataManager.shared.createContext()
                            
                            guard
                                let perLogo = DataManager.shared.getOne(context: context, type: PersistentLogo.self, predicate: .byId(.string("USER_PHOTO_ID")), createIfNotFound: true)
                            else {
                                return
                            }
                            perLogo.id = "USER_PHOTO_ID"
                            perLogo.photoData = logoData
                            perLogo.serverUpdatedDate = Date()
                            perLogo.localUpdatedDate = Date()
                            
                            let _ = DataManager.shared.save(context: context)
                            
                            settingsModel.logo = logoData
                        }
                    }
                }
            }
        }
//        #if os(iOS)
//        .fullScreenCover(isPresented: $showCamera) {
//            AccessCameraView(selectedImage: $imageFromCamera)
//                .background(.black)
//        }
//        /// Upload the picture from the camera when the camera sheet closes.
//        .onChange(of: showCamera) {
//            if !$1 {
//                FileModel.shared.uploadPictureFromCamera(
//                    delegate: settingsModel,
//                    parentType: XrefModel.getItem(from: .logoTypes, byEnumID: .userPhoto)
//                )
//            }
//        }
//        #endif
        
        
    }
    
    
    var logoutButton: some View {
        Button("Logout") {
            Task {
                showSettings = false
                funcModel.logout()
            }
        }
        .focusable(false)
        .buttonStyle(.borderedProminent)
    }
    
    
    var accountNumberLine: some View {
        HStack {
            Label {
                Text("Account #")
            } icon: {
                Image(systemName: "number.circle")
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            if let accountID = AppState.shared.user?.accountID {
                Text("000\(accountID)")
            } else {
                Text("N/A")
            }
        }
    }
    
    
    @ViewBuilder
    var additionalUsersSections: some View {
        if !AppState.shared.accountUsers.filter({ $0.id != AppState.shared.user?.id }).isEmpty {
            Section("Additional Account Users") {
                ForEach(AppState.shared.accountUsers.filter { $0.id != AppState.shared.user?.id }) { user in
                    additionalUserLine(for: user)
                }
            }
        }
    }
    
    
    @ViewBuilder func additionalUserLine(for user: CBUser) -> some View {
        let nameAndEmail = HStack {
            VStack(alignment: .leading) {
                Text(user.name)
                    .foregroundStyle(.primary)
                Text(user.email)
                    .foregroundStyle(.gray)
                    .font(.caption2)
            }
            
            Spacer()
            
            Image(systemName: "envelope.fill")
        }
        
        Link(destination: URL(string: "mailto:?to=\(user.email)")!) {
            Label {
                nameAndEmail
            } icon: {
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(.gray)
            }
        }
        .focusable(false)
    }
    
    
    #if os(macOS)
    var alwaysStartInFullScreenToggle: some View {
        Toggle(isOn: $startInFullScreen) {
            Label {
                Text("Always start in fullscreen")
            } icon: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
        }
    }
    
    
    var showIndividualLoadingSpinnersToggle: some View {
        Toggle(isOn: $showIndividualLoadingSpinner) {
            Label {
                Text("Show sidebar loading indicators")
            } icon: {
                Image(systemName: "arrow.circlepath")
            }
        }
    }
    #endif
    
    
    #if os(iOS)
    var appThemeSection: some View {
        Section("App Theme") {
            HStack {
                Label {
                    Text("Color")
                        .schemeBasedForegroundStyle()
                } icon: {
                    Image(systemName: "lightspectrum.horizontal")
                        .symbolRenderingMode(.multicolor)
                }
                Spacer()
                
                Menu {
                    colorThemePicker
                } label: {
                    HStack(spacing: 4) {
                        Text(colorTheme.capitalized)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote)
                    }
                }
            }
        }
    }
    
    
    var colorThemePicker: some View {
        Picker("", selection: $colorTheme) {
            ForEach(AppState.shared.colorMenuOptions, id: \.self) { color in
                HStack {
                    Text(color.description.capitalized)
                    Image(systemName: "circle.fill")
                        .tint(color)
                        //.foregroundStyle(color, .primary, .secondary)
                    
                }
                .tag(color.description)
            }
        }
        .labelsHidden()
        .pickerStyle(.inline)
    }
    #endif

    
    #if os(macOS)
    var alignWeekdayNamesLeftSection: some View {
        Section("Calendar") {
            Toggle(isOn: $alignWeekdayNamesLeft) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Align weekday names to the left")
                    }
                } icon: {
                    Image(systemName: "arrow.left.arrow.right.square")
                }
            }

        }
    }
    #endif
    
    
    var deviceInformationSection: some View {
        Section {
            if let uuid = UserDefaults.fetchOneString(requestedKey: "deviceUUID") {
                Text(uuid)
                    .foregroundStyle(.gray)
                    .font(.footnote)
            }
                                
            if NotificationManager.shared.notificationsAreAllowed {
                Text(AppState.shared.notificationToken ?? "N/A")
                    .foregroundStyle(.gray)
                    .font(.footnote)
            } else {
                openSettingAppButton
            }
        } header: {
            Text("Device Information")
        } footer: {
            if !NotificationManager.shared.notificationsAreAllowed {
                Text("Notifications are used to alert you about upcoming payments, or reminders about certain transactions.")
            }
        }
    }
    
    
    var openSettingAppButton: some View {
        Button("Enable Notifications") {
            #if os(iOS)
            if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
            }
            #endif
        }
    }
    
    
    var resetAllTipsButton: some View {
        Button("Reset All Tips") {
            do {
                try Tips.resetDatastore()
                try Tips.configure()
            } catch {
                AppState.shared.showAlert("There was a problem resetting all tips.")
            }
        }
        .tint(.orange)
    }
    
    
    func resetAllSettings() {
        useWholeNumbers = false
        colorTheme = Color.green.description
        showIndividualLoadingSpinner = false
        threshold = 500.00
        debugPrint = false
        startInFullScreen = false
        alignWeekdayNamesLeft = true
        showPaymentMethodIndicator = false
        incomeColor = Color.blue.description
        tightenUpEodTotals = true
        phoneLineItemDisplayItem = .both
        lineItemIndicator = .emoji
        updatedByOtherUserDisplayMode = .full
        categorySortMode = .title
        transactionSortMode = .title
        showHashTagsOnLineItems = true
    }    
    
//    func biometricType() -> BiometricType {
//        let authContext = LAContext()
//        if #available(iOS 11, *) {
//            let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
//            
//            switch(authContext.biometryType) {
//            case .none:
//                return .none
//            case .touchID:
//                return .touch
//            case .faceID:
//                return .face
//            case .opticID:
//                return .optic
//            @unknown default:
//                return .none
//            }
//        } else {
//            return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touch : .none
//        }
//    }
//
//    enum BiometricType {
//        case none
//        case touch
//        case face
//        case optic
//    }
}
