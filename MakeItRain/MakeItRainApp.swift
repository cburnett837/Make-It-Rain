//
//  MakeItRainApp.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import SwiftUI
import Observation
import LocalAuthentication
import TipKit
#if os(iOS)
import UIKit
import AppIntents
#endif

@main
struct MakeItRainApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegateMac.self) var appDelegate
    //@State private var windowDelegate = MyWindowDelegate()
    #else
    @UIApplicationDelegateAdaptor(AppDelegatePhone.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    #endif
    
    @Environment(\.colorScheme) var colorScheme
    //@Local(\.colorTheme) var colorTheme
    @AppStorage("appScreenWidth") var screenWidth: Double = 0
    @AppStorage("appScreenHeight") var screenHeight: Double = 0
    @AppStorage("useBiometrics") var useBiometrics = false
    @Local(\.startInFullScreen) var startInFullScreen
    @Local(\.userColorScheme) var userColorScheme
    
    @State private var appState = AppState.shared
    @State private var authState = AuthState.shared
    @State private var undoManager = UndodoManager.shared
    @State private var openRecordManager = OpenRecordManager.shared
    
    @State var funcModel: FuncModel
    @State var calModel: CalendarModel
    @State var payModel: PayMethodModel
    @State var catModel: CategoryModel
    @State var keyModel: KeywordModel
    @State var repModel: RepeatingTransactionModel
    @State var plaidModel: PlaidModel
    
    @State private var photoModel = FileModel.shared
    @State private var locationManager = LocationManager.shared
    @State var dataChangeTriggers = DataChangeTriggers.shared
    //@State private var mapModel = MapModel()
    
    @State var calProps = CalendarProps()
    
    @State private var showCamera = false
    
    //@State private var isUnlocked = false
    
    @Namespace private var monthNavigationNamespace
    
    init() {
        let calModel = CalendarModel()
                
        /// This is now a singleton because the creditLimits are needed inside the calModel. 2/21/25
        /// However, views still access this via the environment.
        let payModel = PayMethodModel.shared
        //let payModel = PayMethodModel()
        
        /// All singletons because of experimenting with single window groups on iPad os.
        /// Should be find to leave them as such.
        let catModel = CategoryModel()
        let keyModel = KeywordModel()
        let repModel = RepeatingTransactionModel()
        let plaidModel = PlaidModel()
        
        self.calModel = calModel
        self.payModel = payModel
        self.catModel = catModel
        self.keyModel = keyModel
        self.repModel = repModel
        self.plaidModel = plaidModel
        
        self.funcModel = .init(
            calModel: calModel,
            payModel: payModel,
            catModel: catModel,
            keyModel: keyModel,
            repModel: repModel,
            plaidModel: plaidModel
        )
        
        do {
            try setupTips()
        } catch {
            print("Error initializing tips: \(error)")
        }
    }
        
    var body: some Scene {
        WindowGroup {
            /// Allow for universal sheets. Such as payment method sheet when first downloading the app, universal alerts, universal camera, etc.
            /// Views shown in this layer will be at the top-most part of the UI - Allowing for content on top of both sheets, and the universal calendar sheet.
            RootViewWrapper(showCamera: $showCamera) {
                /// Allow for a universal calendar view.
                CalendarSheetLayerWrapper(monthNavigationNamespace: monthNavigationNamespace) {
                    @Bindable var appState = AppState.shared
                    Group {
                        /// `AuthState.shared.isThinking` is always true when app launches from a fresh state.
                        /// `AppState.shared.shouldShowSplash` is set to false in `downloadEverything()` when the current month completes, or if login fails.
                        /// `AppState.shared.splashIsAnimating`is true when launching from a fresh state, and is set to false when the animation on the splash screen finishes.
                        /// *Once the 3 conditions above are met, the view will flip to the `rootView` or the `loginView` (depending on the apps overall state).*
                        if AuthState.shared.isThinking || appState.shouldShowSplash || appState.splashIsAnimating {
                            /// Always the first view to be shown.
                            /// Starts the login process.
                            /// Login flow descriptions are written in the `splashScreen` and `loginScreen` views,
                            splashScreen
                        } else {
                            //let _ = print("ROOT VIEW IS BEING RENDERED")
                            if AuthState.shared.isLoggedIn {
                                rootView                                    
                            } else {
                                /// Login flow descriptions are written in the `splashScreen` and `loginScreen` views,
                                loginView
                            }
                        }
                    }
                    #if os(iOS)
                    .onAppear {
                        setDeviceOrientation(UIDevice.current.orientation)
                        setDefaultColorScheme(.green)
                    }
                    .onRotate { setDeviceOrientation($0) }
                    #endif
                    
                    /// Create the app delegate for Mac.
                    #if os(macOS)
                    .background {
                        HostingWindowFinder { window in
                            guard let window else { return }
                            window.delegate = appDelegate
                        }
                    }
                    
                    /// Set fullscreen if the app preferences call for it.
                    .onAppear {
                        if startInFullScreen { startMacInFullScreen() }
                        setDefaultColorScheme(.blue)
                    }
                    #endif
                }
            }
            .onOpenURL { handleOpeningUrl($0) }
            #if os(macOS)
            .toolbar(.visible, for: .windowToolbar)
            #endif
            .environment(funcModel)
            .environment(calModel)
            .environment(payModel)
            .environment(catModel)
            .environment(keyModel)
            .environment(repModel)
            .environment(plaidModel)
            .environment(calProps)
            .environment(dataChangeTriggers)
            //.preferredColorScheme(colorScheme)
        }
        .defaultSize(width: 1000, height: 600)
        
        #if os(macOS)
        //.defaultLaunchBehavior(.presented) --> Not using because we terminate the app when the last window closes.
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
            SidebarCommands()
            //TextFormattingCommands()
            //ToolbarCommands()
        }
        #endif
        
        #if os(macOS)
        dashboardWindow
        plaidWindow
        insightsWindow
        multiSelectWindow
        monthlyPlaceholderWindow
        settingsWindow
        #endif
    }
    
    
    
    
    @ViewBuilder
    private var splashScreen: some View {
        /// -----Login flow for splash screen-----
        /// The splash screen is the first view to show.
        /// It will check the keychain for an API key and call `AuthState.loginViaKeychain()`.
        
        /// If `AuthState.attemptLogin()` is successful, it will ...
            /// 1. Return true to this task, which will run ``FuncModel.downloadInitial()``.
            /// Once...
            ///     1. We are logged in…
            ///     2. Splash animation has finished…
            ///     3. First month has downloaded…
            /// ... the splash screen will show the calendar full screen cover, and a split seocnd later switch the app from ``SplashScreen`` to ``RootView``.
        
        /// If `AuthState.attemptLogin()` fails, it will ...
            /// 1. Set `AuthState.isLoggedIn = false`
            /// 2. Set `AuthState.isThinking = false`.
            /// 3. Set `AppState.shouldShowSplash = false`.
            /// 4. Clear login state. (AKA the api key from the keychain if it exists.)
            /// The combo of variable settings above will cause the app to be redirected to the login screen.
                
        @Bindable var navManager = NavigationManager.shared
        SplashScreen()
            .transition(.opacity)
            .task {
                //print("FLIPPED TO SPLASH SCREEN")
                funcModel.setDeviceUUID()
                
                if AuthState.shared.isLoggedIn {
                    funcModel.downloadInitial()
                } else {
                    if await AuthState.shared.loginViaKeychain() {
                        funcModel.downloadInitial()
                    }
                }
            }
    }
    
    
    private var loginView: some View {
        /// -----Login flow for login screen-----
        /// You enter your email and password on the login page, and tap the login button, which calls `AuthState.attemptLogin()`.
        
        /// If `AuthState.attemptLogin()` is successful, it will set ...
            /// 1. `AuthState.isLoggedIn = true`
            /// 2. `AuthState.isThinking = false`.
            /// 3. `AppState.shared.splashIsAnimating = true`.
            /// 4. `AppState.shouldShowSplash = true`.
            /// --- This will trigger the splash screen to show, which will run ``FuncModel.downloadInitial()`` and do further app logic.
            /// --- See description in `private var splashScreen` for further information.
        
        /// If `AuthState.attemptLogin()`fails, it will...
            /// 1. Set `AuthState.isLoggedIn = false`
            /// 2. Set `AuthState.isThinking = false`.
            /// 3. Set `AppState.shouldShowSplash = false`.
            /// 4. Set an error in ``AuthState`` that will show an alert on the login screen.
            /// 5. Clear login state. (AKA the api key from the keychain if it exists.)
        LoginView()
            .transition(.opacity)
            .onAppear {
                if AuthState.shared.serverRevoked {
                    funcModel.logout()
                    AuthState.shared.serverRevoked = false
                }
            }
    }
    
    
    @ViewBuilder
    private var rootView: some View {
        //let _ = print("RootView Render")
        RootView(monthNavigationNamespace: monthNavigationNamespace)
            .tint(Color.theme)
            .frame(idealWidth: screenWidth, idealHeight: screenHeight)
            .onPreferenceChange(SizePreferenceKey.self) { value in
                screenWidth = value.width
                screenHeight = value.height
            }
    }
    
    
    #if os(iOS)
    private func setDeviceOrientation(_ new: UIDeviceOrientation) {
        AppState.shared.orientation = new
        if [.landscapeLeft, .landscapeRight].contains(new) || ([.faceUp, .faceDown].contains(new) && AppState.shared.isLandscape) {
            AppState.shared.isLandscape = true
        } else {
            AppState.shared.isLandscape = false
        }
    }
    #endif
    
    
    #if os(macOS)
    private func startMacInFullScreen() {
        Task {
            await MainActor.run {
                if let window = NSApplication.shared.windows.last {
                    AppState.shared.isInFullScreen = true
                    window.toggleFullScreen(nil)
                }
            }
        }
    }
    #endif
    
    
    private func setupTips() throws {
        // Show all defined tips in the app.
        // Tips.showAllTipsForTesting()

        // Show some tips, but not all.
        // Tips.showTipsForTesting([tip1, tip2, tip3])

        // Hide all tips defined in the app.
        // Tips.hideAllTipsForTesting()

        // Purge all TipKit-related data.
        //try Tips.resetDatastore()

        // Configure and load all tips in the app.
        try Tips.configure()
        
    }
    
    
    private func setDefaultColorScheme(_ color: Color) {
        /// Set a default color scheme
        if UserDefaults.standard.data(forKey: "colorTheme") == nil {
            let data = try? JSONEncoder().encode(color.description)
            UserDefaults.standard.set(data, forKey: "colorTheme")
        }
    }
    
    
    private func handleOpeningUrl(_ url: URL) {
        print(url.absoluteString)
        
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            fatalError("Could not create URLComponents")
        }
        
        if let queryItems = urlComponents.queryItems {
            for item in queryItems {
                print("Key: \(item.name), Value: \(item.value ?? "nil")")
                
                if item.name == "action" {
                    if item.value == "take_photo" {
                        print("should open camera")
                        calModel.isUploadingSmartTransactionFile = true
                        showCamera = true
                    }
                }
            }
        }
    }
}

