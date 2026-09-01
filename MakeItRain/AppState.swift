//
//  AppModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/25/24.
//

import Foundation
import SwiftUI
internal import Combine

@Observable
class AppState {
    static let shared = AppState()
    //month.hasLoadedFromServer = falsevar downloadedMonths: Array<NavDest> = []
    var user: CBUser?
    var avatar: Data?
    var apiKey: String?
    var openAiKey: String?
    var accountUsers: Array<CBUser> = []
    var methsExist = false
    var showPaymentMethodNeededSheet = false
    var notificationsAreAllowed = false
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
    var country: Country = Countries.fetch(by: 225)!
    
    var deviceUUID: String?
    var notificationToken: String?
    var unreadToasts: Array<String> = []
    
    @ObservationIgnored
    @Environment(\.openWindow) var openWindow
    
    @ObservationIgnored
    @Environment(\.dismissWindow) var dismissWindow

    
    //var keyboardHeight: CGFloat = 0
    //var showKeyboardToolbar = false
    
    var debugPrintString = UserDefaults.standard.string(forKey: "debugPrint") ?? "no debugPrint found"
    var debugPrint: Bool { return debugPrintString == "YES" ? true : false }
    var devMode: Bool = UserDefaults.standard.bool(forKey: "devMode")
        
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
    
    var isAwayFromHomeCountry: Bool {
        if LocationManager.shared.currentCountry != nil {
            return LocationManager.shared.currentCountry != country.code
        } else {
            return false
        }
        
    }

    //var holdSplash = true
    //var splashTimer = Timer.publish(every: 3, tolerance: 0.5, on: .main, in: .common).autoconnect()
    var shouldShowSplash: Bool = true
    var splashIsAnimating: Bool = true
    
    var longNetworkTaskTimer: Timer?
    
    var lastNetworkTime: Date?
    
    var dragOnMonthTimer: Timer?
    var dragMonthTarget: NavDest?
    
    var showCustomAlert: Bool = false
    var alertConfig: AlertConfig?
    var toast: Toast?
    
    func showDragTarget(for month: NavDest) {
        self.dragMonthTarget = month
    }
        
    var openOrClosedRecords: Array<CBOpenOrClosedRecord> = []
        
    //var shouldWarmUpTransactionViewDuringSplash = false
    
    /// For Sqlite
//    var fromServerDateFormatter: DateFormatter {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = getDateFormat(.serverDateTime)
//        dateFormatter.timeZone = .none
//        return dateFormatter
//    }
    /// For Postgres
    var fromServerDateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        return formatter
    }
    
    let numberFormatter = NumberFormatter()
    let dateFormatter = DateFormatter()
          
    
    init() {
        if let ud = UserDefaults(suiteName: "group.dev.cburnett837.MakeItRain")?.data(forKey: "user") {
            do {
                self.user = try JSONDecoder().decode(CBUser.self, from: ud)
            } catch {
                print("Unable to Decode User (\(error))")
            }
        }
    }
    
    
    func user(is user: CBUser?) -> Bool {
        guard let user, let cody = AppState.shared.user else { return false }
        return cody.id == user.id
    }
    
    
    func user(isNot user: CBUser?) -> Bool {
        guard let user, let cody = AppState.shared.user else { return false }
        return cody.id != user.id
    }
    
    
    func getUserBy(id: Int) -> CBUser? {
        return AppState.shared.accountUsers.first { $0.id == id }
    }
    
    
//    func hasBadConnection() async -> Bool {
//        //print("-- \(#function)")
//        
//        let model = RequestModel(requestType: "check_connection", model: CodablePlaceHolder())
//        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
//        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model, timeout: 10)
//        
//        switch await result {
//        case .success:
//            AppState.shared.hasBadConnection = false
//            return false
//            
//        case .failure(let error):
//            LogManager.error(error.localizedDescription)
//            AppState.shared.hasBadConnection = true
//            AppState.shared.showAlert("Connection Problem")
//            return true
//        }
//    }
    
    
//    func checkIfDownloadingDataIsNeeded() async -> Bool {
//        print("-- \(#function)")
//        
//        
//        let model = RequestModel(requestType: "check_for_changes", model: CheckIfShouldDownloadModel(lastNetworkTime: AppState.shared.lastNetworkTime ?? Date()))
//        typealias ResultResponse = Result<CheckIfShouldDownloadModel?, AppError>
//        async let result: ResultResponse = await NetworkManager(timeout: 10).singleRequest(requestModel: model, retainTime: false)
//        
//        switch await result {
//        case .success(let model):
//            if let model = model {
//                return model.shouldDownload
//            } else {
//                return true
//            }
//            
//        case .failure(let error):
//            LogManager.error(error.localizedDescription)
//            return true
//        }
//    }
    
    
    // MARK: - Current Date Stuff
//    var currentDateTimer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
//    var todayDay = Calendar.current.component(.day, from: Date())
//    var todayMonth = Calendar.current.component(.month, from: Date())
//    var todayYear = Calendar.current.component(.year, from: Date())
//
//    /// Called via `currentDateTimer`. The onReceive() modifier that calls this is in ``CalendarViewPhone``.
//    func setNow() -> Bool {
//        let oldToday = todayDay
//        let newToday = Calendar.current.component(.day, from: Date())
//                        
//        if newToday != oldToday {
//            todayDay = newToday
//            todayMonth = Calendar.current.component(.month, from: Date())
//            todayYear = Calendar.current.component(.year, from: Date())
//            return true
//        } else {
//            return false
//        }
//    }
//    
//    /// Called when the iPhone enters the forground or when the Mac unlocks.
//    func startNewNowTimer() {
//        self.currentDateTimer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
//    }
//    
//    /// Called when the iPhone enters background or when the Mac locks.
//    func cancelNowTimer() {
//        self.currentDateTimer.upstream.connect().cancel()
//    }
    
    
    /// Attempt 2
