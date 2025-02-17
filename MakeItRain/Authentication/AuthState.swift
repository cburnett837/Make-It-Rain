//
//  AuthenticationManager.swift
//  wittwer_connect_v1_021221
//
//  Created by Cody Burnett on 2/12/21.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class AuthState {
    var isLoggedIn = false
    var isBioAuthed = false
    var isThinking = true
    var isAdmin = false
    var error: AppError?
    
    var serverRevoked = false
    
    static let shared: AuthState = AuthState()
    
    let networkManager = NetworkManager()
    let keychainManager = KeychainManager()
    
    func attemptLogin(email: String, password: String) async {
        print("-- \(#function)")
        let loginModel = LoginModel(email: email, password: password)
        
        let model = RequestModel(requestType: "budget_app_login", model: loginModel)
        typealias ResultResponse = Result<CBLogin?, AppError>
        async let result: ResultResponse = await NetworkManager(timeout: 20).singleRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            do {
                if let model = model {
                    try keychainManager.addToKeychain(email: email, password: password)
                    
                    let userData = try JSONEncoder().encode(model.user)
                    UserDefaults.standard.set(userData, forKey: "user")
                    AppState.shared.user = model.user
                    AppState.shared.accountUsers = model.accountUsers
                    AppState.shared.methsExist = model.hasPaymentMethodsExisiting
                    AppState.shared.isLoggingInForFirstTime = true
                    AppState.shared.hasBadConnection = false
                    withAnimation {
                        AppState.shared.appIsReadyToHideSplashScreen = false
                    }
                    
                    self.isLoggedIn = true
                    self.isThinking = false
                    self.isBioAuthed = true
                }
            } catch {
                print(error.localizedDescription)
            }
            
            
        case .failure(let error):
            self.error = error
            
            switch error {
            case .incorrectCredentials:
                self.isLoggedIn = false
                self.isThinking = false
                self.isBioAuthed = false
                AppState.shared.appIsReadyToHideSplashScreen = true
                logout()
            
            default:
                self.isLoggedIn = false
                self.isThinking = false
                self.isBioAuthed = false
                AppState.shared.hasBadConnection = true
                AppState.shared.appIsReadyToHideSplashScreen = true
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("Connection Problem")
            }
        }
    }
    
    
    func logout() {
        withAnimation {
            self.isLoggedIn = false
        }        
        do {
            try keychainManager.removeFromKeychain()
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
    
}
