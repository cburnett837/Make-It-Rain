//
//  AppDelegate.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/6/24.
//

import Foundation
import SwiftUI
import PhotosUI

#if os(macOS)
class AppDelegateMac: NSObject, NSApplicationDelegate, NSWindowDelegate {
//    internal func applicationWillTerminate(_ aNotification: Notification) {
//        print("-- \(#function)")
//    }
    
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
        
//    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
//        if model.wholeTransactionListStoredForFiltering != model.shouldSaveComparisonList {
//            showCloseAlert = true
//            return NSApplication.TerminateReply.terminateLater
//        } else {
//            return NSApplication.TerminateReply.terminateNow
//        }
//    }
//    
//    func dontCloseApp() {
//        NSApplication.shared.reply(toApplicationShouldTerminate: false)
//    }
//    
//    func closeApp() {
//        NSApplication.shared.reply(toApplicationShouldTerminate: true)
//    }
    //replyToApplicationShouldTerminate()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [unowned self] (status) in
            DispatchQueue.main.async { [unowned self] in
                #warning("Handle this authentication")
                //showUI(for: status)
            }
        }
        
        // Display connected / disconnected
//        NotificationCenter.default.addObserver(self, selector: #selector(displayConfigurationChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
                
        // System sleep / wakeup
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(systemDidWake), name: NSWorkspace.didWakeNotification, object: nil)
        center.addObserver(self, selector: #selector(systemWillSleep), name: NSWorkspace.willSleepNotification, object: nil)

        // Screensaver starts
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenIsLocked), name: Notification.Name("com.apple.screenIsLocked"), object: nil)
        // Screensaver ends
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenIsUnlocked), name: Notification.Name("com.apple.screenIsUnlocked"), object: nil)
        
    }
    
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        NotificationManager.shared.sendNotificationTokenToServer(token: token)
    }
    
    
    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        #warning("something funky going on here when 'start in full screen' toggle is off")
        print("-- 🍎 LIFECYCLE: \(#function)")
        AppState.shared.isInFullScreen = true
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        print("-- 🍎 LIFECYCLE: \(#function)")
        AppState.shared.isInFullScreen = false
    }
    
    func windowDidResignMain(_ notification: Notification) {
        print("-- 🍎 LIFECYCLE: \(#function)")
        AppState.shared.macWindowDidBecomeMain = false
    }
        
    func windowDidBecomeMain(_ notification: Notification) {
        print("-- 🍎 LIFECYCLE: \(#function)")
        AppState.shared.macWindowDidBecomeMain = true
    }
    
//    func windowDidBecomeKey(_ notification: Notification) {
//        print("-- \(#function)")
//    }
//    
//    func windowWillClose(_ notification: Notification) {
//        print("-- \(#function)")
//    }
//    
//    func applicationWillHide(_ notification: Notification) {
//        print("-- \(#function)")
//    }
//    
//    func applicationWillBecomeActive(_ notification: Notification) {
//        print("-- \(#function)")
//    }
//    
//    func applicationWillResignActive(_ notification: Notification) {
//        print("-- \(#function)")
//    }
//    
//    func applicationWillTerminate(_ notification: Notification) {
//        print("-- \(#function)")
//    }
    
    

//    @objc private func displayConfigurationChanged() {
//        print("-- 🍎 LIFECYCLE: \(#function)")
//        // Handle display configuration change
//    }

    @objc private func systemDidWake() {
        print("-- 🍎 LIFECYCLE: \(#function)")
        // Handle system wakeup
        AppState.shared.macSlept = false
        AppState.shared.macWokeUp = true
    }

    @objc private func systemWillSleep() {
        print("-- 🍎 LIFECYCLE: \(#function)")
        // Handle system sleep
        AppState.shared.macSlept = true
        AppState.shared.macWokeUp = false
        
        
        //NotificationCenter.default.removeObserver(self)
        //NSWorkspace.shared.notificationCenter.removeObserver(self)
        //DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func screenIsLocked() {
        print("-- 🍎 LIFECYCLE: \(#function)")
        // Handle screen locking (screensaver starts)
    }

    @objc private func screenIsUnlocked() {
        print("-- 🍎 LIFECYCLE: \(#function)")
        // Handle screen locking (screensaver starts)
    }
    
}


/// Set as the background of the app container in order to let me access the NSWindowDelegateMethods
struct HostingWindowFinder: NSViewRepresentable {
    var callback: (NSWindow?) -> ()
    
    func makeNSView(context: Self.Context) -> NSView {
        let view = NSView()
        Task { await MainActor.run { self.callback(view.window) } }
        //DispatchQueue.main.async { self.callback(nsView.window) }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        Task { await MainActor.run { self.callback(nsView.window) } }
        //DispatchQueue.main.async { self.callback(nsView.window) }
    }
}

#endif




#if os(iOS)
class AppDelegatePhone: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [unowned self] (status) in
//            DispatchQueue.main.async { [unowned self] in
//                #warning("Handle this authentication")
//                //showUI(for: status)
//            }
//        }
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        return true
    }
    
    
    @objc func keyboardDidShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            //print(keyboardHeight)
            AppState.shared.keyboardHeight = keyboardHeight
            AppState.shared.showKeyboardToolbar = true
        }
    }
    
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
           // print(keyboardHeight)
            AppState.shared.keyboardHeight = keyboardHeight
            AppState.shared.showKeyboardToolbar = true
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        AppState.shared.keyboardHeight = 0
        AppState.shared.showKeyboardToolbar = false
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        NotificationManager.shared.sendNotificationTokenToServer(token: token)
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }        
    
}

#endif




