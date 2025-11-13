//
//  AppModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/25/24.
//

import Foundation
import SwiftUI

@Observable
class AppState {
    static let shared = AppState()
    var downloadedData: Array<NavDestination> = []
    var user: CBUser?
    var apiKey: String?
    var accountUsers: Array<CBUser> = []
    var methsExist = false
    var showPaymentMethodNeededSheet = false
    #if os(macOS)
    var isInFullScreen = false
    var macWindowDidBecomeMain = false
    var macSlept = false
    var macWokeUp = false
    var monthlySheetWindowTitle = ""
    #endif
    var longPollFailed = false
    var isLoggingInForFirstTime = false
    var hasBadConnection = false
    
    var deviceUUID: String?
    var notificationToken: String?
    
    //var keyboardHeight: CGFloat = 0
    //var showKeyboardToolbar = false
    
    var debugPrintString = UserDefaults.standard.string(forKey: "debugPrint") ?? "no debugPrint found"
    var debugPrint: Bool { return debugPrintString == "YES" ? true : false }
    
    let numberFormatter = NumberFormatter()
    let dateFormatter = DateFormatter()
    let colorMenuOptions: Array<Color> = [.pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .brown, /*.white, .black*/]
    
    #if os(iOS)
    var orientation: UIDeviceOrientation = UIDevice.current.orientation
    var isLandscape: Bool = false
    var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    var isIphone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    //var isIphoneInLandscape: Bool { UIDevice.current.userInterfaceIdiom == .phone && isLandscape }
    //var isIphoneInPortrait: Bool { UIDevice.current.userInterfaceIdiom == .phone && !isLandscape }
    #else
    var isIpad: Bool = false
    #endif

    //var holdSplash = true
    //var splashTimer = Timer.publish(every: 3, tolerance: 0.5, on: .main, in: .common).autoconnect()
    var appShouldShowSplashScreen: Bool = true
    var splashTextAnimationIsFinished: Bool = false
    
    var longNetworkTaskTimer: Timer?
    
    var lastNetworkTime: Date?
    
    var dragOnMonthTimer: Timer?
    var dragMonthTarget: NavDestination?
    
    func showDragTarget(for month: NavDestination) {
        self.dragMonthTarget = month
    }
    
    
    var openOrClosedRecords: Array<CBOpenOrClosedRecord> = []
    
    
    
    init() {
        if let ud = UserDefaults.standard.data(forKey: "user") {
            do {
                self.user = try JSONDecoder().decode(CBUser.self, from: ud)

            } catch {
                print("Unable to Decode User (\(error))")
            }
        }
    }
    
    
    func user(is user: CBUser?) -> Bool {
        if let user {
            return AppState.shared.user!.id == user.id
        } else {
            return false
        }
    }
    
    func user(isNot user: CBUser?) -> Bool {
        if let user {
            return AppState.shared.user!.id != user.id
        } else {
            return true
        }
    }
    
    
    func getUserBy(id: Int) -> CBUser? {
        return AppState.shared.accountUsers.filter {$0.id == id}.first
    }
    
    
    func hasBadConnection() async -> Bool {
        print("-- \(#function)")
        
        let model = RequestModel(requestType: "check_connection", model: CodablePlaceHolder())
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager(timeout: 10).singleRequest(requestModel: model)
        
        switch await result {
        case .success:
            AppState.shared.hasBadConnection = false
            return false
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.hasBadConnection = true
            AppState.shared.showAlert("Connection Problem")
            return true
        }
    }
    
    
    func checkIfDownloadingDataIsNeeded() async -> Bool {
        print("-- \(#function)")
        
        let model = RequestModel(requestType: "check_for_changes", model: CheckIfShouldDownloadModel(lastNetworkTime: AppState.shared.lastNetworkTime ?? Date()))
        typealias ResultResponse = Result<CheckIfShouldDownloadModel?, AppError>
        async let result: ResultResponse = await NetworkManager(timeout: 10).singleRequest(requestModel: model, retainTime: false)
        
        switch await result {
        case .success(let model):
            if let model = model {
                return model.shouldDownload
            } else {
                return true
            }
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            return true
        }
    }
    
    
    
    
    
