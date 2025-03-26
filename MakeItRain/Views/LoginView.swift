//
//  LoginView.swift
//  WittwerDashboard
//
//  Created by Cody Burnett on 5/25/21.
//

import SwiftUI

@MainActor
struct LoginView: View {
    enum Field: Hashable {
        case email
        case password
    }
    
    enum AlertType {
        case email, password, invalid, server
    }
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var email = ""
    @State private var password = ""
    @State private var showMissingEmailAlert = false
    @State private var showMissingPasswordAlert = false
    @State private var showFailedLoginAlert = false
    @State private var showServerErrorAlert = false
    
    @FocusState private var focusedField: Field?
    @State private var attemptingLogin = false
    
    @State private var wish = false
    
    var body: some View {
        ZStack {
            //#if os(iOS)
            EmitterView()
                .scaleEffect(!wish ? 1 : 0, anchor: .top)
                .opacity(!wish ? 1 : 0)
                .ignoresSafeArea()
                #if os(macOS)
                .rotationEffect(Angle(degrees: 180))                
                #endif
                //.blur(radius: 1)
            //#endif
            
            VStack {
                Spacer()
                
                Text("Make it Rain")
                    .font(.largeTitle)
                    .foregroundStyle(.primary)
                    //.background(Color(.secondarySystemBackground).blur(radius: 20))
                    
                Spacer()
                
                VStack(spacing: 0) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                        .textContentType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .frame(width: 250)
//                        .onChange(of: email) { oldValue, newValue in
//                            email = email.lowercased()
//                        }
                    Divider()
                        .frame(width: 250)
                }
                //.background(Color(.secondarySystemBackground).blur(radius: 10))
                                
                Spacer().frame(height: 16)
                
                VStack(spacing: 0) {
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .frame(width: 250)
                        .onSubmit {
                            focusedField = nil
                            attemptingLogin = true
                            Task { await attemptLogin() }
                        }
                    
                    Divider()
                        .frame(width: 250)
                }
                
                Spacer().frame(height: 16)
                
                VStack {
                    Button("Login") {
                        focusedField = nil
                        attemptingLogin = true
                        Task { await attemptLogin() }
                    }
                    .opacity(attemptingLogin ? 0 : 1)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .keyboardShortcut(.return)                    
                }
                .overlay {
                    ProgressView()
                        .tint(.none)
                        .opacity(attemptingLogin ? 1 : 0)
                }
                Spacer()
            }
        }
        #if os(iOS)
        .standardBackground()
        #endif
        
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack(spacing: 2) {
                    Button {
                        focusedField = .email
                    } label: {
                        Image(systemName: "chevron.up")
                            //.foregroundStyle(.green)
                            .foregroundStyle(focusedField == .email ? .gray : .green)
                    }
                    .disabled(focusedField == .email)
                    
                    Button {
                        focusedField = .password
                    } label: {
                        Image(systemName: "chevron.down")
                            //.foregroundStyle(.green)
                            .foregroundStyle(focusedField == .password ? .gray : .green)
                    }
                    .disabled(focusedField == .password)
                    
                    Spacer()
                    Button {
                        focusedField = nil
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .alert("Email cannot be blank", isPresented: $showMissingEmailAlert, actions: { Button("OK") { } })
        .alert("Password cannot be blank", isPresented: $showMissingPasswordAlert, actions: { Button("OK") { } })
        .alert("The entered credentials were incorrect", isPresented: $showFailedLoginAlert, actions: { Button("OK") { } })
        .alert("There was a problem connecting to server", isPresented: $showServerErrorAlert, actions: {
            Button("OK") { }
        }, message: {
            Text("If this issue persists, please contact Cody.")
        })
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
                focusedField = .email
                showAlert(.email)
            } else if password.isEmpty {
                focusedField = .password
                showAlert(.password)
            }
            return
        }
        
        /// Sets `AuthState.isThinking`
        /// Sets `AuthState.isLoggedIn`
        /// Sets `AppState.appShouldShowSplashScreen`
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

