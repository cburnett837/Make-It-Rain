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


//var todayDay = Calendar.current.component(.day, from: Date())
//var todayMonth = Calendar.current.component(.month, from: Date())
//var todayYear = Calendar.current.component(.year, from: Date())
//
//func updateTodayVariables() {
//    todayDay = Calendar.current.component(.day, from: Date())
//    todayMonth = Calendar.current.component(.month, from: Date())
//    todayYear = Calendar.current.component(.year, from: Date())
//}
//
//let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
//
//let numberFormatter = NumberFormatter()
//let colorMenuOptions: Array<Color> = [.pink, .red, .orange, .yellow, .green, .mint, .cyan, .blue, .indigo, .purple]

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
    
    @State private var funcModel: FuncModel
    @State private var calModel: CalendarModel
    @State private var payModel: PayMethodModel
    @State private var catModel: CategoryModel
    @State private var keyModel: KeywordModel
    @State private var repModel: RepeatingTransactionModel
    @State private var eventModel: EventModel    
    
    @State private var isUnlocked = false
    
    //#if os(iOS)
    #warning("NOTE: This cannot be in the calendarModel because scrolling on the calendarView causes this to change (idk why), and causes the calendarView to lag. 3/13/25")
    /// Only used in iOS.
    @State private var selectedDay: CBDay?
    //#endif
    
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
            CalendarSheetLayerWrapper(selectedDay: $selectedDay) {
                RootViewWrapper(selectedDay: $selectedDay) {
                    @Bindable var appState = AppState.shared
                    Group {
                        /// `AuthState.shared.isThinking` is always true when app launches from fresh state.
                        /// `AppState.shared.appShouldShowSplashScreen` is set to false in `downloadEverything()` when the current month completes.
                        if AuthState.shared.isThinking || AppState.shared.appShouldShowSplashScreen || !AppState.shared.splashTextAnimationIsFinished/* || AppState.shared.holdSplash */{
                            loadingScreen
                        } else {
                            if AuthState.shared.isLoggedIn {
                                rootView
                            } else {
                                Login()
                                    .transition(.opacity)
                                    .onAppear {
                                        if AuthState.shared.serverRevoked {
                                            //serverRevokedAccess()
                                            AuthState.shared.serverRevoked = false
                                        }
                                    }
                            }
                        }
                    }
                    #if os(iOS)
                    .onAppear {
                        let or = UIDevice.current.orientation
                        AppState.shared.orientation = or
                        if [.landscapeLeft, .landscapeRight].contains(or) || ([.faceUp, .faceDown].contains(or) && AppState.shared.isLandscape) {
                            AppState.shared.isLandscape = true
                        } else {
                            AppState.shared.isLandscape = false
                        }
                        
                        /// Set a default color scheme
                        if UserDefaults.standard.string(forKey: "appColorTheme") == nil {
                            UserDefaults.standard.set(Color.green.description, forKey: "appColorTheme")
                        }
                    }
                    .onRotate {
                        AppState.shared.orientation = $0
                        if [.landscapeLeft, .landscapeRight].contains($0) || ([.faceUp, .faceDown].contains($0) && AppState.shared.isLandscape) {
                            AppState.shared.isLandscape = true
                        } else {
                            AppState.shared.isLandscape = false
                        }
                    }
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
                        if startInFullScreen {
                            Task {
                                await MainActor.run {
                                    AppState.shared.isInFullScreen = true
                                    if let window = NSApplication.shared.windows.last {
                                        window.toggleFullScreen(nil)
                                    }
                                }
                            }
                        }
                        
                        /// Set a default color scheme
                        if UserDefaults.standard.string(forKey: "appColorTheme") == nil {
                            UserDefaults.standard.set(Color.blue.description, forKey: "appColorTheme")
                        }
                    }
                    #endif
                }
            }
            .environment(funcModel)
            .environment(calModel)
            .environment(payModel)
            .environment(catModel)
            .environment(keyModel)
            .environment(repModel)
            .environment(eventModel)
            //.environment(\.colorScheme, preferDarkMode ? .dark : .light)
