//
//  PlaidLinkView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/21/25.
//

#if os(iOS)
import SwiftUI
import LinkKit


struct PlaidLinkView: View {
    ///`NOTE! Can't use environment in a view that imports LinkKit`
    //@Environment(PlaidModel.self) private var plaidModel
    @Bindable var plaidModel: PlaidModel
    var linkMode: PlaidLinkMode
    var bank: CBPlaidBank?
    
    @State private var handler: Handler?
    @State private var isGettingLinkToken = false
    @State private var isPresentingLink = false
    
    var showSpinner: Bool {
        plaidModel.isSettingUpBankOnServer || handler != nil || isGettingLinkToken
    }
    
    var body: some View {
        linkButton
            .fullScreenCover(isPresented: $isPresentingLink, onDismiss: linkControllerClosed) {
                if let handler {
                    PlaidLinkController(handler: handler)
                        .ignoresSafeArea(.all)
                } else {
                    VStack {
                        Text("Error: LinkController not initialized")
                        Button("Close") {
                            isPresentingLink = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                }
            }
    }
    
    var linkButton: some View {
        Button(action: createHandler) {
            switch linkMode {
            case .addAccount:
                Text("Revise selected accounts")
                
            case .updateBank:
                Text("Update this bank")
                
            case .newBank:
                Image(systemName: "plus")
            }
        }
        .opacity(showSpinner ? 0 : 1)
        .overlay { ProgressView().opacity(showSpinner ? 1 : 0) }
    }
    
//    var newBankButton: some View {
//        Button {
//            Task {
//                isGettingLinkToken = true
//                /// Create handler with a dummy bank. If a real bank was being passed in, it would mean that that bank requires an update.
//                await createLinkHandler(bank: .init())
//                isPresentingLink = true
//                isGettingLinkToken = false
//            }
//        } label: {
//            Image(systemName: "plus")
//        }
//    }
//    var addAccountsButton: some View {
//        Button {
//            if let bank = bank {
//                Task {
//                    isGettingLinkToken = true
//                    await createLinkHandler(bank: bank)
//                    isPresentingLink = true
//                    isGettingLinkToken = false
//                }
//            }
//            
//        } label: {
//            Text("Add more accounts")
//        }
//    }
    
    private func linkControllerClosed() {
        isPresentingLink = false
        handler = nil
    }
    
    private func createHandler() {
        Task {
            isGettingLinkToken = true
            await createLinkHandler(bank: bank ?? .init())
            isPresentingLink = true
            isGettingLinkToken = false
        }
    }
    
    private func createLinkHandler(bank: CBPlaidBank) async {
        let createResult = await plaidModel.createHandler(bank: bank, linkMode: linkMode, isPresentingLink: $isPresentingLink)
        switch createResult {
        case .failure(let createError):
            isGettingLinkToken = false
            AppState.shared.showAlert("There was a problem trying to fetch a plaid link token.")
            print("Link Creation Error: \(createError.localizedDescription)")
            
        case .success(let handler):
            self.handler = handler
            isGettingLinkToken = false
            print("Link Handler has been created")
            
        case .none:
            isGettingLinkToken = false
            AppState.shared.showAlert("There was a problem trying to fetch a plaid link token.")
            print("Error creating handler")
        }
    }
}
#endif
