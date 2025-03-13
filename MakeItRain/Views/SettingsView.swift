//
//  Settings.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import SwiftUI
import LocalAuthentication
import TipKit


struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    
    @AppStorage("userColorScheme") var userColorScheme: UserPreferedColorScheme = .userSystem
    
    
    @AppStorage("darkModeBackgroundColor") var darkModeBackgroundColor: String = "darkGray3"
    @AppStorage("darkModeSelectionColor") var darkModeSelectionColor: String?
    @AppStorage("showIndividualLoadingSpinner") var showIndividualLoadingSpinner = false
    @AppStorage("threshold") var threshold = "500.00"
    @AppStorage("debugPrint") var debugPrint = false
    //@AppStorage("useBiometrics") var useBiometrics = false
    @AppStorage("startInFullScreen") var startInFullScreen = false
    @AppStorage("alignWeekdayNamesLeft") var alignWeekdayNamesLeft = true
    
    
    
    /// BEGIN ONLY HERE FOR RESET ALL BUTTON
    @AppStorage("showPaymentMethodIndicator") var showPaymentMethodIndicator = false
    @AppStorage("incomeColor") var incomeColor: String = Color.blue.description
    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    @AppStorage("lineItemInteractionMode") var lineItemInteractionMode: LineItemInteractionMode = .open
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    //@AppStorage("macCategoryDisplayMode") var macCategoryDisplayMode: MacCategoryDisplayMode = .emoji
    
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode: UpdatedByOtherUserDisplayMode = .full
    @AppStorage("phoneLineItemTotalPosition") var phoneLineItemTotalPosition: PhoneLineItemTotalPosition = .below
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    @AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
    
    @AppStorage("showHashTagsOnLineItems") var showHashTagsOnLineItems: Bool = true
    /// END ONLY HERE FOR RESET ALL BUTTON
    
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(EventModel.self) var eventModel
        
    //@State private var bioType: BiometricType?
        
    @Binding var showSettings: Bool
    
    @FocusState private var focusedField: Int?
    
    @State private var showResetAllSettingsAlert = false
    
    #if os(iOS)
    struct GrayOption: Identifiable {
        var id = UUID()
        var title: String
        var tag: String
        var selectionTag: String?
        var color: Color
    }
    
    let grayOptions: Array<GrayOption> = [
        GrayOption(title: "Gray 1", tag: "darkGray", selectionTag: "systemGray4", color: Color.darkGray),
        GrayOption(title: "Gray 2", tag: "darkGray2", selectionTag: "systemGray4", color: Color.darkGray2),
        GrayOption(title: "Gray 3", tag: "darkGray3", selectionTag: "systemGray4", color: Color.darkGray3),
        GrayOption(title: "Black", tag: "black", selectionTag: "systemGray4", color: .black)
    ]
    #endif
    
    
    var body: some View {
        VStack {
//            #if os(iOS)
//            SheetHeader(title: "Settings", close: { showSettings = false })
//                .padding()
//            #endif
            
            Group {
                #if os(macOS)
                Form {
                    settingsContent
                }
                .formStyle(.grouped)
                #else
                List {
                    settingsContent
                }
                .scrollDismissesKeyboard(.interactively)
                #endif
            }
//            .task {
//                bioType = biometricType()
//            }
        }
        //.preferredColorScheme(preferDarkMode ? .dark : .light)
        .tint(Color.fromName(appColorTheme))
        .alert("Reset All Settings?", isPresented: $showResetAllSettingsAlert) {
            Button("Reset", role: .destructive, action: resetAllSettings)
            Button("No", role: .cancel) {
                showResetAllSettingsAlert = false
            }
        }
        #if os(iOS)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationBarBackButtonHidden(true)
        .toolbar {
            #if os(iOS)
            phoneToolbar()
            #endif
        }
    }
    
    #if os(iOS)
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        if !AppState.shared.isIpad {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                    //dismiss() //NavigationManager.shared.selection = nil // NavigationManager.shared.navPath.removeLast()
                    //NavigationManager.shared.selection = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }
    #endif
    
    
    
    var settingsContent: some View {
        Group {
            Section("Your Details") {
                HStack {
                    
                    Label {
                        VStack(alignment: .leading) {
                            Text("\(AppState.shared.user?.name ?? "N/A")")
                            Text("\(AppState.shared.user?.email ?? "N/A")")
                                .foregroundStyle(.gray)
                                .font(.caption2)
                        }
                    } icon: {
                        Image(systemName: "person.crop.circle")
                    }
                    Spacer()
                    
                    Button("Logout", action: logout)
                        .focusable(false)
                }
                
                HStack {
                    Label {
                        Text("Account #")
                    } icon: {
                        Image(systemName: "number.circle")
                    }
                    
                    Spacer()
                    if let accountID = AppState.shared.user?.accountID {
                        Text("000\(accountID)")
                    } else {
                        Text("N/A")
                    }
                }
//                
//                HStack {
//                    Label {
//                        Text("Account Users")
//                    } icon: {
//                        Image(systemName: "person.3.fill")
//                    }
//                    
//                    VStack {
//                        ForEach(AppState.shared.accountUsers) { user in
//                            Text(user.email)
//                        }
//                    }
//                }
            }
            
            Section("Additional Account Users") {
                ForEach(AppState.shared.accountUsers.filter { $0.id != AppState.shared.user?.id }) { user in
                    HStack {
                        
                        Link(destination: URL(string: "mailto:?to=\(user.email)")!) {
                            //Label { Text("Email (via Mail)") } icon: { Image(systemName: "envelope.fill") }
                            
                            Label {
                                HStack {
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
                                
                                
                            } icon: {
                                Image(systemName: "person.crop.circle")
                            }
                            
                        }
                        .focusable(false)
                    }
                }
            }
            
            Section("General Settings") {
                #if os(macOS)
                Toggle(isOn: $startInFullScreen) {
                    Label {
                        Text("Always start in fullscreen")
                    } icon: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                }
                #endif
                
//                    Toggle(isOn: $useBiometrics) {
//                        Label {
//                            Text(bioType == .face ? "Use Face ID to unlock" : "Use Touch ID to unlock")
//                        } icon: {
//                            Image(systemName: bioType == .face ? "faceid" : "touchid")
//                        }
//                    }
                                    
                #if os(macOS)
                Toggle(isOn: $showIndividualLoadingSpinner) {
                    Label {
                        Text("Show sidebar loading indicators")
                    } icon: {
                        Image(systemName: "arrow.circlepath")
                    }
                }
                #endif
                
                
                
                
                
                Toggle(isOn: $debugPrint) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Console print")
                        }
                    } icon: {
                        Image(systemName: "apple.terminal")
                    }
                }
                .onChange(of: debugPrint) { oldValue, newValue in
                    if newValue {
                        UserDefaults.standard.set("YES", forKey: "debugPrint")
                        AppState.shared.debugPrintString = "YES"
                    } else {
                        UserDefaults.standard.set("NO", forKey: "debugPrint")
                        AppState.shared.debugPrintString = "NO"
                    }
                }
            }
            
            #if os(iOS)
            Section("App Theme") {
                Menu {
                    Picker("", selection: $appColorTheme) {
                        ForEach(AppState.shared.colorMenuOptions, id: \.self) { color in
                            HStack {
                                Text(color.description.capitalized)
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(color, .primary, .secondary)
                            }
                            .tag(color.description)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.inline)
                    
                } label: {
                    HStack {
                        Label {
                            Text("Color")
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        } icon: {
                            Image(systemName: "lightspectrum.horizontal")
                                .symbolRenderingMode(.multicolor)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text(appColorTheme.capitalized)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.footnote)
                        }
                    }
                }
                                    
//                Toggle(isOn: $preferDarkMode) {
//                    Label {
//                        Text("Dark mode")
//                    } icon: {
//                        Image(systemName: "moon")
//                    }
//                }
//                
//                if colorScheme == .dark || preferDarkMode {
//                    Menu {
//                        Picker("", selection: $darkModeBackgroundColor) {
//                            ForEach(grayOptions) { opt in
//                                HStack {
//                                    Text(opt.title)
//                                    Image(systemName: "circle.fill")
//                                        .foregroundStyle(opt.color, .primary, .secondary)
//                                }
//                                .tag(opt.tag)
//                            }
//                        }
//                        .labelsHidden()
//                        .pickerStyle(.inline)
//                    } label: {
//                        HStack {
//                            Label {
//                                Text("Background color")
//                                    .foregroundStyle(preferDarkMode ? .white : .black)
//                            } icon: {
//                                Image(systemName: "circle.fill")
//                                    .foregroundStyle(AngularGradient(gradient: Gradient(colors: [.gray, .darkGray, .darkGray2, .darkGray3, .black]), center: .center))
//                            }
//                            Spacer()
//                            HStack(spacing: 4) {
//                                let title = grayOptions.first { $0.tag == darkModeBackgroundColor }?.title
//                                
//                                Text(title ?? "N/A")
//                                Image(systemName: "chevron.up.chevron.down")
//                                    .font(.footnote)
//                            }
//                        }
//                    }
//                    .onChange(of: darkModeBackgroundColor, initial: true) { oldValue, newValue in
//                        let applicable = grayOptions.first { $0.tag == newValue }
//                        darkModeSelectionColor = applicable?.selectionTag
//                    }
//                }
//                
//                Picker("", selection: $userColorScheme) {
//                    Text("Dark")
//                        .tag(UserPreferedColorScheme.userDark)
//                    Text("Light")
//                        .tag(UserPreferedColorScheme.userLight)
//                    Text("System")
//                        .tag(UserPreferedColorScheme.userSystem)
//                }
//                .pickerStyle(.segmented)
//                .labelsHidden()
                
                
            }
            #endif
            
            #if os(macOS)
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
            #endif
                        
            SettingsViewInsert()

            
            Section {
                if let uuid = UserDefaults.fetchOneString(requestedKey: "deviceUUID") {
                    Text(uuid)
                        .foregroundStyle(.gray)
                        .font(.footnote)
                }
                                    
                if NotificationManager.shared.notificationsAreAllowed {
                    Text(AppState.shared.user?.notificationToken ?? "N/A")
                        .foregroundStyle(.gray)
                        .font(.footnote)
                } else {
                    Button("Enable Notifications") {
                        #if os(macOS)
//                        if let appSettingsURL = URL(string: NSApplication.openSettingsURLString) {
//                            NSApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
//                        }
                        #else
                        if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
                        }
                        #endif
                        
                    }
                }
            } header: {
                Text("Device Information")
            } footer: {
                if !NotificationManager.shared.notificationsAreAllowed {
                    Text("Notifications are used to alert you about upcoming payments, or reminders about certain transactions.")
                }
            }

                                              