//            .if(userColorScheme != .userSystem) {
//                $0.preferredColorScheme(userColorScheme == .userDark ? .dark : .light)
//            }
            //.preferredColorScheme(preferDarkMode ? .dark : .light)
        }
        .defaultSize(width: 1000, height: 600)
        
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
            SidebarCommands()
            TextFormattingCommands()
            ToolbarCommands()
        }
        #endif
        
        #if os(macOS)
        Window("Pending Fit Transactions", id: "pendingFitTransactions") {
            FitTransactionOverlay(showFitTransactions: .constant(true))
                .frame(minWidth: 300, minHeight: 200)
                .environment(calModel)
                .environment(payModel)
        }
        
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
        }
        
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
        }
        #endif
    }        
    
    var loadingScreen: some View {
        Group {
            @Bindable var navManager = NavigationManager.shared
            SplashScreen()
                .transition(.opacity)
        }
    }
    
    
    var rootView: some View {
        RootView(selectedDay: $selectedDay)
            .frame(idealWidth: screenWidth, idealHeight: screenHeight)
            .onPreferenceChange(SizePreferenceKey.self) { value in
                screenWidth = value.width
                screenHeight = value.height
            }
    }
    
    
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
    @Environment(CalendarViewModel.self) private var calViewModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    @Environment(EventModel.self) private var eventModel
    
    var content: Content
        
    #if os(iOS)
    @Binding var selectedDay: CBDay?
    @State private var window: UIWindow?
    #endif
    
    init(selectedDay: Binding<CBDay?>, @ViewBuilder content: @escaping () -> Content) {
        self._selectedDay = selectedDay
        self.content = content()
    }
                        
    var body: some View {
        @Bindable var appState = AppState.shared
        content
            .environment(calViewModel)
            #if os(iOS)
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, window == nil {
                    let rootVC = UIHostingController(rootView:
                        AlertAndToastLayerView(selectedDay: $selectedDay)
                            .environment(funcModel)
                            .environment(calModel)
                            .environment(calViewModel)
                            .environment(payModel)
                            .environment(catModel)
                            .environment(keyModel)
                            .environment(repModel)
                            .environment(eventModel)
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
                    .environment(calViewModel)
                    .environment(payModel)
                    .environment(catModel)
                    .environment(keyModel)
                    .environment(repModel)
                    .environment(eventModel)
            }
            #endif
            .task {
                funcModel.setDeviceUUID()
                await login()
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $appState.showPaymentMethodNeededSheet, onDismiss: { downloadInitial() }) {
                PaymentMethodRequiredView()
            }
            .fullScreenCover(isPresented: $appState.hasBadConnection) {
                TempTransactionList()
            }
            #else
            .sheet(isPresented: $appState.showPaymentMethodNeededSheet, onDismiss: { downloadInitial() }) {
                PaymentMethodRequiredView()
                    .padding()
            }
            #endif

    }
    
    
    func login() async {
        /// This will check the keychain for credentials. If it finds them, it will attempt to authenticate with the server. If not, it will take the user to the login page.
        /// If the user successfully authenticates with the server, this will also look if the user has payment methods, and set AppState accordingly.
        if let apiKey = await AuthState.shared.getApiKeyFromKeychain() {
            AuthState.shared.loginTask = Task {
                await AuthState.shared.attemptLogin(using: .apiKey, with: LoginModel(apiKey: apiKey))
                if AuthState.shared.isLoggedIn {
                    /// When the user logs in, if they have no payment methods, show the payment method required sheet.
                    if AppState.shared.methsExist {
                        downloadInitial()
                    } else {
                        LoadingManager.shared.showInitiallyLoadingSpinner = false
                        LoadingManager.shared.showLoadingBar = false
                        AppState.shared.showPaymentMethodNeededSheet = true
                    }
                    //await NotificationManager.shared.registerForPushNotifications()
                }
            }
            
            
        } else {
            AuthState.shared.isThinking = false
            AppState.shared.appShouldShowSplashScreen = false
        }
    }
    
    func downloadInitial() {
        @Bindable var navManager = NavigationManager.shared
        /// Set navigation destination to current month
        //navManager.selection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
        navManager.selectedMonth = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
        //navManager.monthSelection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
        //navManager.navPath.append(NavDestination.getMonthFromInt(AppState.shared.todayMonth)!)
        
        LoadingManager.shared.showInitiallyLoadingSpinner = true
                    
        funcModel.refreshTask = Task {
            /// populate all months with their days.
            calModel.prepareMonths()
            //if let selection = navManager.selection {
            if let selectedMonth = navManager.selectedMonth {
                /// set the calendar model to use the current month (ignore starting amounts and calculations)
                calModel.setSelectedMonthFromNavigation(navID: selectedMonth, prepareStartAmount: false)
                /// download everything, and populate the days in the respective months with transactions.
                await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaInitial)
            }
        }
    }
    
    func serverRevokedAccess() {
        AuthState.shared.logout()
        AppState.shared.downloadedData.removeAll()
        LoadingManager.shared.showInitiallyLoadingSpinner = true
        LoadingManager.shared.downloadAmount = 0
        LoadingManager.shared.showLoadingBar = true
        
        /// Cancel the long polling task.
        funcModel.longPollTask?.cancel()
        funcModel.longPollTask = nil
        
        /// Cancel the regular download task.
        funcModel.refreshTask?.cancel()
        funcModel.refreshTask = nil
        
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
    
    
}


