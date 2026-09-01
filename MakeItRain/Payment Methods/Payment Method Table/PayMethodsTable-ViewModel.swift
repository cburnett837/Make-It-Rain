//
//  ViewModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//


import SwiftUI
import LocalAuthentication

extension PayMethodsTable {
    @Observable
    class ViewModel {
        var paymentMethodEditID: String?
        var editPaymentMethod: CBPaymentMethod?
        var transEditID: String?
        var transDay: CBDay?
        var selectedPaymentMethod: CBPaymentMethod?

        var hideUnselectedCards: Bool = false
        var walletSearchText = ""
        var transSearchText = ""
        var showOfflineCardDetailsSheet = false
        
        var info: Info = .init()

        var isCardSelected: Bool {
            return selectedPaymentMethod != nil
        }
        
        var navTitle: String {
            "\(isCardSelected ? selectedPaymentMethod!.title : "Wallet")\(AppState.shared.devMode ? " (Dev)" : "")"
        }
        
        var animation: Animation = .interactiveSpring(response: 0.55, dampingFraction: 0.8)

        
        struct Info {
            //var scrollOffset: CGFloat = 0
            var containerSize: CGSize = .zero
            var safeArea: EdgeInsets = .init()
            var minY: CGFloat = 0
        }
    }
}