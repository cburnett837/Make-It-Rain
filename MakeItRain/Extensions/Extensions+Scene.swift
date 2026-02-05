//
//  Extensions+Scene.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation
import SwiftUI

#if os(macOS)
extension Scene {
    func auxilaryWindow(openIn location: UnitPoint = .topTrailing) -> some Scene {
        self
        //.defaultLaunchBehavior(.suppressed) --> Not using because we terminate the app when the last window closes.
        /// Required to prevent the window from entering full screen if the main window is full screen.
        .windowResizability(.contentSize)
        /// Make sure any left over windows do not get opened when the app launches.
        .restorationBehavior(.disabled)
        /// Open in the top right corner.
        .defaultPosition(location)
    }
}
#endif
