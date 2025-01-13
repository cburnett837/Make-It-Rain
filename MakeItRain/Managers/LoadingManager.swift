//
//  LoadingManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import Foundation


@Observable
class LoadingManager {
    static let shared = LoadingManager()
    
    var downloadAmount = 0.0
    var showLoadingBar = false
    var showLoadingSpinner = false
    var showInitiallyLoadingSpinner = false
    
    var timer: Timer?
    
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
}
