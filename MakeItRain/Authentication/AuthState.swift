//
//  AuthenticationManager.swift
//  wittwer_connect_v1_021221
//
//  Created by Cody Burnett on 2/12/21.
//

import Foundation
import SwiftUI
import CryptoKit


enum LoginType {
    case apiKey, emailAndPassword
}

@MainActor
@Observable
class AuthState {
    var isLoggedIn = false
    //var isBioAuthed = false
    var isThinking = true
    var isAdmin = false
    var error: AppError?
    
    var serverRevoked = false
    
    static let shared: AuthState = AuthState()
    
    let networkManager = NetworkManager()
    let keychainManager = KeychainManager()
    
    var loginTask: Task<Void, Error>?

    
    /// This will take the stored credentials, and send them to the server for authentication.
    /// The server will send back a ``CBUser`` object. That object will contain the user information, as well as a flag that indicates if we need to force the user to the payment method screen.
    @MainActor
    func getApiKeyFromKeychain() async -> String? {
        do {
            if let apiKey = try keychainManager.getFromKeychain(key: "user_api_key") {
                return apiKey
            } else {
                return nil
            }
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    
    func attemptLogin(using loginType: LoginType, with loginModel: LoginModel) async {
        //print("-- \(#function)")
        
        //error = nil
        self.error = nil
        //self.isLoggedIn = false
        //self.isThinking = true
        
        typealias ResultResponse = Result<CBLogin?, AppError>
        
        /// Set the ticker to 0 so it doesn't try and reattempt.
        /// This will try to login once with a 15 second timeout before it says screw it.
        async let result: ResultResponse = await NetworkManager(timeout: 15).login(using: loginType, with: loginModel, ticker: 0)
        
        switch await result {
        case .success(let model):
            do {
                if let model = model {
                    //try keychainManager.addToKeychain(key: "user_email", value: email)
                    //try keychainManager.addToKeychain(key: "user_password", value: password)
                    if let apiKey = model.apiKey {
                        try keychainManager.addToKeychain(key: "user_api_key", value: apiKey)
                        AppState.shared.apiKey = apiKey
                        
                        let userData = try JSONEncoder().encode(model.user)
                        UserDefaults.standard.set(userData, forKey: "user")
                        AppState.shared.user = model.user
                        AppState.shared.accountUsers = model.accountUsers
                        AppState.shared.methsExist = model.hasPaymentMethodsExisiting
                        AppState.shared.isLoggingInForFirstTime = true
                        AppState.shared.hasBadConnection = false
                        
                        AppState.shared.splashIsAnimating = true
                        withAnimation {
                            AppState.shared.shouldShowSplash = true
                        }
                                            
                        self.isLoggedIn = true
                        self.isThinking = false                        
                        //self.isBioAuthed = true
                    } else {
                        self.isLoggedIn = false
                        self.isThinking = false
                        //self.isBioAuthed = false
                        AppState.shared.shouldShowSplash = false
                        clearLoginState()
                        AppState.shared.showAlert("Problem getting api key from the server.")
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            
            self.error = error
            self.isLoggedIn = false
            self.isThinking = false
            //self.isBioAuthed = false
            AppState.shared.shouldShowSplash = false
            
            switch error {
            case .incorrectCredentials, .accessRevoked:
                clearLoginState()
                
            case .taskCancelled:
                AppState.shared.hasBadConnection = true
                
            default:
                AppState.shared.hasBadConnection = true
                AppState.shared.showAlert("Connection Problem")
            }
        }
    }
    
    
    func clearLoginState() {
        withAnimation {
            self.isLoggedIn = false
        }        
        do {
            try keychainManager.removeFromKeychain(key: "user_api_key")
            AppState.shared.apiKey = nil
            UserDefaults.standard.set(nil, forKey: "user")
        } catch {
            print(error.localizedDescription)
        }
    }
        
    
    func serverAccessRevoked() {
        /// This is called via ``NetworkManager``.
        /// This calls `clearLoginState()`, which causes the if block in ``MakeItRainApp`` to switch to ``LoginView``.
        /// On Appear of ``LoginView``,  `serverRevoked` being set will cause `funcModel.logout()` to run and force the user out.
        serverRevoked = true
        clearLoginState()
    }
    
    
//    func loginViaKeychain(funcModel: FuncModel) async {
//        print("-- \(#function)")
//        /// This will check the keychain for credentials. If it finds them, it will attempt to authenticate with the server. If not, it will take the user to the login page.
//        /// If the user successfully authenticates with the server, this will also look if the user has payment methods, and set AppState accordingly.
//        if let apiKey = await self.getApiKeyFromKeychain() {
//            self.loginTask = Task {
//                /// Talk to server with the users API key.
//                await self.attemptLogin(using: .apiKey, with: LoginModel(apiKey: apiKey))
//                
//                /// This will get set via `attemptLogin()`
//                if self.isLoggedIn {
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
//            self.isThinking = false
//            AppState.shared.shouldShowSplash = false
//        }
//    }
    
    
    
    func loginViaKeychain() async -> Bool {
        //print("-- \(#function)")
        /// This will check the keychain for credentials. If it finds them, it will attempt to authenticate with the server. If not, it will take the user to the login page.
        /// If the user successfully authenticates with the server, this will also look if the user has payment methods, and set AppState accordingly.
        if let apiKey = await self.getApiKeyFromKeychain() {
            self.loginTask = Task {
                /// Talk to server with the users API key.
                await self.attemptLogin(using: .apiKey, with: LoginModel(apiKey: apiKey))
                
                /// This will get set via `self.attemptLogin()`
                if self.isLoggedIn {
                    /// When the user logs in, if they have no payment methods, show the payment method required sheet.
                    if !AppState.shared.methsExist {
                        AppState.shared.showPaymentMethodNeededSheet = true
                    }
                    //await NotificationManager.shared.registerForPushNotifications()
                }
            }
            
            /// This is only here to keep this function from returning until the login task is complete.
            /// I need this to wait because the next step in the calling function, (which is `.task{}` in ``MakeItRainApp`` `splashScreen`), is to call `funcModel.downloadInitial()`.
            /// But only if the login succeeds.
            _ = await self.loginTask?.result
            return self.isLoggedIn
        } else {
            self.isThinking = false
            AppState.shared.shouldShowSplash = false
            return false
        }
    }
    
    
    
//    func verifyHS256JWT(jwt: String) -> Bool {
//        do {
//            let credentials = try keychainManager.getCredentialsFromKeychain()
//                
//            if let password = credentials.1 {
//                let secret = "\(password)theWinnerTakesItAll"
//                
//                let components = jwt.split(separator: ".")
//                guard components.count == 3 else { return false }
//
//                let headerAndPayload = "\(components[0]).\(components[1])"
//                let signature = components[2]
//
//                guard let signatureData = base64UrlDecode(String(signature)) else { return false }
//                guard let computedSignature = generateHMACSHA256Signature(message: headerAndPayload, secret: secret) else { return false }
//
//                return computedSignature == signatureData
//                
//            } else {
//                return false
//            }
//        } catch {
//            return false
//        }
//        
//        
//        
//        // Helper
//        func base64UrlDecode(_ value: String) -> Data? {
//            var base64 = value.replacing("-", with: "+").replacing("_", with: "/")
//            while base64.count % 4 != 0 {
//                base64.append("=")
//            }
//
//            return Data(base64Encoded: base64)
//        }
//        
//        // Helper
//        func generateHMACSHA256Signature(message: String, secret: String) -> Data? {
//            guard let keyData = secret.data(using: .utf8), let messageData = message.data(using: .utf8) else { return nil }
//
//            let key = SymmetricKey(data: keyData)
//            let signature = HMAC<SHA256>.authenticationCode(for: messageData, using: key)
//            
//            return Data(signature)
//        }
//    }
}
