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


@Observable
class SettingsModel {
    @MainActor
    func updateUserAvatar(user: CBUser) async {
        print("-- \(#function)")
        LogManager.log()
      
        let model = RequestModel(requestType: "update_user_avatar", model: user)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success:
            LogManager.networkingSuccessful()

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to update the user avatar.")
        }
    }
}

struct SettingsView: View {
    @Local(\.alignWeekdayNamesLeft) var alignWeekdayNamesLeft
    @Local(\.colorTheme) var colorTheme
    @Local(\.debugPrint) var debugPrint
    @Local(\.lineItemIndicator) var lineItemIndicator
    @Local(\.phoneLineItemDisplayItem) var phoneLineItemDisplayItem
    @Local(\.showHashTagsOnLineItems) var showHashTagsOnLineItems
    @Local(\.showIndividualLoadingSpinner) var showIndividualLoadingSpinner
    @Local(\.showPaymentMethodIndicator) var showPaymentMethodIndicator
    @Local(\.startInFullScreen) var startInFullScreen
    @Local(\.updatedByOtherUserDisplayMode) var updatedByOtherUserDisplayMode
    @Local(\.userColorScheme) var userColorScheme
    
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(PlaidModel.self) var plaidModel
    
        
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
            #if os(iOS)
            Button("No", role: .close) { showResetAllSettingsAlert = false }
            #else
            Button("No") { showResetAllSettingsAlert = false }
            #endif
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
    #if os(iOS)
    @State private var selectedAvatar: UIImage?
    #else
    @State private var selectedAvatar: NSImage?
    #endif
    @State private var showPhotosPicker: Bool = false
    //@State private var imagesFromLibrary: Array<PhotosPickerItem> = []
    #if os(iOS)
    //@State private var imageFromCamera: UIImage?
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
            @Bindable var user = AppState.shared.user!
            Group {
                if AppState.shared.user?.avatar == nil {
                    Button {
                        showPhotosPicker = true
                    } label: {
                        UserAvatar(user: AppState.shared.user!)
                    }
                } else {
                    Menu {
                        Button("Clear Avatar") { changeAvatarAndSendToServer(avatarData: nil) }
                        Button("Change Avatar") { showPhotosPicker = true }
                    } label: {
                        UserAvatar(user: AppState.shared.user!)
                    }
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showPhotosPicker) {
                CustomImageAndCameraPicker(imageSourceType: .photoLibrary, selectedImage: $selectedAvatar)
            }
            #endif
                                    
//            UserAvatar(user: AppState.shared.user!)
//                .onTapGesture {
//                    showPhotosPicker = true
//                }
//                .sheet(isPresented: $showPhotosPicker) {
//                    CustomImageAndCameraPicker(imageSourceType: .photoLibrary, selectedImage: $selectedAvatar)
//                }
//                                    
        }
//        .task {
//            /// Fetch the logo out of core data since the encoded strings can be heavy and I don't want to use Async Image for every logo.
//            let avatarId = "avatar_user_\(AppState.shared.user!.id)"
//            let context = DataManager.shared.createContext()
//            if let logo = DataManager.shared.getOne(context: context, type: PersistentLogo.self, predicate: .byId(.string(avatarId)), createIfNotFound: false) {
//                //settingsModel.logo = logo.photoData
//                AppState.shared.user!.avatar = logo.photoData
//            } else {
//                print("user logo was not found")
//            }
//        }
            
        /// Upload the picture from the selectedt photos when the photo picker sheet closes.
        .onChange(of: showPhotosPicker) {
            if !$1 {
                #if os(iOS)
                if let image = selectedAvatar, let avatarData = FileModel.shared.prepareDataFromUIImage(image: image) {
                    changeAvatarAndSendToServer(avatarData: avatarData)
                } else {
                    changeAvatarAndSendToServer(avatarData: nil)
                }
                #else
                if let image = selectedAvatar, let avatarData = FileModel.shared.prepareDataFromNSImage(image: image) {
                    changeAvatarAndSendToServer(avatarData: avatarData)
                } else {
                    changeAvatarAndSendToServer(avatarData: nil)
                }
                #endif
            }
        }
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
                UserAvatar(user: user)
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
        AppSettings.shared.useWholeNumbers = false
        colorTheme = Color.green.description
        showIndividualLoadingSpinner = false
        AppSettings.shared.lowBalanceThreshold = 500.00
        debugPrint = false
        startInFullScreen = false
        alignWeekdayNamesLeft = true
        showPaymentMethodIndicator = false
        AppSettings.shared.incomeColor = .blue
        AppSettings.shared.tightenUpEodTotals = true
        phoneLineItemDisplayItem = .both
        lineItemIndicator = .emoji
        updatedByOtherUserDisplayMode = .full
        AppSettings.shared.categorySortMode = .title
        AppSettings.shared.transactionSortMode = .title
        showHashTagsOnLineItems = true
    }
    
    
    func changeAvatarAndSendToServer(avatarData: Data?) {
        
        if let avatarData = avatarData {
            performChange(dataOrNil: avatarData)
        } else {
            performChange(dataOrNil: nil)
        }
        
        
        func performChange(dataOrNil: Data?) {
            let context = DataManager.shared.createContext()
            
            /// Set user avatar.
            let pred1 = NSPredicate(format: "relatedID == %@", String(AppState.shared.user!.id))
            let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: 47))
            let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
            
            guard
                let perLogo = DataManager.shared.getOne(
                    context: context,
                    type: PersistentLogo.self,
                    predicate: .compound(comp),
                    createIfNotFound: true
                )
            else {
                return
            }
            if perLogo.id == nil {
                perLogo.id = UUID().uuidString
            }
            perLogo.relatedID = String(AppState.shared.user!.id)
            perLogo.relatedTypeID = Int64(47)
            perLogo.photoData = dataOrNil
            perLogo.serverUpdatedDate = Date()
            perLogo.localUpdatedDate = Date()
            
            let _ = DataManager.shared.save(context: context)
            
            
            funcModel.changeAvatarLocally(to: dataOrNil, id: String(AppState.shared.user!.id))
            
            //settingsModel.logo = logoData
            Task {
                await settingsModel.updateUserAvatar(user: AppState.shared.user!)
            }
        }
        
        
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
