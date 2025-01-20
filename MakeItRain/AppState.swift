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
    var methsExist = false
    var showPaymentMethodNeededSheet = false
    
    var isInFullScreen = false
    var macWindowDidBecomeMain = false
    var macSlept = false
    var macWokeUp = false    
    var longPollFailed = false
    
    var isLoggingInForFirstTime = false
    var hasBadConnection = false
    
    var deviceUUID: String?
    
    var keyboardHeight: CGFloat = 0
    var showKeyboardToolbar = false
    
    var debugPrintString = UserDefaults.standard.string(forKey: "debugPrint") ?? "no debugPrint found"
    var debugPrint: Bool { return debugPrintString == "YES" ? true : false }
    
    let numberFormatter = NumberFormatter()
    let dateFormatter = DateFormatter()
    let colorMenuOptions: Array<Color> = [.pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .brown, /*.white, .black*/]
    
    #if os(iOS)
    var orientation: UIDeviceOrientation = UIDevice.current.orientation
    var isLandscape: Bool = false
    #endif

    var holdSplash = true
    //var splashTimer = Timer.publish(every: 3, tolerance: 0.5, on: .main, in: .common).autoconnect()
    var appIsReadyToHideSplashScreen: Bool = false
    
    
    var toast: Toast?
    func showToast(header: String, title: String, message: String, symbol: String, symbolColor: Color? = nil) {
        withAnimation(.bouncy) {
            toast = Toast(header: header, title: title, message: message, symbol: symbol, symbolColor: symbolColor)
        }
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
    
        
    // MARK: - Current Date Stuff
    var currentDateTimer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
    var todayDay = Calendar.current.component(.day, from: Date())
    var todayMonth = Calendar.current.component(.month, from: Date())
    var todayYear = Calendar.current.component(.year, from: Date())

    /// Called via `currentDateTimer`. The onReceive() modifier that calls this is in ``RootView``.
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
        
        return false
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
    var showAlert: Bool = false
    var alertText: String = ""
    var alertButtonText: String = ""
    var alertFunction: (() -> Void)?
    var alertButtonText2: String = ""
    var alertFunction2: (() -> Void)?
    
    func showAlert(_ text: String) {
        resetAlert()
        self.showAlert = true
        self.alertText = text
    }
    
    func showAlert(_ text: String, buttonText: String, _ function: @escaping () -> Void) {
        resetAlert()
        self.showAlert = true
        self.alertText = text
        self.alertButtonText = buttonText
        self.alertFunction = function
    }
    
    
    func showAlert(_ text: String, buttonText1: String, buttonFunction1: @escaping () -> Void, buttonText2: String, buttonFunction2: @escaping () -> Void) {
        resetAlert()
        self.showAlert = true
        self.alertText = text
        self.alertButtonText = buttonText1
        self.alertFunction = buttonFunction1
        self.alertButtonText2 = buttonText2
        self.alertFunction2 = buttonFunction2
    }
    
    func resetAlert() {
        alertText = ""
        alertButtonText = ""
        alertFunction = nil
    }
    
    
    
    
    
    
    func hasBadConnection() async -> Bool {
        print("-- \(#function)")
        
        let model = RequestModel(requestType: "check_connection", model: CodablePlaceHolder())
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager(timeout: 3).singleRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            AppState.shared.hasBadConnection = false
            return false
            break
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.hasBadConnection = true
            AppState.shared.showAlert("Connection Problem")
            return true
        }
    }
    
    
}