//    var currentDateTimer: Timer?
//    var todayDay = Calendar.current.component(.day, from: Date())
//    var todayMonth = Calendar.current.component(.month, from: Date())
//    var todayYear = Calendar.current.component(.year, from: Date())
//
//
//    /// Updates the stored current date.
//    func setNow() {
//        let now = Date()
//        todayDay = Calendar.current.component(.day, from: now)
//        todayMonth = Calendar.current.component(.month, from: now)
//        todayYear = Calendar.current.component(.year, from: now)
//    }
//
//
//    /// Called when the iPhone enters the foreground
//    /// or when the Mac unlocks.
//    func startNewNowTimer() {
//        currentDateTimer?.invalidate()
//
//        /// Immediately make sure the date is correct.
//        setNow()
//
//        let calendar = Calendar.current
//
//        guard let nextMidnight = calendar.nextDate(
//            after: Date(),
//            matching: DateComponents(hour: 0, minute: 0, second: 0),
//            matchingPolicy: .nextTime
//        ) else {
//            return
//        }
//
//        currentDateTimer = Timer(fire: nextMidnight, interval: 0, repeats: false) { [weak self] _ in
//            guard let self else { return }
//
//            self.setNow()
//
//            /// Schedule tomorrow's midnight.
//            self.startNewNowTimer()
//        }
//
//        if let currentDateTimer {
//            RunLoop.main.add(currentDateTimer, forMode: .common)
//        }
//    }
//
//
//    /// Called when the iPhone enters the background
//    /// or when the Mac locks.
//    func cancelNowTimer() {
//        currentDateTimer?.invalidate()
//        currentDateTimer = nil
//    }
    
    
    /// Attempt 3
    @ObservationIgnored
    private var midnightTimer: Timer?
    
    var today = Calendar.current.startOfDay(for: Date())
    var todayDay = Calendar.current.component(.day, from: Date())
    var todayMonth = Calendar.current.component(.month, from: Date())
    var todayYear = Calendar.current.component(.year, from: Date())
    
    @discardableResult
    func setNow() -> Bool {
        let newToday = Calendar.current.startOfDay(for: Date())
        
        guard newToday != today else { return false }
        
        today = newToday
        todayDay = Calendar.current.component(.day, from: newToday)
        todayMonth = Calendar.current.component(.month, from: newToday)
        todayYear = Calendar.current.component(.year, from: newToday)
        
        return true
    }
    
    /// Called when the iPhone enters the foreground
    /// or when the Mac unlocks.
    func startNewNowTimer() {
        midnightTimer?.invalidate()
        
        /// Catch up immediately when returning to the foreground.
        setNow()
        
        guard let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else { return }
        
        midnightTimer = Timer(fire: nextMidnight, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.setNow()
                self.startNewNowTimer()
            }
        }
        
        if let midnightTimer {
            RunLoop.main.add(midnightTimer, forMode: .common)
        }
    }
    
    /// Called when the iPhone enters the background
    /// or when the Mac locks.
    func cancelNowTimer() {
        midnightTimer?.invalidate()
        midnightTimer = nil
    }
    
    
    
    
    // MARK: - Background Task Stuff
    #if os(iOS)
    func beginBackgroundTask() -> UIBackgroundTaskIdentifier {
        var taskId: UIBackgroundTaskIdentifier?
        taskId = UIApplication.shared.beginBackgroundTask(withName: UUID().uuidString) {
            if let theId = taskId {
                UIApplication.shared.endBackgroundTask(theId)
                taskId = .invalid
            }
            
        }
        return taskId!
    }
    
    func endBackgroundTask(_ taskId: inout UIBackgroundTaskIdentifier) {
        UIApplication.shared.endBackgroundTask(taskId)
        taskId = .invalid
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
    
    
    
    #if os(macOS)
    func openMacAlertAndToastOverlayWindow(withDarkOverlay: Bool = false) {
        Task {
            await MainActor.run {
                guard let mainWindow = NSApplication.shared.windows.first(where: {$0.identifier?.rawValue == "mainWindow"}) else {
                    print("cant find main window")
                    return
                }
                // configure the window in `onAppear` after calling openWindow will not work (completely)
                // some of the properties set will not be reflected.
                guard let window = NSApplication.shared.windows.first(where: {$0.identifier?.rawValue == MacAlertAndToastOverlay.id}) else {
                    return
                }
                
                print("window found")
                window.level = .floating // popUpMenu will also work
                
                window.contentMinSize = mainWindow.frame.size
                window.contentMaxSize = mainWindow.frame.size
                window.setFrame(mainWindow.frame, display: true, animate: false)
                
                // remove title and buttons
                window.styleMask.remove(.titled)
                window.styleMask = [.borderless]
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                window.hidesOnDeactivate = true
                //window.isReleasedWhenClosed = false
                
                // so that the window can follow the virtual desktop
                window.collectionBehavior.insert(.canJoinAllSpaces)
                
                // set it clear here so the configuration in UtilityWindowView will be reflected as it is
                if withDarkOverlay {
                    window.backgroundColor = NSColor.black.withAlphaComponent(0.3)
                } else {
                    window.backgroundColor = .clear
                }
                openWindow(id: MacAlertAndToastOverlay.id)
            }
        }
        
    }
    #endif
}

