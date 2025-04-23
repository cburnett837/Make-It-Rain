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
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("appScreenWidth") var screenWidth: Double = 0
    @AppStorage("appScreenHeight") var screenHeight: Double = 0
    @AppStorage("useBiometrics") var useBiometrics = false
    @AppStorage("startInFullScreen") var startInFullScreen = false
    @AppStorage("userColorScheme") var userColorScheme: UserPreferedColorScheme = .userSystem
    
    @State private var appState = AppState.shared
    @State private var authState = AuthState.shared
    @State private var undoManager = UndodoManager.shared
    @State private var openRecordManager = OpenRecordManager.shared
    
    @State private var funcModel: FuncModel
    @State private var calModel: CalendarModel
    @State private var payModel: PayMethodModel
    @State private var catModel: CategoryModel
    @State private var keyModel: KeywordModel
    @State private var repModel: RepeatingTransactionModel
    @State private var eventModel: EventModel
    
    @State private var photoModel = PhotoModel.shared
    @State private var locationManager = LocationManager.shared
    @State private var mapModel = MapModel()
    
    @State private var isUnlocked = false
    
    init() {
        let calModel = CalendarModel.shared
                
        /// This is now a singleton because the creditLimits are needed inside the calModel. 2/21/25
        /// However, views still access this via the environment.
        let payModel = PayMethodModel.shared
        //let payModel = PayMethodModel()
        
        /// All singletons because of experimenting with single window groups on iPad os.
        /// Should be find to leave them as such
        let catModel = CategoryModel.shared
        let keyModel = KeywordModel.shared
        let repModel = RepeatingTransactionModel.shared
        let eventModel = EventModel.shared
        
        self.calModel = calModel
        self.payModel = payModel
        self.catModel = catModel
        self.keyModel = keyModel
        self.repModel = repModel
        self.eventModel = eventModel
        
        self.funcModel = .init(calModel: calModel, payModel: payModel, catModel: catModel, keyModel: keyModel, repModel: repModel, eventModel: eventModel)
        
        do {
            try setupTips()
        } catch {
            print("Error initializing tips: \(error)")
        }
    }
        
    var body: some Scene {
        WindowGroup {
            RootViewWrapper {
                CalendarSheetLayerWrapper {
                    @Bindable var appState = AppState.shared
                    Group {
                        /// `AuthState.shared.isThinking` is always true when app launches from fresh state.
                        /// `AppState.shared.appShouldShowSplashScreen` is set to false in `downloadEverything()` when the current month completes.
                        /// `AppState.shared.splashTextAnimationIsFinished` is set to false in when the animation on the splash screen finishes.
                        if AuthState.shared.isThinking || AppState.shared.appShouldShowSplashScreen || !AppState.shared.splashTextAnimationIsFinished/* || AppState.shared.holdSplash */{
                            /// Always the first view to be shown.
                            /// Starts the login process.
                            splashScreen
                        } else {
                            if AuthState.shared.isLoggedIn {
                                rootView
                            } else {
                                LoginView()
                                    .transition(.opacity)
                                    .onAppear {
                                        if AuthState.shared.serverRevoked {
                                            funcModel.logout()
                                            AuthState.shared.serverRevoked = false
                                        }
                                    }
                            }
                        }
                    }
                    #if os(iOS)
                    .onAppear {
                        setDeviceOrientation(UIDevice.current.orientation)
                        
                        /// Set a default color scheme
                        if UserDefaults.standard.string(forKey: "appColorTheme") == nil {
                            UserDefaults.standard.set(Color.green.description, forKey: "appColorTheme")
                        }
                    }
                    .onRotate { setDeviceOrientation($0) }
                    #endif
                    
                    /// Create the app delegate for Mac
                    #if os(macOS)
                    .background {
                        HostingWindowFinder { window in
                            guard let window else { return }
                            window.delegate = appDelegate
                        }
                    }
                    
                    /// Set fullscreen if the app preferences call for it
                    .onAppear {
                        if startInFullScreen { startMacInFullScreen() }
                        
                        /// Set a default color scheme
                        if UserDefaults.standard.string(forKey: "appColorTheme") == nil {
                            UserDefaults.standard.set(Color.blue.description, forKey: "appColorTheme")
                        }
                    }
                    #endif
                }
            }
//            .onChange(of: openRecordManager.openOrClosedRecords.count, { oldValue, newValue in
//                OpenRecordManager.shared.openOrClosedRecords.forEach {
//                    print($0.user.id)
//                    print($0.recordID)
//                    print($0.recordType.enumID)
//                    print($0.active)
//                    print("----")
//                }
//                print("")
//                print("")
//                print("")
//                print("")
//                print("")
//            })
            
            #if os(macOS)
            .toolbar(.visible, for: .windowToolbar)
            #endif
            .environment(funcModel)
            .environment(calModel)
            .environment(payModel)
            .environment(catModel)
            .environment(keyModel)
            .environment(repModel)
            .environment(eventModel)
            //.environment(mapModel)
            //.environment(\.colorScheme, preferDarkMode ? .dark : .light)
//            .if(userColorScheme != .userSystem) {
//                $0.preferredColorScheme(userColorScheme == .userDark ? .dark : .light)
//            }
            //.preferredColorScheme(preferDarkMode ? .dark : .light)
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
        Window("Pending Fit Transactions", id: "pendingFitTransactions") {
            FitTransactionOverlay(bottomPanelContent: .constant(.fitTransactions), bottomPanelHeight: .constant(0), scrollContentMargins: .constant(0))
                .frame(minWidth: 300, minHeight: 200)
                .environment(calModel)
                .environment(payModel)
        }
        //.defaultLaunchBehavior(.suppressed) --> Not using because we terminate the app when the last window closes.
        /// Make sure any left over windows do not get opened when the app launches.
        .restorationBehavior(.disabled)
        
        Window("Category Analysis", id: "analysisSheet") {
            AnalysisSheet(showAnalysisSheet: .constant(true))
                .frame(minWidth: 300, minHeight: 500)
                .environment(funcModel)
                .environment(calModel)
                .environment(payModel)
                .environment(catModel)
                .environment(keyModel)
                .environment(repModel)
                .environment(eventModel)
                //.environment(mapModel)
        }
        //.defaultLaunchBehavior(.suppressed) --> Not using because we terminate the app when the last window closes.
        .restorationBehavior(.disabled)
        
        WindowGroup("MonthlyWindowPlaceHolder", id: "monthlyWindow", for: NavDestination?.self) { dest in
            let width = ((NSScreen.main?.visibleFrame.width ?? 500) / 3) * 2
            let height = ((NSScreen.main?.visibleFrame.height ?? 500) / 4) * 3
                        
            if let dest = dest.wrappedValue {
                CalendarViewMac(enumID: dest!, isInWindow: true)
                    /// Frame is required to prevent the window from entering full screen if the main window is full screen
                    .frame(
                        minWidth: width,
                        maxWidth: (NSScreen.main?.visibleFrame.width ?? 500) - 1,
                        minHeight: height,
                        maxHeight: (NSScreen.main?.visibleFrame.height ?? 500) - 1
                    )
                    .environment(funcModel)
                    .environment(calModel)
                    .environment(payModel)
                    .environment(catModel)
                    .environment(keyModel)
                    .environment(repModel)
                    .environment(eventModel)
                    //.environment(mapModel)
                    .onAppear {
                        if let window = NSApp.windows.first(where: {$0.title.contains("MonthlyWindowPlaceHolder")}) {
                            window.title = AppState.shared.monthlySheetWindowTitle
                        }
                    }
                    .onDisappear {
                        calModel.windowMonth = nil
                    }                
            }
        }
        /// Required to prevent the window from entering full screen if the main window is full screen
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.expanded)
        //.defaultLaunchBehavior(.suppressed) --> Not using because we terminate the app when the last window closes.
        /// Make sure any left over windows do not get opened when the app launches.
        .restorationBehavior(.disabled)
        
        Settings {
            SettingsView(showSettings: .constant(false))
                .frame(maxWidth: 400, minHeight: 600)
                .environment(funcModel)
                .environment(calModel)
                .environment(payModel)
                .environment(catModel)
                .environment(keyModel)
                .environment(repModel)
                .environment(eventModel)
                //.environment(mapModel)
        }
        #endif
    }        
    
    var splashScreen: some View {
        @Bindable var navManager = NavigationManager.shared
        return SplashScreen()
            .transition(.opacity)
            .task {
                print("FLIPPED TO SPLASH SCREEN")
                funcModel.setDeviceUUID()
                await AuthState.shared.loginViaKeychain(funcModel: funcModel)
            }
    }
    
    
    var rootView: some View {
        RootView()
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
}



