//
//  WatchPhoneSync.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/28/26.
//


import Foundation
import WatchKit
import WatchConnectivity
import WidgetKit

final class WatchPhoneSync: NSObject, WCSessionDelegate {
    static let shared = WatchPhoneSync()

    func start() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("-- \(#function)")
        if let userID = applicationContext["user_id"] as? Int {
            UserDefaults.standard.set(userID, forKey: "user_id")
        }

        if let name = applicationContext["account_id"] as? Int {
            UserDefaults.standard.set(name, forKey: "account_id")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("-- \(#function)")
        print("Received:", message)
        if message["action"] as? String == "reloadWidget" {
            // Main thread update for WidgetCenter
            DispatchQueue.main.async {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("-- \(#function)")
        print("Received:", userInfo)
        
        if let action = userInfo["action"] as? String {
            if action == "reloadWidget" {
                DispatchQueue.main.async {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            
            return
            
        }
        
        if
            let userID = userInfo["user_id"] as? Int,
            let accountID = userInfo["account_id"] as? Int,
            let name = userInfo["name"] as? String,
            let initials = userInfo["initials"] as? String,
            let email = userInfo["email"] as? String,
            let apiKey = userInfo["api_key"] as? String
        {
            
            do {
                let user = CBUser(id: userID, accountID: accountID, name: name, initials: initials, email: email)
                let userData = try JSONEncoder().encode(user)
                UserDefaults(suiteName: "group.dev.cburnett837.MakeItRain")?.set(userData, forKey: "user")
            } catch {
                print(error.localizedDescription)
            }
            
            do {
                try KeychainManager().addToKeychain(key: "api_key", value: apiKey)
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch session activated:", activationState.rawValue)

        let context = session.receivedApplicationContext
        print("Existing context:", context)

        if context.isEmpty {
            print("No context received yet")
        }
    }
}
