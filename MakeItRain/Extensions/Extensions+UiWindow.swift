//
//  Extensions+UiWindow.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//


import Foundation
import SwiftUI

#if os(iOS)
extension UIWindow {
    //  Override the default behavior of shake gestures to send our notification instead.
     open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
     }
}
#endif
