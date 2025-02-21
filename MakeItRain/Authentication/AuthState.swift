//
//  AuthenticationManager.swift
//  wittwer_connect_v1_021221
//
//  Created by Cody Burnett on 2/12/21.
//

import Foundation
import SwiftUI
import CryptoKit


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
    
    /// This will take the stored credentials, and send them to the server for authentication.
    /// The server will send back a ``CBUser`` object. That object will contain the user information, as well as a flag that indicates if we need to force the user to the payment method screen.
    @MainActor func checkForCredentials() async {
        do {
            let apiKey = try keychainManager.getFromKeychain(key: "user_api_key")
            guard apiKey != nil else {
                isThinking = false
                AppState.shared.appShouldShowSplashScreen = false
                return
            }
//            
//            let (email, password) = try keychainManager.getCredentialsFromKeychain()
//            guard (email != nil), (password != nil) else {
//                isThinking = false
//                AppState.shared.appShouldShowSplashScreen = false
//                return
//            }
            
            /// API key will be fetched from the network functions and placed in the header.
            await attemptLogin(email: "", password: "")
        } catch {
            print(error.localizedDescription)
            isThinking = false
            AppState.shared.appShouldShowSplashScreen = false
        }
    }
    
    
    func attemptLogin(email: String, password: String) async {
        /// Email and password are only used if the user is manually providing them.
        print("-- \(#function)")
        let loginModel = LoginModel(email: email, password: password)
        
        let model = RequestModel(requestType: "budget_app_login", model: loginModel)
        typealias ResultResponse = Result<CBLogin?, AppError>
        async let result: ResultResponse = await NetworkManager(timeout: 20).singleRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            do {
                if let model = model {
                    //try keychainManager.addToKeychain(key: "user_email", value: email)
                    //try keychainManager.addToKeychain(key: "user_password", value: password)
                    if let apiKey = model.apiKey {
                        try keychainManager.addToKeychain(key: "user_api_key", value: apiKey)
                    }
                    
                    let userData = try JSONEncoder().encode(model.user)
                    UserDefaults.standard.set(userData, forKey: "user")
                    AppState.shared.user = model.user
                    AppState.shared.accountUsers = model.accountUsers
                    AppState.shared.methsExist = model.hasPaymentMethodsExisiting
                    AppState.shared.isLoggingInForFirstTime = true
                    AppState.shared.hasBadConnection = false
                    
                    withAnimation {
                        AppState.shared.appShouldShowSplashScreen = true
                    }
                                        
                    self.isLoggedIn = true
                    self.isThinking = false
                    //self.isBioAuthed = true
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
            AppState.shared.appShouldShowSplashScreen = false
            
            switch error {
            case .incorrectCredentials, .accessRevoked:
                logout()
                
            default:
                AppState.shared.hasBadConnection = true
                AppState.shared.showAlert("Connection Problem")
            }
        }
    }
    
    
    func logout() {
        withAnimation {
            self.isLoggedIn = false
        }        
        do {
            //try keychainManager.removeFromKeychain(key: "user_email")
            //try keychainManager.removeFromKeychain(key: "user_password")
            try keychainManager.removeFromKeychain(key: "user_api_key")
            UserDefaults.standard.set(nil, forKey: "user")
//            UserDefaults.standard.set("", forKey: "userEmail")
//            UserDefaults.standard.set("", forKey: "userAccountID")
//            UserDefaults.standard.set("", forKey: "userID")
//            UserDefaults.standard.set("", forKey: "userName")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    func serverAccessRevoked() {
        logout()
        serverRevoked = true        
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
//            var base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
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