//            Button("Reset All Tips") {
//                do {
//                    try Tips.resetDatastore()
//                    try Tips.configure()
//                } catch {
//                    AppState.shared.showAlert("There was a problem resetting all tips.")
//                }
//            }
//            .tint(.orange)
            
            Button("Reset All Settings") {
                showResetAllSettingsAlert = true
            }
            .tint(.red)
        }
    }
    
    
    func resetAllSettings() {
        useWholeNumbers = false
        appColorTheme = Color.green.description
        preferDarkMode = true
        darkModeBackgroundColor = "darkGray3"
        darkModeSelectionColor = "systemGray4"
        showIndividualLoadingSpinner = false
        threshold = "500.00"
        debugPrint = false
        startInFullScreen = false
        alignWeekdayNamesLeft = true
        showPaymentMethodIndicator = false
        incomeColor = Color.blue.description
        tightenUpEodTotals = true
        lineItemInteractionMode = .open
        phoneLineItemDisplayItem = .both
        lineItemIndicator = .emoji
        updatedByOtherUserDisplayMode = .full
        phoneLineItemTotalPosition = .below
        categorySortMode = .title
        transactionSortMode = .title
        showHashTagsOnLineItems = true
    }
    
    
    func logout() {
        showSettings = false
        AuthState.shared.logout()
        AppState.shared.downloadedData.removeAll()
        LoadingManager.shared.showInitiallyLoadingSpinner = true
        LoadingManager.shared.downloadAmount = 0
        LoadingManager.shared.showLoadingBar = true        
        
        /// Cancel the long polling task.
        if let _ = funcModel.longPollTask {
            funcModel.longPollTask!.cancel()
            funcModel.longPollTask = nil
        }
        
        /// Remove all transactions and starting amounts for all months.
        calModel.months.forEach { month in
            month.startingAmounts.removeAll()
            month.days.forEach { $0.transactions.removeAll() }
            month.budgets.removeAll()
        }
        
        /// Remove all extra downloaded data.
        repModel.repTransactions.removeAll()
        payModel.paymentMethods.removeAll()
        catModel.categories.removeAll()
        keyModel.keywords.removeAll()
        eventModel.events.removeAll()
        eventModel.invitations.removeAll()
        
        /// Remove all from cache.
        let _ = DataManager.shared.deleteAll(for: PersistentPaymentMethod.self, shouldSave: false)
        //print(saveResult1)
        let _ = DataManager.shared.deleteAll(for: PersistentCategory.self, shouldSave: false)
        //print(saveResult2)
        let _ = DataManager.shared.deleteAll(for: PersistentKeyword.self, shouldSave: false)
        //print(saveResult3)
        
        let _ = DataManager.shared.save()
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
