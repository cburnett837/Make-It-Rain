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
    //@State private var tagModel = TagModel()
    
    @State private var isUnlocked = false
    
    init() {
        let calModel = CalendarModel()
                
        /// This is now a singleton because the creditLimits are needed inside the calModel. 2/21/25
        /// However, views still access this via the environment.
        let payModel = PayMethodModel.shared
        //let payModel = PayMethodModel()
        
        let catModel = CategoryModel()
        let keyModel = KeywordModel()
        let repModel = RepeatingTransactionModel()
        let eventModel = EventModel()
        
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
                @Bindable var appState = AppState.shared
                Group {
                    /// `AuthState.shared.isThinking` is always true when app launches from fresh state.
                    /// `AppState.shared.appShouldShowSplashScreen` is set to false in `downloadEverything()` when the current month completes.
                    if AuthState.shared.isThinking || AppState.shared.appShouldShowSplashScreen || !AppState.shared.splashTextAnimationIsFinished/* || AppState.shared.holdSplash */{
                        loadingScreen
                    } else {
                        if AuthState.shared.isLoggedIn {
                            if AppState.shared.hasBadConnection {
                                TempTransactionList()
                            } else {
                                rootView
                            }
                        } else {
                            if AppState.shared.hasBadConnection {
                                TempTransactionList()
                            } else {
                                Login()
                                    .transition(.opacity)
                                    .onAppear {
                                        if AuthState.shared.serverRevoked {
                                            serverRevokedAccess()
                                            AuthState.shared.serverRevoked = false
                                        }
                                    }
                            }
                        }
                    }
                }
                #if os(iOS)
                .fullScreenCover(isPresented: $appState.showPaymentMethodNeededSheet, onDismiss: { downloadInitial() }) {
                    PaymentMethodRequiredView()
                }
                #else
                .sheet(isPresented: $appState.showPaymentMethodNeededSheet, onDismiss: { downloadInitial() }) {
                    PaymentMethodRequiredView()
                        .padding()
                }
                #endif
                
                #if os(iOS)
                .onAppear {
                    let or = UIDevice.current.orientation
                    AppState.shared.orientation = or
                    if [.landscapeLeft, .landscapeRight].contains(or) || ([.faceUp, .faceDown].contains(or) && AppState.shared.isLandscape) {
                        AppState.shared.isLandscape = true
                    } else {
                        AppState.shared.isLandscape = false
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
                }
                #endif
            }
            .environment(funcModel)
            .environment(calModel)
            .environment(payModel)
            .environment(catModel)
            .environment(keyModel)
            .environment(repModel)
            .environment(eventModel)
            .environment(\.colorScheme, preferDarkMode ? .dark : .light)
            .preferredColorScheme(preferDarkMode ? .dark : .light)
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
                .task {
                    funcModel.setDeviceUUID()
                    
                    /// This will check the keychain for credentials. If it finds them, it will attempt to authenticate with the server. If not, it will take the user to the login page.
                    /// If the user successfully authenticates with the server, this will also look if the user has payment methods, and set AppState accordingly.
                    await AuthState.shared.checkForCredentials()
                    
                    if AuthState.shared.isLoggedIn {
                        /// When the user logs in, if they have no payment methods, show the payment method required sheet.
                        if AppState.shared.methsExist {
                            downloadInitial()
                        } else {
                            LoadingManager.shared.showInitiallyLoadingSpinner = false
                            LoadingManager.shared.showLoadingBar = false
                            AppState.shared.showPaymentMethodNeededSheet = true
                        }
                                                
                        NotificationManager.shared.registerForPushNotifications()
                    }
                }
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
    
    
    func serverRevokedAccess() {
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
        
    
    func downloadInitial() {
        @Bindable var navManager = NavigationManager.shared
        /// Set navigation destination to current month
        navManager.selection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
        navManager.navPath.append(NavDestination.getMonthFromInt(AppState.shared.todayMonth)!)
        LoadingManager.shared.showInitiallyLoadingSpinner = true
                    
        funcModel.refreshTask = Task {
            /// populate all months with their days.
            calModel.prepareMonths()
            if let selection = navManager.selection {
                /// set the calendar model to use the current month (ignore starting amounts and calculations)
                calModel.setSelectedMonthFromNavigation(navID: selection, prepareStartAmount: false)
                /// download everything, and populate the days in the respective months with transactions.
                await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaInitial)
            }
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





struct PaymentMethodRequiredView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FuncModel.self) private var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @State private var editPaymentMethod: CBPaymentMethod?
    @State private var paymentMethodEditID: CBPaymentMethod.ID?
    @State private var showLoadingSpinner = false
    
    var body: some View {
        VStack {
            Spacer()
            
            ContentUnavailableView("Let's Make it Rain", systemImage: "creditcard", description: Text("Get started by adding a payment method"))
            Spacer()
            
            if showLoadingSpinner {
                ProgressView {
                    Text("Saving…")
                }
            } else {
                Button("Add Payment Method") {
                    paymentMethodEditID = UUID().uuidString
                }
                .focusable(false)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .background(.green.gradient, in: .capsule)
                .buttonStyle(.plain)
                
                Button("Logout") {
                    AppState.shared.showPaymentMethodNeededSheet = false
                    funcModel.logout()
                }
                .focusable(false)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .background(.green.gradient, in: .capsule)
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $editPaymentMethod, onDismiss: {
            paymentMethodEditID = nil
        }, content: { meth in
            PayMethodView(payMethod: meth, payModel: payModel, editID: $paymentMethodEditID)
        })
        .onChange(of: paymentMethodEditID) { oldValue, newValue in
            if let newValue {
                let payMethod = payModel.getPaymentMethod(by: newValue)
                editPaymentMethod = payMethod
            } else {
                /// Slimmed down logic from `payModel.savePaymentMethod()`
                let payMethod = payModel.getPaymentMethod(by: oldValue!)
                if payMethod.title.isEmpty {
                    if payMethod.action != .add && payMethod.title.isEmpty {
                        payMethod.title = payMethod.deepCopy?.title ?? ""
                    }
                    return
                }
                                
                Task {
                    showLoadingSpinner = true
                    /// Save the newly created payment method to the server.
                    let _ = await payModel.submit(payMethod)
                    /// Fetch the newly added payment method, plus the 2 unified methods from the server.
                    await payModel.fetchPaymentMethods(calModel: calModel)
                    /// Allow entry into the normal app.
                    AppState.shared.methsExist = true
                    /// Close the sheet, which will kick off the normal download task.
                    dismiss()
                }
            }
        }
    }
}



struct RootViewWrapper<Content: View>: View {
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    var content: Content
    //var properties = UniversalOverProperties()
    #if os(iOS)
    @State private var window: UIWindow?
    #endif
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            //.environment(properties)
            #if os(iOS)
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, window == nil {
                    let window = PassThroughWindowPhone(windowScene: windowScene)
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    
                    let rootViewController = UIHostingController(rootView:
                        AlertAndToastLayerView()
                        .environment(funcModel)
                        .environment(calModel)
                        .environment(payModel)
                        .environment(catModel)
                        .environment(keyModel)
                    )
                    rootViewController.view.backgroundColor = .clear
                    
                    window.rootViewController = rootViewController
                    
                    //properties.window = window
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
            }
            #endif

    }
}
//
//@Observable
//class UniversalOverProperties {
//    var window: UIWindow?
//    var views: [OverlayView] = []
//    
//    struct OverlayView: Identifiable {
//        var id: String = UUID().uuidString
//        var view: AnyView
//    }
//}

struct AlertAndToastLayerView: View {
    @Environment(CalendarModel.self) private var calModel
    
    var body: some View {
        @Bindable var appState = AppState.shared
        @Bindable var calModel = calModel
        @Bindable var undoManager = UndodoManager.shared
        
        Group {
//            if appState.showAlert {
//                VStack {
//                    Text(AppState.shared.alertText)
//                    HStack {
//                        if let function = AppState.shared.alertFunction {
//                            Button(AppState.shared.alertButtonText) {
//                                appState.showAlert = false
//                                function()
//                            }
//                        }
//                        if let function = AppState.shared.alertFunction2 {
//                            Button(AppState.shared.alertButtonText2) {
//                                appState.showAlert = false
//                                function()
//                            }
//                        } else {
//                            Button("Close", action: {
//                                appState.showAlert = false
//                            })
//                        }
//                        
//                    }
//                }
//            }
        }
        .toast()
        
        .alert("Undo / Redo", isPresented: $undoManager.showAlert) {
            VStack {
                if UndodoManager.shared.canUndo {
                    Button {
                        if let old = UndodoManager.shared.undo() {
                            undoManager.returnMe = old
                        }
                    } label: {
                        Text("Undo")
                    }
                }
                
                if UndodoManager.shared.canRedo {
                    Button {
                        if let new = UndodoManager.shared.redo() {
                            undoManager.returnMe = new
                        }
                    } label: {
                        Text("Redo")
                    }
                }
                
                Button(role: .cancel) {
                } label: {
                    Text("Cancel")
                }
            }
        }
        
        
//        .sheet(isPresented: $calModel.showSmartTransactionPaymentMethodSheet) {
//            PaymentMethodSheet(
//                payMethod: Binding(get: { CBPaymentMethod() }, set: { calModel.pendingSmartTransaction!.payMethod = $0 }),
//                trans: calModel.pendingSmartTransaction,
//                calcAndSaveOnChange: true,
//                whichPaymentMethods: .allExceptUnified,
//                isPendingSmartTransaction: true
//            )
//        }
//        
//        
//        .sheet(isPresented: $calModel.showSmartTransactionDatePickerSheet, onDismiss: {
//            if calModel.pendingSmartTransaction!.date == nil {
//                calModel.pendingSmartTransaction!.date = Date()
//            }
//            
//            calModel.saveTransaction(id: calModel.pendingSmartTransaction!.id, location: .smartList)
//            calModel.tempTransactions.removeAll()
//            calModel.pendingSmartTransaction = nil
//        }, content: {
//            GeometryReader { geo in
//                ScrollView {
//                    VStack {
//                        SheetHeader(title: "Select Receipt Date", subtitle: calModel.pendingSmartTransaction!.title) {
//                            calModel.showSmartTransactionDatePickerSheet = false
//                        }
//                        
//                        Divider()
//                        
//                        DatePicker(selection: Binding($calModel.pendingSmartTransaction)!.date ?? Date(), displayedComponents: [.date]) {
//                            EmptyView()
//                        }
//                        .datePickerStyle(.graphical)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .labelsHidden()
//                       
//                        Spacer()
//                        Button("Done") {
//                            calModel.showSmartTransactionDatePickerSheet = false
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .padding(.bottom, 12)
//                    }
//                    .frame(minHeight: geo.size.height)
//                }
//                .padding([.top, .horizontal])
//            }
//            //.presentationDetents([.medium])
//        })
        
        
        //.opacity((AppState.shared.showAlert || AppState.shared.toast != nil) ? 1 : 0)
//        .alert(AppState.shared.alertText, isPresented: $appState.showAlert) {
//            if let function = AppState.shared.alertFunction {
//                Button(AppState.shared.alertButtonText ?? "", action: function)
//            }
//            if let function = AppState.shared.alertFunction2 {
//                Button(AppState.shared.alertButtonText2 ?? "", action: function)
//            } else {
//                Button("Close", action: {})
//            }
//        }
        .overlay {
            if let config = AppState.shared.alertConfig {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                    .ignoresSafeArea()
                    .overlay { CustomAlert(config: config) }
                    .opacity(appState.showCustomAlert ? 1 : 0)
                                        
            }
        }
    }
}



struct CustomAlert: View {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    
    let config: AlertConfig
    var body: some View {
        VStack {
            Image(systemName: config.symbol.name)
                .font(.title)
                .foregroundStyle(.primary)
                .frame(width: 65, height: 65)
                .background((config.symbol.color ?? .primary).gradient, in: .circle)
                .background {
                    Circle()
                        .stroke(.background, lineWidth: 8)
                }
            
            Group {
                Text(config.title)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                
                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .foregroundStyle(.gray)
                    //.padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 15)
                
            if !config.views.isEmpty {
                ForEach(config.views) { viewConfig in
                    Divider()
                    viewConfig.content
                }
            }
        
                                    
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 0) {
                    if let button = config.secondaryButton {
                        button
                        Divider()
                    } else {
                        AlertConfig.CancelButton()
                        Divider()
                    }
                    
                    if let button = config.primaryButton {
                        button
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        //.padding([.horizontal, .bottom], 15)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThickMaterial)
                .padding(.top, 30)
        }
        .frame(maxWidth: 310)
        .compositingGroup()
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



//class PassThroughWindowOG: UIWindow {
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        guard let hitView = super.hitTest(point, with: event), let rootView = rootViewController?.view else { return nil }
//        print(hitView)
//        
////        if #available(iOS 18, *) {
////            
////            // Need this to click the alerts
////            if let rootViewController, let presented = rootViewController.presentedViewController {
////                if presented.isKind(of: UIAlertController.self) {
////                    print("⚠️ is UIAlertController")
////                    return hitView
////                }
////            }
////            
//////            if let rootViewController, let presented = rootViewController.presentedViewController {
//////                if presented.isKind(of: UISheetPresentationController.self) {
//////                    print("⚠️ is UIPresentationController")
//////                    return hitView
//////                }
//////            }
////            
////            
////            /// Need this to click the toasts (but can't click the paymethod sheet(via smart trans) in the normal trans sheet
////            for subview in rootView.subviews.reversed() {
////                print(subview)
////                let pointInSubView = subview.convert(point, from: rootView)
////                if subview.hitTest(pointInSubView, with: event) == subview {
////                    return hitView
////                }
////            }
////            
////            return nil
////        } else {
////            return hitView == rootView ? nil : hitView
////        }
//        
//        //Alert works, toast does not, inner sheet does
//        return hitView == rootView ? nil : hitView
//    }
//}
//
//extension View {
//    @ViewBuilder func universalOverlay<Content: View>(animation: Animation = .snappy, show: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
//        self.modifier(UniversalOverlayModifier(animation: animation, show: show, viewContent: content))
//    }
//}
//
//
//struct UniversalOverlayModifier<ViewContent: View>: ViewModifier {
//    var animation: Animation
//    @Binding var show: Bool
//    @ViewBuilder var viewContent: ViewContent
//    
//    func body(content: Content) -> some View {
//        content
//    }
//}
//


//@main
//struct MakeItRainApp: App {
//    #if os(macOS)
//    @NSApplicationDelegateAdaptor(AppDelegateMac.self) var appDelegate
//    //@State private var windowDelegate = MyWindowDelegate()
//    #else
//    @UIApplicationDelegateAdaptor(AppDelegatePhone.self) var appDelegate
//    @Environment(\.scenePhase) var scenePhase
//    #endif
//    
//    @Environment(\.colorScheme) var colorScheme
//    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
//    @AppStorage("appScreenWidth") var screenWidth: Double = 0
//    @AppStorage("appScreenHeight") var screenHeight: Double = 0
//    @AppStorage("useBiometrics") var useBiometrics = false
//    @AppStorage("startInFullScreen") var startInFullScreen = false
//    
//    @State private var appState = AppState.shared
//    @State private var authState = AuthState.shared
//    @State private var funcModel: FuncModel
//    @State private var calModel: CalendarModel
//    @State private var payModel: PayMethodModel
//    @State private var catModel: CategoryModel
//    @State private var keyModel: KeywordModel
//    @State private var repModel: RepeatingTransactionModel
//    //@State private var tagModel = TagModel()
//    
//    let keychainManager = KeychainManager()
//    @State private var isUnlocked = false
//    
//    
//    init() {
//        let calModel = CalendarModel()
//        let payModel = PayMethodModel()
//        let catModel = CategoryModel()
//        let keyModel = KeywordModel()
//        let repModel = RepeatingTransactionModel()
//        
//        self.calModel = calModel
//        self.payModel = payModel
//        self.catModel = catModel
//        self.keyModel = keyModel
//        self.repModel = repModel
//        
//        self.funcModel = .init(calModel: calModel, payModel: payModel, catModel: catModel, keyModel: keyModel, repModel: repModel)
//    }
//        
//    var body: some Scene {
//        WindowGroup {
//            @Bindable var appState = AppState.shared
//            Group {
////                if useBiometrics && !AuthState.shared.isBioAuthed {
////                    Text("")
////                        .task {
////                            //AppState.shared.setDateToYesterday()
////                            funcModel.setDeviceUUID()
////                            funcModel.authenticate()
////                        }
////                } else {
//                    Group {
//                        if AuthState.shared.isThinking { /// always true when app launches from fresh state.
//                            loadingScreen
//                        } else {
//                            if AuthState.shared.isLoggedIn {
//                                rootView
//                            } else {
//                                if AppState.shared.hasBadConnection {
//                                    tempTransList
//                                } else {
//                                    Login()
//                                }
//                            }
//                        }
//                    }
//                //}
//            }
//            .environment(funcModel)
//            .environment(calModel)
//            .environment(payModel)
//            .environment(catModel)
//            .environment(keyModel)
//            .environment(repModel)
//            .environment(\.colorScheme, preferDarkMode ? .dark : .light)
//            .preferredColorScheme(preferDarkMode ? .dark : .light)
//            
//            #if os(iOS)
//            .onAppear {
//                let or = UIDevice.current.orientation
//                AppState.shared.orientation = or
//                if [.landscapeLeft, .landscapeRight].contains(or) || ([.faceUp, .faceDown].contains(or) && AppState.shared.isLandscape) {
//                    AppState.shared.isLandscape = true
//                } else {
//                    AppState.shared.isLandscape = false
//                }
//            }
//            .onRotate {
//                AppState.shared.orientation = $0
//                if [.landscapeLeft, .landscapeRight].contains($0) || ([.faceUp, .faceDown].contains($0) && AppState.shared.isLandscape) {
//                    AppState.shared.isLandscape = true
//                } else {
//                    AppState.shared.isLandscape = false
//                }
//            }
//            #endif
//        
//            /// Create the app delegate for Mac
//            #if os(macOS)
//            .background {
//                HostingWindowFinder { window in
//                    guard let window else { return }
//                    window.delegate = appDelegate
//                }
//            }
//        
//            /// Set fullscreen if the app preferences call for it
//            .onAppear {
//                if startInFullScreen {
//                    Task {
//                        await MainActor.run {
//                            AppState.shared.isInFullScreen = true
//                            if let window = NSApplication.shared.windows.last {
//                                window.toggleFullScreen(nil)
//                            }
//                        }
//                    }
//                }
//            }
//            #endif
//        
//            /// Univseral alert
//            .alert(AppState.shared.alertText, isPresented: $appState.showAlert) {
//                if let function = AppState.shared.alertFunction {
//                    Button(AppState.shared.alertButtonText) {
//                        function()
//                    }
//                }
//                
//                Button("Close") {}
//            }
//        }
//        .defaultSize(width: 1000, height: 600)
//        
//        #if os(macOS)
//        .windowStyle(.hiddenTitleBar)
//        .windowToolbarStyle(.unified)
//        .commands {
//            CommandGroup(replacing: .newItem, addition: { })
//            SidebarCommands()
//            TextFormattingCommands()
//            ToolbarCommands()
//        }
//        #endif
//        
//        #if os(macOS)
//        Settings {
//            SettingsView(showSettings: .constant(false))
//                .frame(maxWidth: 400, minHeight: 600)
//                .environment(funcModel)
//                .environment(calModel)
//                .environment(payModel)
//                .environment(catModel)
//                .environment(keyModel)
//                .environment(repModel)
//                //.environment(tagModel)
//        }
//        #endif
//        
//    }
//    
//    var loadingScreen: some View {
//        VStack {
//            ProgressView()
//                .tint(.none)
//            //Text("Authenticating…")
//            Text("Loading…")
//        }
//        #if os(iOS)
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .standardBackground()
//        #endif
//        .task {
//            funcModel.setDeviceUUID()
//            await funcModel.checkForCredentials()
////            do {
////                AuthState.shared.logout()
////                try keychainManager.removeFromKeychain()
////            } catch {
////                print(error.localizedDescription)
////            }
//        }
//        //ProgressView()
//    }
//    
//    var rootView: some View {
//        RootView()
//            .frame(idealWidth: screenWidth, idealHeight: screenHeight)
//        //.environment(tagModel)
//        //.toolbar(.hidden, for: .windowToolbar)
//            .onPreferenceChange(SizePreferenceKey.self) { value in
//                screenWidth = value.width
//                screenHeight = value.height
//            }
//    }
//    
//    var tempTransList: some View {
//        TempTransactionList()
//            #if os(iOS)
//            .onChange(of: scenePhase) { oldPhrase, newPhase in
//                if newPhase == .inactive {
//                    print("scenePhase: Inactive")
//                } else if newPhase == .active {
//                    print("scenePhase: Active")
//                    Task {
//                        //authState.isThinking = true
//                        await funcModel.checkForCredentials()
//                    }
//                } else if newPhase == .background {
//                    print("scenePhase: Background")
//                }
//            }
//            #else
//            // MARK: - Handling Lifecycles (Mac)
//            .onChange(of: AppState.shared.macWokeUp) { oldValue, newValue in
//                if newValue { Task { await funcModel.checkForCredentials() } }
//            }
//            .onChange(of: AppState.shared.macSlept) { oldValue, newValue in
//                if newValue { Task { await funcModel.checkForCredentials() } }
//            }
//            .onChange(of: AppState.shared.macWindowDidBecomeMain) { oldValue, newValue in
//                if newValue { Task { await funcModel.checkForCredentials() } }
//            }
//            #endif
//    }
//    
//}
