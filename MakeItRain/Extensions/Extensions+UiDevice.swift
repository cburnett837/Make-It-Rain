//
//  Extentions+UiDevice.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation
import SwiftUI

#if os(iOS)
// The notification we'll send when a shake gesture happens.
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}
#endif