struct RootViewWrapper<Content: View>: View {
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    @Environment(EventModel.self) private var eventModel
    //@Environment(MapModel.self) private var mapModel
    
    var content: Content
        
    #if os(iOS)
    @State private var window: UIWindow?
    #endif
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
                        
    var body: some View {
        @Bindable var appState = AppState.shared
        content
            #if os(iOS)
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, window == nil {
                    let rootVC = UIHostingController(rootView:
                        AlertAndToastLayerView()
                            .environment(funcModel)
                            .environment(calModel)
                            .environment(payModel)
                            .environment(catModel)
                            .environment(keyModel)
                            .environment(repModel)
                            .environment(eventModel)
                            //.environment(mapModel)
                    )
                    rootVC.view.backgroundColor = .clear
                    
                    let window = PassThroughWindowPhone(windowScene: windowScene)
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    window.rootViewController = rootVC
                    self.window = window
                }
            }
            #else
            .overlay {
                AlertAndToastLayerView()
                    .environment(funcModel)
                    .environment(calModel)
                    .environment(payModel)
                    .environment(catModel)
                    .environment(keyModel)
                    .environment(repModel)
                    .environment(eventModel)
                    //.environment(mapModel)
            }
            #endif
//            .task {
//                funcModel.setDeviceUUID()
//                await AuthState.shared.loginViaKeychain(funcModel: funcModel)
//            }
            #if os(iOS)
            .fullScreenCover(isPresented: $appState.showPaymentMethodNeededSheet, onDismiss: { funcModel.downloadInitial() }) {
                PaymentMethodRequiredView()
            }
            .fullScreenCover(isPresented: $appState.hasBadConnection) {
                TempTransactionList()
            }
            #else
            .sheet(isPresented: $appState.showPaymentMethodNeededSheet, onDismiss: { funcModel.downloadInitial() }) {
                PaymentMethodRequiredView()
                    .padding()
            }
            #endif

    }
    
    
