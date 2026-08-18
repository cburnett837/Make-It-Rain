//
//  PhoneWatchSync.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/28/26.
//

#if os(iOS)
import Foundation
import SwiftUI
import WatchConnectivity

final class PhoneWatchSync: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchSync()

    func start() {
        //print("-- \(#function)")
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        
        print("⌚️ isPaired:", WCSession.default.isPaired)
        print("⌚️ isWatchAppInstalled:", WCSession.default.isWatchAppInstalled)
    }

    func syncUserDefaultsToWatch(apiKey: String) {
        //print("-- \(#function)")
        guard WCSession.default.activationState == .activated else {
            print("⌚️ Phone WCSession not activated yet")
            return
        }
        guard WCSession.default.isWatchAppInstalled else { return }
        
        guard let ud = UserDefaults(suiteName: "group.dev.cburnett837.MakeItRain")?.data(forKey: "user") else {
            print("⌚️ User default user not found")
            return
        }
        guard let user = try? JSONDecoder().decode(CBUser.self, from: ud) else {
            print("⌚️ Could not decode user from UserDefaults")
            return
        }
        
        let payload: [String: Any] = [
            "user_id": user.id,
            "account_id": user.accountID,
            "name": user.name,
            "initials": user.initials,
            "email": user.email,
            "api_key": apiKey
            //"syncVersion": Date().timeIntervalSince1970
        ]

        do {
            WCSession.default.transferUserInfo(payload)
            //try WCSession.default.updateApplicationContext(payload)
            print("⌚️ Sent context:", payload)
        } catch {
            print("⌚️ Failed to sync defaults to watch:", error)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}


#endif
