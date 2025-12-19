//
//  LoadingManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import Foundation
import SwiftUI


@Observable
class LoadingManager {
    static let shared = LoadingManager()
    
    //var downloadAmount = 0.0
    //var showLoadingBar = false
    var showLoadingSpinner = false
    //var showInitiallyLoadingSpinner = false
    
    var timer: Timer?
    var longNetworkTaskTimer: Timer?
    var showLongNetworkTaskToast = false
    
    
    
    
    @objc func showDelayedSpinner() {
        showLoadingSpinner = true
    }
    
    func startDelayedSpinner() {
        timer = Timer(fireAt: Date.now.addingTimeInterval(2), interval: 0, target: self, selector: #selector(showDelayedSpinner), userInfo: nil, repeats: false)
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }
    
    func stopDelayedSpinner() {
        showLoadingSpinner = false
        if let timer = self.timer {
            timer.invalidate()
        }
    }
    
    
    
    
    
    
    @objc func showLongNetworkToast() {
        showLongNetworkTaskToast = true
        AppState.shared.showToast(
            title: "Potential Network Problem",
            subtitle: "Syncing with the server is taking longer than expected.",
            body: "Your data will be stored offline and sync when you have a better connection.",
            symbol: "network.slash",
            symbolColor: .orange,
            autoDismiss: false
//            action: {
//                withAnimation {
//                    AppState.shared.hasBadConnection = true
//                    AppState.shared.toast = nil
//                }
//            }
        )
        
    }
            
    func startLongNetworkTimer() {
        if longNetworkTaskTimer == nil {
            longNetworkTaskTimer = Timer(fireAt: Date.now.addingTimeInterval(5), interval: 0, target: self, selector: #selector(showLongNetworkToast), userInfo: nil, repeats: false)
            if let longNetworkTaskTimer { RunLoop.main.add(longNetworkTaskTimer, forMode: .common) }
        }
    }
    
    func stopLongNetworkTimer() {
        showLongNetworkTaskToast = false
        showLoadingSpinner = false
        if let longNetworkTaskTimer = self.longNetworkTaskTimer {
            longNetworkTaskTimer.invalidate()
            self.longNetworkTaskTimer = nil
        }
    }
}
