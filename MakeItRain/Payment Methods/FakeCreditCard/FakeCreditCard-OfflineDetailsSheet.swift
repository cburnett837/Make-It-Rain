//
//  OfflineCardDetailsSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//


import SwiftUI
import LocalAuthentication

struct FakeCreditCardOfflineDetailsSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var keychainCardNumber: String?
    @State private var keychainExpirationMonth: String?
    @State private var keychainExpirationYear: String?
    @State private var keychainSecurityCode: String?
    
    @State private var keychainCardNumberBackup: String?
    @State private var keychainExpirationMonthBackup: String?
    @State private var keychainExpirationYearBackup: String?
    @State private var keychainSecurityCodeBackup: String?
    
    //@State private var keychainCardNumber2: String = ""
    
    @Bindable var payMethod: CBPaymentMethod
    
    let context = LAContext()
    @State private var error: NSError?
    @State private var isUnlocked = false
    @State private var authImage: String = "faceid"
    
    @State private var expDate: Date?
    @State private var showDatePicker = false
    @FocusState private var focusedField: Int?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    fakeCardCardNumber
                        .blur(radius: isUnlocked ? 0 : 20)
                    fakeCardExpirationDate
                        .blur(radius: isUnlocked ? 0 : 20)
                    fakeCardSecurityCode
                        .blur(radius: isUnlocked ? 0 : 20)
                        
                } footer: {
                    Text("These card details are only for your convenience, are stored securely on-device, and are never transmitted to the server.")
                }
                //.privacySensitive()
                
                if !isUnlocked {
                    Button {
                        authenticate()
                    } label: {
                        Text("Unlock")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                if isEditing {
                    clearButton
                }
            }
            .navigationTitle("Physical Card Details")
            .toolbar {
                if isUnlocked {
                    ToolbarItem(placement: .topBarLeading) {
                        editCancelButton
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        saveButton
                    } else {
                        closeButton
                    }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                YearMonthPicker(date: $expDate ?? Date())
                    .presentationDetents([.height(200)])
                    .frame(maxWidth: .infinity)
            }
        }
        .task {
            prepareAuth()
            try? await Task.sleep(for: .seconds(0.5))
            authenticate()
        }
        
        .onChange(of: isUnlocked) {
            if $1 { getCardDetailsFromKeychain() }
        }
        .onChange(of: isEditing) {
            if !$1 { saveCardDetailsToKeychain() }
        }
        .onChange(of: expDate) {
            if let new = $1 {
                keychainExpirationMonth = new.string(to: .mm)
                keychainExpirationYear = new.string(to: .yy)
            }
        }
    }
                 
    
    var fakeCardCardNumber: some View {
        HStack {
            Text("Card Number")
            Spacer()
            UITextFieldWrapper(placeholder: "Card Number", text: $keychainCardNumber ?? "", toolbar: {
                KeyboardToolbarView(
                    focusedField: $focusedField,
                    removeNavButtons: true
                )
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.right)
            .uiKeyboardType(.system(.numberPad))
            .uiDisabled(!isEditing)
            .uiTextColor(isEditing ? .label : .clear)
            .focused($focusedField, equals: 0)
            .overlay(alignment: .trailing) {
                Text(keychainCardNumber ?? "")
                    .opacity(isEditing ? 0 : 1)
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    
    var fakeCardExpirationDate: some View {
        HStack {
            Text("Expiration Date")
            Spacer()
            
            if let keychainExpirationMonth, let keychainExpirationYear {
                Text(keychainExpirationMonth.isEmpty || keychainExpirationYear.isEmpty
                     ? "Expiration Date"
                     : "\(keychainExpirationMonth)/\(keychainExpirationYear)"
                )
                .textSelection(.enabled)
                .foregroundStyle(isEditing ? .primary : .secondary)
                .onTapGesture {
                    if isEditing {
                        showDatePicker = true
                        focusedField = nil
                    }
                }
                
            } else {
                Text("Expiration Date")
                    .foregroundStyle(Color(.placeholderText))
                    .onTapGesture {
                        if isEditing {
                            showDatePicker = true
                            focusedField = nil
                        }
                    }
            }
        }
    }
    
    
    var fakeCardSecurityCode: some View {
        HStack {
            Text("Security Code")
            Spacer()
            
            UITextFieldWrapper(placeholder: "Security Code", text: $keychainSecurityCode ?? "", toolbar: {
                KeyboardToolbarView(
                    focusedField: $focusedField,
                    removeNavButtons: true
                )
            })
            .uiTag(1)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.right)
            .uiKeyboardType(.system(.numberPad))
            .uiDisabled(!isEditing)
            .uiTextColor(isEditing ? .label : .clear)
            .focused($focusedField, equals: 1)
            .overlay(alignment: .trailing) {
                Text(keychainSecurityCode ?? "")
                    .opacity(isEditing ? 0 : 1)
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    
    var clearButton: some View {
        Button {
            keychainCardNumber = nil
            keychainExpirationMonth = nil
            keychainExpirationYear = nil
            keychainSecurityCode = nil
            expDate = nil
            isEditing = false
        } label: {
            Text("Clear")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .foregroundStyle(.red)
    }
    
    
    var editCancelButton: some View {
        Button {
            if isEditing {
                keychainCardNumber = keychainCardNumberBackup
                keychainExpirationMonth = keychainExpirationMonthBackup
                keychainExpirationYear = keychainExpirationYearBackup
                keychainSecurityCode = keychainSecurityCodeBackup
                isEditing = false
            } else {
                isEditing = true
                keychainCardNumberBackup = keychainCardNumber
                keychainExpirationMonthBackup = keychainExpirationMonth
                keychainExpirationYearBackup = keychainExpirationYear
                keychainSecurityCodeBackup = keychainSecurityCode
            }
        } label: {
            Text(isEditing ? "Cancel" : "Edit")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var saveButton: some View {
        Button {
            isEditing = false
            //focusedField = nil
        } label: {
            Text("Save")
                .schemeBasedForegroundStyle()
        }
        .buttonStyle(.glassProminent)
    }
    
    
    var closeButton: some View {
        Button {
            saveCardDetailsToKeychain()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    func close() {
        saveCardDetailsToKeychain()
        dismiss()
    }
    
    
    func prepareAuth() {
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            authImage = switch context.biometryType {
            case .faceID: "faceid"
            case .touchID: "touchid"
            case .none: "lock.trianglebadge.exclamationmark"
            case .opticID: "opticid"
            @unknown default: "lock.trianglebadge.exclamationmark"
            }
        } else {
            authImage = "lock.trianglebadge.exclamationmark"
        }
    }
    
    
    func authenticate() {
        context.localizedCancelTitle = "Enter Password"
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Unlock to view your card information."
            
            //.deviceOwnerAuthenticationWithBiometrics
            //.deviceOwnerAuthentication to fallback to passcode if bio fails
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                withAnimation {
                    isUnlocked = success
                }
            }
        } else {
            // no biometrics
        }
    }
    
    
    func getCardDetailsFromKeychain() {
        print("-- \(#function)")
        let keychainManager = KeychainManager()
        do {
            if let cardNumber = try keychainManager.getFromKeychain(key: "payment_method_card_number_\(payMethod.id)") {
                self.keychainCardNumber = cardNumber
            }
            if let expirationMonth = try keychainManager.getFromKeychain(key: "payment_method_expiration_month_\(payMethod.id)") {
                self.keychainExpirationMonth = expirationMonth
            }
            if let expirationYear = try keychainManager.getFromKeychain(key: "payment_method_expiration_year_\(payMethod.id)") {
                self.keychainExpirationYear = expirationYear
            }
            if let securityCode = try keychainManager.getFromKeychain(key: "payment_method_security_code_\(payMethod.id)") {
                self.keychainSecurityCode = securityCode
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    func saveCardDetailsToKeychain() {
        print("-- \(#function)")
        let keychainManager = KeychainManager()
                        
        do {
            if let keychainCardNumber = keychainCardNumber {
                try keychainManager.addToKeychain(key: "payment_method_card_number_\(payMethod.id)", value: keychainCardNumber)
            } else {
                try keychainManager.removeFromKeychain(key: "payment_method_card_number_\(payMethod.id)")
            }
            
            if let keychainExpirationMonth = keychainExpirationMonth {
                try keychainManager.addToKeychain(key: "payment_method_expiration_month_\(payMethod.id)", value: keychainExpirationMonth)
            } else {
                try keychainManager.removeFromKeychain(key: "payment_method_expiration_month_\(payMethod.id)")
            }
            
            if let keychainExpirationYear = keychainExpirationYear {
                try keychainManager.addToKeychain(key: "payment_method_expiration_year_\(payMethod.id)", value: keychainExpirationYear)
            } else {
                try keychainManager.removeFromKeychain(key: "payment_method_expiration_year_\(payMethod.id)")
            }
            
            if let keychainSecurityCode = keychainSecurityCode {
                try keychainManager.addToKeychain(key: "payment_method_security_code_\(payMethod.id)", value: keychainSecurityCode)
            } else {
                try keychainManager.removeFromKeychain(key: "payment_method_security_code_\(payMethod.id)")
            }

        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    
    struct YearMonthPicker: UIViewRepresentable {
        @Binding var date: Date

        func makeUIView(context: Context) -> UIDatePicker {
            let picker = UIDatePicker()
            picker.datePickerMode = .yearAndMonth
            picker.preferredDatePickerStyle = .wheels
            picker.addTarget(
                context.coordinator,
                action: #selector(Coordinator.dateChanged(_:)),
                for: .valueChanged
            )
            return picker
        }

        func updateUIView(_ picker: UIDatePicker, context: Context) {
            picker.date = date
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(date: $date)
        }

        final class Coordinator: NSObject {
            @Binding var date: Date

            init(date: Binding<Date>) {
                self._date = date
            }

            @objc func dateChanged(_ sender: UIDatePicker) {
                date = sender.date
            }
        }
    }
}