//    func login() async {
//        /// This will check the keychain for credentials. If it finds them, it will attempt to authenticate with the server. If not, it will take the user to the login page.
//        /// If the user successfully authenticates with the server, this will also look if the user has payment methods, and set AppState accordingly.
//        if let apiKey = await AuthState.shared.getApiKeyFromKeychain() {
//            AuthState.shared.loginTask = Task {
//                await AuthState.shared.attemptLogin(using: .apiKey, with: LoginModel(apiKey: apiKey))
//                if AuthState.shared.isLoggedIn {
//                    /// When the user logs in, if they have no payment methods, show the payment method required sheet.
//                    if AppState.shared.methsExist {
//                        funcModel.downloadInitial()
//                    } else {
//                        LoadingManager.shared.showInitiallyLoadingSpinner = false
//                        LoadingManager.shared.showLoadingBar = false
//                        AppState.shared.showPaymentMethodNeededSheet = true
//                    }
//                    //await NotificationManager.shared.registerForPushNotifications()
//                }
//            }
//        } else {
//            AuthState.shared.isThinking = false
//            AppState.shared.appShouldShowSplashScreen = false
//        }
//    }
    
//    func downloadInitial() {
//        @Bindable var navManager = NavigationManager.shared
//        /// Set navigation destination to current month
//        //navManager.selection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
//        #if os(iOS)
//        navManager.selectedMonth = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
//        #else
//        navManager.selection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
//        #endif
//        //navManager.monthSelection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
//        //navManager.navPath.append(NavDestination.getMonthFromInt(AppState.shared.todayMonth)!)
//        
//        LoadingManager.shared.showInitiallyLoadingSpinner = true
//                    
//        funcModel.refreshTask = Task {
//            /// populate all months with their days.
//            calModel.prepareMonths()
//            #if os(iOS)
//            if let selectedMonth = navManager.selectedMonth {
//                /// set the calendar model to use the current month (ignore starting amounts and calculations)
//                calModel.setSelectedMonthFromNavigation(navID: selectedMonth, prepareStartAmount: false)
//                /// download everything, and populate the days in the respective months with transactions.
//                await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaInitial)
//            }
//            #else
//            if let selectedMonth = navManager.selection {
//                /// set the calendar model to use the current month (ignore starting amounts and calculations)
//                calModel.setSelectedMonthFromNavigation(navID: selectedMonth, prepareStartAmount: false)
//                /// download everything, and populate the days in the respective months with transactions.
//                await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaInitial)
//            }
//            #endif
//        }
//    }
    
//    func serverRevokedAccess() {
//        AuthState.shared.logout()
//        AppState.shared.downloadedData.removeAll()
//        LoadingManager.shared.showInitiallyLoadingSpinner = true
//        LoadingManager.shared.downloadAmount = 0
//        LoadingManager.shared.showLoadingBar = true
//        
//        /// Cancel the long polling task.
//        funcModel.longPollTask?.cancel()
//        funcModel.longPollTask = nil
//        
//        /// Cancel the regular download task.
//        funcModel.refreshTask?.cancel()
//        funcModel.refreshTask = nil
//        
//        /// Remove all transactions and starting amounts for all months.
//        calModel.months.forEach { month in
//            month.startingAmounts.removeAll()
//            month.days.forEach { $0.transactions.removeAll() }
//            month.budgets.removeAll()
//        }
//        
//        /// Remove all extra downloaded data.
//        repModel.repTransactions.removeAll()
//        payModel.paymentMethods.removeAll()
//        catModel.categories.removeAll()
//        keyModel.keywords.removeAll()
//        eventModel.events.removeAll()
//        eventModel.invitations.removeAll()
//        
//        /// Remove all from cache.
//        let _ = DataManager.shared.deleteAll(for: PersistentPaymentMethod.self, shouldSave: false)
//        //print(saveResult1)
//        let _ = DataManager.shared.deleteAll(for: PersistentCategory.self, shouldSave: false)
//        //print(saveResult2)
//        let _ = DataManager.shared.deleteAll(for: PersistentKeyword.self, shouldSave: false)
//        //print(saveResult3)
//        
//        let _ = DataManager.shared.save()
//    }
    
    
}


