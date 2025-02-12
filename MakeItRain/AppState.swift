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
    var accountUsers: Array<CBUser> = []
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
    
    func user(is user: CBUser?) -> Bool {
        if let user {
            return AppState.shared.user!.id == user.id
        } else {
            return false
        }
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
    func showToast(title: String, subtitle: String?, body: String?, symbol: String, symbolColor: Color? = nil) {
        withAnimation(.bouncy) {
            //DispatchQueue.main.async {
                self.toast = Toast(header: title, title: subtitle, message: body, symbol: symbol, symbolColor: symbolColor)
            //}
            
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
        withAnimation(.snappy) {
            let config = AlertConfig(title: text)
            self.alertConfig = config
            self.showCustomAlert = true
        }
    }
    
    var showCustomAlert: Bool = false
    var alertConfig: AlertConfig?
    func showAlert(config: AlertConfig) {
        withAnimation {
            self.alertConfig = config
            self.showCustomAlert = true
        }
    }
    
    func closeAlert() {
        withAnimation {
            self.alertConfig = nil
            self.showCustomAlert = true
        }
    }
}

struct AlertConfig {
    var title: String
    var subtitle: String?
    var symbol: SymbolConfig = .init(name: "exclamationmark.triangle.fill", color: .orange)
    var primaryButton: AlertButton?
    var secondaryButton: AlertButton?
    var views: [ViewConfig] = []
    
    
    
    struct SymbolConfig {
        var name: String
        var color: Color? = .primary
    }
    
    struct ViewConfig: Identifiable {
        var id: UUID = UUID()
        var content: AnyView
    }
    
    struct ButtonConfig: Identifiable {
        var id: UUID = UUID()
        var text: String
        var role: AlertConfig.ButtonRole? = nil
        var function: () -> Void
        var color: Color {
            switch role {
            case .cancel, .primary, .some(.none), nil:
                .primary
            case .destructive:
                .red
            }
        }
        var edge: Edge = .trailing
    }
    
    enum ButtonRole {
        case cancel, destructive, primary, none
    }
    
    
    struct AlertButton: View {
        @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
        var config: ButtonConfig
        
        var body: some View {
            Button {
                AppState.shared.closeAlert()
                config.function()
            } label: {
                Text(config.text)
                    .fontWeight(config.role == .primary ? .bold : .regular)
                    .foregroundStyle(config.role == .destructive ? .red : (preferDarkMode ? .white : .black))
                    //.padding(.vertical, 14)
                    //.frame(maxWidth: .infinity)
                    //.background(config.color/*.gradient*/, in: .rect(cornerRadius: 10))
            }
            .buttonStyle(.codyAlert)
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: config.edge == .trailing ? 0 : 15,
                    bottomTrailingRadius: config.edge == .trailing ? 15 : 0,
                    topTrailingRadius: 0
                )
            )
        }
        
    }
    
    struct CancelButton: View {
        @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
        
        var body: some View {
            Button {
                AppState.shared.closeAlert()
            } label: {
                Text("Cancel")
            }
            .buttonStyle(.codyAlert)
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 15,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )
        }
    }
}
