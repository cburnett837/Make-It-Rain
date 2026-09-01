//
//  CalendarModel+LoadingSpinner.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//

import Foundation

extension CalendarModel {
    @objc func showLoadingSpinnerViaTimer() {
        showLoadingSpinner = true
    }
    
    func startDelayedLoadingSpinnerTimer() {
        //print("-- \(#function)")
        if loadingSpinnerTimer != nil {
            loadingSpinnerTimer = Timer(fireAt: Date.now.addingTimeInterval(2), interval: 0, target: self, selector: #selector(showLoadingSpinnerViaTimer), userInfo: nil, repeats: false)
            RunLoop.main.add(loadingSpinnerTimer!, forMode: .common)
        }
    }
    
    func stopDelayedLoadingSpinnerTimer() {
        //print("-- \(#function)")
        if let loadingSpinnerTimer = self.loadingSpinnerTimer {
            loadingSpinnerTimer.invalidate()
        }
        if showLoadingSpinner {
            showLoadingSpinner = false
        }
    }
}