struct CalendarSheetLayerView: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @Environment(CalendarModel.self) private var calModel
    
    @Namespace private var monthNavigationNamespace
        
    var body: some View {
        @Bindable var appState = AppState.shared
        @Bindable var calModel = calModel;
        
        Rectangle()
            .fill(Color.clear)
            .ignoresSafeArea(.all)
            .overlay {
                Rectangle()
                    .fill(Color.clear)
                    .ignoresSafeArea(.all)
                    //.if(!AppState.shared.isIpad) {
                    #if os(iOS)
                    .fullScreenCover(isPresented: $calModel.showMonth) {
                        if let selectedMonth = NavigationManager.shared.selectedMonth {
                            if NavDestination.justMonths.contains(selectedMonth) {
                                CalendarViewPhone(enumID: selectedMonth)                                    
                                    .tint(Color.fromName(appColorTheme))
                                    .navigationTransition(.zoom(sourceID: selectedMonth, in: monthNavigationNamespace))
                                    .if(AppState.shared.methsExist) {
                                        $0.loadingSpinner(id: selectedMonth, text: "Loading…")
                                    }
                            }
                        }
                    }
                    #else
//                    .sheet(isPresented: $calModel.showMonth) {
//                        if let selectedMonth = NavigationManager.shared.selectedMonth {
//                            if NavDestination.justMonths.contains(selectedMonth) {
//                                CalendarViewMac(enumID: selectedMonth)
//                                    .if(AppState.shared.methsExist) {
//                                        $0.loadingSpinner(id: selectedMonth, text: "Loading…")
//                                    }
//                                    .frame(minWidth: 300, minHeight: 500)
//                                    .presentationSizing(.fitted)
//                            }
//                        }
//                    }
                    #endif
                    
                    //}
            }
    }
}


#if os(macOS)
class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}
#endif

struct CalendarSheetLayerWrapper<Content: View>: View {
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    @Environment(EventModel.self) private var eventModel
    //@Environment(MapModel.self) private var mapModel
    
    
    var content: Content
        
    #if os(iOS)
    @State private var window: UIWindow?
    #else
    @State private var window: NSWindow?
    #endif
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
                        
    var body: some View {
        @Bindable var appState = AppState.shared
        content
            #if os(iOS)
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, window == nil {
                    let rootVC = UIHostingController(rootView:
                        CalendarSheetLayerView()
                            .environment(funcModel)
                            .environment(calModel)
                            .environment(payModel)
                            .environment(catModel)
                            .environment(keyModel)
                            .environment(repModel)
                            .environment(eventModel)
                            //.environment(mapModel)
                    )
                    rootVC.view.backgroundColor = .clear
                    
                    let window = PassThroughWindowPhone(windowScene: windowScene)
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    window.rootViewController = rootVC
                    self.window = window
                }
            }
            #else
            .onAppear {
//                guard window == nil else { return }
//
//                let overlay = NSHostingView(rootView:
//                    CalendarSheetLayerView()
//                        .environment(funcModel)
//                        .environment(calModel)
//                        .environment(payModel)
//                        .environment(catModel)
//                        .environment(keyModel)
//                        .environment(repModel)
//                        .environment(eventModel)
//                )
//
//                let window = OverlayWindow(
//                    contentRect: NSScreen.main?.frame ?? .zero,
//                    styleMask: [.borderless],
//                    backing: .buffered,
//                    defer: false
//                )
//                window.isOpaque = false
//                window.backgroundColor = .clear
//                window.level = .floating
//                window.contentView = overlay
//                window.makeKeyAndOrderFront(nil)
//
//                self.window = window
            }
            #endif
    }
}







#if os(iOS)
class PassThroughWindowPhone: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        if #available(iOS 18, *) {
            guard let view, _hitTest(point, from: view) != rootViewController?.view else { return nil }
        } else {
            guard view != rootViewController?.view else { return nil }
        }
        
        return view
    }
    
    private func _hitTest(_ point: CGPoint, from view: UIView) -> UIView? {
        let converted = convert(point, to: view)
        guard view.bounds.contains(converted) && view.isUserInteractionEnabled && !view.isHidden && view.alpha > 0 else { return nil }
        
        return view.subviews.reversed()
            .reduce(Optional<UIView>.none) { result, view in
                result ?? _hitTest(point, from: view)
            } ?? view
    }
}
#endif