struct CalendarSheetLayerView: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarViewModel.self) private var calViewModel
    @Namespace private var monthNavigationNamespace
    
    @Binding var selectedDay: CBDay?
    
    var body: some View {
        @Bindable var appState = AppState.shared
        @Bindable var calModel = calModel;
        @Bindable var calViewModel = calViewModel
        
        Rectangle()
            .fill(Color.clear)
            .ignoresSafeArea(.all)
            .overlay {
                Rectangle()
                    .fill(Color.clear)
                    //.if(!AppState.shared.isIpad) {
                    .fullScreenCover(isPresented: $calModel.showMonth) {
                        if let selectedMonth = NavigationManager.shared.selectedMonth {
                            
                            if NavDestination.justMonths.contains(selectedMonth) {
                                
                                CalendarViewPhone(enumID: selectedMonth, selectedDay: $selectedDay)
                                    .tint(Color.fromName(appColorTheme))
                                    .navigationTransition(.zoom(sourceID: selectedMonth, in: monthNavigationNamespace))
                                    .if(AppState.shared.methsExist) {
                                        $0.loadingSpinner(id: selectedMonth, text: "Loading…")
                                    }
                            }
                        }
                    }
                    //}
            }
    }
}



struct CalendarSheetLayerWrapper<Content: View>: View {
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    @Environment(EventModel.self) private var eventModel
    
    @State private var calViewModel: CalendarViewModel
    
    var content: Content
        
    #if os(iOS)
    @Binding var selectedDay: CBDay?
    @State private var window: UIWindow?
    #endif
    
    init(selectedDay: Binding<CBDay?>, @ViewBuilder content: @escaping () -> Content) {
        self._selectedDay = selectedDay
        self.content = content()
        self.calViewModel = .init(calModel: CalendarModel.shared)
    }
                        
    var body: some View {
        @Bindable var appState = AppState.shared
        content
            .environment(calViewModel)
            #if os(iOS)
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, window == nil {
                    let rootVC = UIHostingController(rootView:
                        CalendarSheetLayerView(selectedDay: $selectedDay)
                            .environment(funcModel)
                            .environment(calModel)
                            .environment(calViewModel)
                            .environment(payModel)
                            .environment(catModel)
                            .environment(keyModel)
                            .environment(repModel)
                            .environment(eventModel)
                    )
                    rootVC.view.backgroundColor = .clear
                    
                    let window = PassThroughWindowPhone(windowScene: windowScene)
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    window.rootViewController = rootVC
                    self.window = window
                }
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
