//
//  LoginView.swift
//  WittwerDashboard
//
//  Created by Cody Burnett on 5/25/21.
//

import SwiftUI

@MainActor
struct LoginView: View {
    enum AlertType {
        case email, password, invalid, server
    }
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Int?
    @State private var attemptingLogin = false
    
    var body: some View {
        ZStack {
            rainingDollars
                        
            blurredBackground
            
            VStack {
                Spacer()
                
                makeItRainLogo
                Spacer()
                    .frame(maxHeight: 100)
                
                emailField
                Spacer().frame(height: 24)
                
                passwordField
                Spacer().frame(height: 24)
                
                loginButton
                Spacer()
            }
        }
    }
    
    var rainingDollars: some View {
        EmitterView()
            .scaleEffect(1, anchor: .top)
            .ignoresSafeArea()
            #if os(macOS)
            .rotationEffect(Angle(degrees: 180))
            #endif
    }
    
    var blurredBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            //.opacity(0.7)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(.all)
    }
    
    @ViewBuilder
    var makeItRainLogo: some View {
//        Image("MakeItRain-logo-no-background")
//            .resizable()
//            .scaledToFit()
//            .frame(width: 250, height: 250)
        Text("Make It Rain")
            .font(.largeTitle)
            .foregroundStyle(.primary)
    }
    
    
    var emailField: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "person")
                    .foregroundStyle(.gray)
                
                UITextFieldWrapper(placeholder: "Email", text: $email, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .uiTag(0)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.left)
                .uiKeyboardType(.system(.emailAddress))
                .uiAutoCapitalizationType(.none)
                .focused($focusedField, equals: 0)
            }
            .frame(width: 250)
                                                                        
            Divider()
                .frame(width: 250)
        }
    }
    
    
    var passwordField: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "lock")
                    .foregroundStyle(.gray)
                
                UITextFieldWrapper(placeholder: "Password", text: $password, onSubmit: {
                    focusedField = nil
                    attemptingLogin = true
                    Task { await attemptLogin() }
                }, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .uiTag(1)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.left)
                .uiKeyboardType(.system(.default))
                .uiAutoCapitalizationType(.none)
                .uiIsSecure(true)
                .focused($focusedField, equals: 1)
            }
            .frame(width: 250)
                                
            Divider()
                .frame(width: 250)
        }
    }
    
    
    var loginButton: some View {
        Capsule()
            .fill(.green)
            .frame(width: 250, height: 40)
            .onTapGesture {
                focusedField = nil
                attemptingLogin = true
                Task { await attemptLogin() }
            }
            .disabled(attemptingLogin)
            //.opacity(attemptingLogin ? 0 : 1)
            .keyboardShortcut(.return)
            .overlay {
                if attemptingLogin {
                    ProgressView()
                        .tint(.none)
                        .opacity(attemptingLogin ? 1 : 0)
                } else {
                    Text("Sign In")
                }
            }
        
        
//        Button("Login") {
//            focusedField = nil
//            attemptingLogin = true
//            Task { await attemptLogin() }
//        }
//        .frame(width: 250)
//        .opacity(attemptingLogin ? 0 : 1)
//        .buttonStyle(.borderedProminent)
//        .tint(.green)
//        //.tint(Color.fromHex("ffa300"))
//        .keyboardShortcut(.return)
//        .overlay {
//            ProgressView()
//                .tint(.none)
//                .opacity(attemptingLogin ? 1 : 0)
//        }
    }
    
    
    func showAlert(_ type: AlertType) {
        AuthState.shared.isThinking = false
        attemptingLogin = false
        switch type {
        case .email:
            AppState.shared.showAlert(config: AlertConfig(title: "Email cannot be blank", symbol: .init(name: "envelope", color: .orange)))
        case .password:
            AppState.shared.showAlert(config: AlertConfig(title: "Password cannot be blank", symbol: .init(name: "lock", color: .orange)))
        case .invalid:
            AppState.shared.showAlert(config: AlertConfig(title: "Login Failed", subtitle: "The entered credentials were incorrect", symbol: .init(name: "hand.thumbsdown", color: .red)))
        case .server:
            AppState.shared.showAlert(config: AlertConfig(title: "Server Error", subtitle: "There was a problem connecting to server", symbol: .init(name: "network.slash", color: .red)))
        }
    }
    
    
    func attemptLogin() async {
        guard !email.isEmpty, !password.isEmpty else {
            if email.isEmpty {
                focusedField = 0
                showAlert(.email)
            } else if password.isEmpty {
                focusedField = 1
                showAlert(.password)
            }
            return
        }
        
        /// Sets `AuthState.isThinking`
        /// Sets `AuthState.isLoggedIn`
        /// Sets `AppState.shouldShowSplash`
        await AuthState.shared.attemptLogin(using: .emailAndPassword, with: LoginModel(email: email, password: password))
                
        switch AuthState.shared.error {
        case .incorrectCredentials, .accessRevoked: // calling .credentialsIncorrect because credentials can't be revoked at this stage. I mean they can, but this is a better alert.
            attemptingLogin = false
            showAlert(.invalid)
            
        case .connectionError, .serverError:
            attemptingLogin = false
            showAlert(.server)
            
        default:
            attemptingLogin = false
//            if AuthState.shared.isLoggedIn {
//                /// When the user logs in, if they have no payment methods, show the payment method required sheet.
//                if AppState.shared.methsExist {
//                    funcModel.downloadInitial()
//                } else {
//                    LoadingManager.shared.showInitiallyLoadingSpinner = false
//                    LoadingManager.shared.showLoadingBar = false
//                    AppState.shared.showPaymentMethodNeededSheet = true
//                }
//                //await NotificationManager.shared.registerForPushNotifications()
//            }
        }
    }
    
    
    
//    func downloadInitial() {
//        @Bindable var navManager = NavigationManager.shared
//        /// Set navigation destination to current month
//        //navManager.selection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
//        #if os(iOS)
//        navManager.selectedMonth = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
//        #else
//        navManager.selection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
//        #endif
//        //navManager.monthSelection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
//        //navManager.navPath.append(NavDestination.getMonthFromInt(AppState.shared.todayMonth)!)
//        
//        LoadingManager.shared.showInitiallyLoadingSpinner = true
//                    
//        funcModel.refreshTask = Task {
//            /// populate all months with their days.
//            calModel.prepareMonths()
//            #if os(iOS)
//            if let selectedMonth = navManager.selectedMonth {
//                /// set the calendar model to use the current month (ignore starting amounts and calculations)
//                calModel.setSelectedMonthFromNavigation(navID: selectedMonth, prepareStartAmount: false)
//                /// download everything, and populate the days in the respective months with transactions.
//                await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaInitial)
//            }
//            #else
//            if let selectedMonth = navManager.selection {
//                /// set the calendar model to use the current month (ignore starting amounts and calculations)
//                calModel.setSelectedMonthFromNavigation(navID: selectedMonth, prepareStartAmount: false)
//                /// download everything, and populate the days in the respective months with transactions.
//                await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaInitial)
//            }
//            #endif
//        }
//    }
}