    func alertBasedOnScenePhase(
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        symbol: String = "exclamationmark.triangle",
        symbolColor: Color? = .orange,
        inAppPreference: InAppAlertPreference = .toast
    ) {
        #if os(iOS)
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            NotificationManager.shared.sendNotification(title: title, subtitle: subtitle, body: body)
        } else {
            switch inAppPreference {
            case .alert:
                //showAlert(title)
                
                let alertConfig = AlertConfig(title: title, subtitle: subtitle, symbol: .init(name: symbol, color: symbolColor))
                showAlert(config: alertConfig)
                
            case .toast:
                showToast(title: title, subtitle: subtitle, body: body, symbol: symbol, symbolColor: symbolColor)
            }
        }
        #else
        switch inAppPreference {
        case .alert:
            showAlert(title)
        case .toast:
            showToast(title: title, subtitle: subtitle, body: body, symbol: symbol, symbolColor: symbolColor)
        }
        #endif
    }
    
    
    var toast: Toast?
    func showToast(
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        symbol: String = "coloncurrencysign.circle",
        symbolColor: Color? = nil,
        autoDismiss: Bool = true,
        action: @escaping () -> Void = {}
    ) {
        withAnimation(.bouncy) {
            //DispatchQueue.main.async {
            Helpers.buzzPhone(.success)
            self.toast = Toast(header: title, title: subtitle, message: body, symbol: symbol, symbolColor: symbolColor, autoDismiss: autoDismiss, action: action)
            //}
        }
        
        let context = DataManager.shared.container.viewContext
        let id = UUID().uuidString
        if let perToast = DataManager.shared.getOne(context: context, type: PersistentToast.self, predicate: .byId(.string(id)), createIfNotFound: true) {
            perToast.id = id
            perToast.title = title
            perToast.subtitle = subtitle ?? ""
            perToast.body = body ?? ""
            perToast.symbol = symbol
            perToast.hexCode = symbolColor?.toHex() ?? ""
            perToast.enteredDate = Date()
            print(perToast)
            let saveResult = DataManager.shared.save(context: context)
            print(saveResult)
        } else {
            print("no per toast")
        }
        
    }
    
        
    // MARK: - Current Date Stuff
    var currentDateTimer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
    var todayDay = Calendar.current.component(.day, from: Date())
    var todayMonth = Calendar.current.component(.month, from: Date())
    var todayYear = Calendar.current.component(.year, from: Date())
    
//    func isToday(date: Date?) -> Bool {
//        if let date {
//            return
//                date.day == AppState.shared.todayDay
//                && date.month == AppState.shared.todayMonth
//                && date.year == AppState.shared.todayYear
//        } else {
//            return false
//        }
//        
//    }
    

    /// Called via `currentDateTimer`. The onReceive() modifier that calls this is in ``CalendarViewPhone``.
    func setNow() -> Bool {
        let oldToday = todayDay
        let newToday = Calendar.current.component(.day, from: Date())
                        
        if newToday != oldToday {
            todayDay = newToday
            todayMonth = Calendar.current.component(.month, from: Date())
            todayYear = Calendar.current.component(.year, from: Date())
            return true
        } else {
            return false
        }
    }
    
    /// Called when the iPhone enters the forground or when the Mac unlocks.
    func startNewNowTimer() {
        self.currentDateTimer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
    }
    
    /// Called when the iPhone enters background or when the Mac locks.
    func cancelNowTimer() {
        self.currentDateTimer.upstream.connect().cancel()
    }
               
    
    // MARK: - Alert Stuff
//    var showAlert: Bool = false
//    var alertText: String = ""
//    var alertButtonText: String? = nil
//    var alertFunction: (() -> Void)?
//    var alertButtonText2: String? = nil
//    var alertFunction2: (() -> Void)?
//    func showAlert(_ text: String) {
//        resetAlert()
//        self.showAlert = true
//        self.alertText = text
//    }
//    func showAlert(_ text: String, buttonText: String, _ function: @escaping () -> Void) {
//        resetAlert()
//        self.showAlert = true
//        self.alertText = text
//        self.alertButtonText = buttonText
//        self.alertFunction = function
//    }
//    
//    func showAlert(
//        _ text: String,
//        buttonText1: String? = nil,
//        buttonFunction1: (() -> Void)? = nil,
//        buttonText2: String? = nil,
//        buttonFunction2: (() -> Void)? = nil
//    ) {
//        resetAlert()
//        self.showAlert = true
//        self.alertText = text
//        self.alertButtonText = buttonText1
//        self.alertFunction = buttonFunction1
//        self.alertButtonText2 = buttonText2
//        self.alertFunction2 = buttonFunction2
//    }
//    
//    func resetAlert() {
//        alertText = ""
//        alertButtonText = ""
//        alertFunction = nil
//    }
    
    
    func showAlert(_ text: String) {
        //withAnimation(.snappy(duration: 0.2)) {
            let config = AlertConfig(title: text)
            self.alertConfig = config
            self.showCustomAlert = true
        //}
    }
    
    func showAlert(title: String, subtitle: String) {
        //withAnimation(.snappy(duration: 0.2)) {
            let config = AlertConfig(title: title, subtitle: subtitle)
            self.alertConfig = config
            self.showCustomAlert = true
        //}
    }
    
    
    var showCustomAlert: Bool = false
    var alertConfig: AlertConfig?
    func showAlert(config: AlertConfig) {
        //withAnimation(.snappy(duration: 0.2)) {
            self.alertConfig = config
            self.showCustomAlert = true
        //}
    }
    
    func closeAlert() {
        //withAnimation {
            self.alertConfig = nil
            self.showCustomAlert = true
        //}
    }
    
    
    #if os(iOS)
    func beginBackgroundTask() -> UIBackgroundTaskIdentifier? {
        var backgroundTaskID: UIBackgroundTaskIdentifier?
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "markEvent") {
            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            backgroundTaskID = .invalid
        }
        return backgroundTaskID
    }
    
    func endBackgroundTask(_ backgroundTaskID: inout UIBackgroundTaskIdentifier) {
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
    #endif
}

