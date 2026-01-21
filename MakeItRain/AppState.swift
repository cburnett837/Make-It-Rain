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
    //month.hasLoadedFromServer = falsevar downloadedMonths: Array<NavDestination> = []
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
    var unreadToasts: Array<String> = []
    
    //var keyboardHeight: CGFloat = 0
    //var showKeyboardToolbar = false
    
    var debugPrintString = UserDefaults.standard.string(forKey: "debugPrint") ?? "no debugPrint found"
    var debugPrint: Bool { return debugPrintString == "YES" ? true : false }
    
    let numberFormatter = NumberFormatter()
    let dateFormatter = DateFormatter()
    let colorMenuOptions: Array<Color> = [.pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .brown, /*.white, .black*/]
    
    #if os(iOS)
    var scenePhase: ScenePhase = .active
    var orientation: UIDeviceOrientation = UIDevice.current.orientation
    var isLandscape: Bool = false
    var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    var isIphone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    //var isIphoneInLandscape: Bool { UIDevice.current.userInterfaceIdiom == .phone && isLandscape }
    //var isIphoneInPortrait: Bool { UIDevice.current.userInterfaceIdiom == .phone && !isLandscape }
    #else
    var isIpad: Bool = false
    var isIphone: Bool = false
    #endif

    //var holdSplash = true
    //var splashTimer = Timer.publish(every: 3, tolerance: 0.5, on: .main, in: .common).autoconnect()
    var shouldShowSplash: Bool = true
    var splashIsAnimating: Bool = true
    
    var longNetworkTaskTimer: Timer?
    
    var lastNetworkTime: Date?
    
    var dragOnMonthTimer: Timer?
    var dragMonthTarget: NavDestination?
    
    var showCustomAlert: Bool = false
    var alertConfig: AlertConfig?
    var toast: Toast?
    
    func showDragTarget(for month: NavDestination) {
        self.dragMonthTarget = month
    }
        
    var openOrClosedRecords: Array<CBOpenOrClosedRecord> = []
        
    //var shouldWarmUpTransactionViewDuringSplash = false
    
    var fromServerDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = getDateFormat(.serverDateTime)
        dateFormatter.timeZone = .none
        return dateFormatter
    }
          
    
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
        //print("-- \(#function)")
        
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
    
    
    // MARK: - Current Date Stuff
    var currentDateTimer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
    var todayDay = Calendar.current.component(.day, from: Date())
    var todayMonth = Calendar.current.component(.month, from: Date())
    var todayYear = Calendar.current.component(.year, from: Date())

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
               

    #if os(iOS)
    func beginBackgroundTask() -> UIBackgroundTaskIdentifier {
        var backgroundTaskID: UIBackgroundTaskIdentifier?
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: UUID().uuidString) {
            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            backgroundTaskID = .invalid
        }
        return backgroundTaskID!
    }
    
    func endBackgroundTask(_ backgroundTaskID: inout UIBackgroundTaskIdentifier) {
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
    #endif
    
//    #if os(macOS)
//    var activityAssertion: NSObjectProtocol?
//
//    func startLongRunningTask() {
//        activityAssertion = ProcessInfo.processInfo.performExpiringActivity(withReason: "Performing important background work") { expired in
//            if expired {
//                print("Background activity expired. Cleaning up.")
//                // Handle cleanup or cancellation if the task couldn't complete in time
//            } else {
//                print("Background activity started.")
//                // Perform your long-running task here
//                // ...
//                // When the task is complete, invalidate the activity
//                self.endLongRunningTask()
//            }
//        }
//    }
//
//    func endLongRunningTask() {
//        if let assertion = activityAssertion {
//            ProcessInfo.processInfo.endActivity(assertion)
//            activityAssertion = nil
//            print("Background activity ended.")
//        }
//    }
//    #endif
}

