//
//  NotificationManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/23/24.
//

import Foundation
import SwiftUI
import UserNotifications

struct PaymentDueNotification: Identifiable {
    var id = UUID()
    var identifier: String
    var payMethodID: String
    var scheduledDate: Date
    var title: String
    var subtitle: String
    
    
}

@Observable
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    var scheduledNotifications = [PaymentDueNotification]()
    var notificationsAreAllowed = false
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        getNotifications()
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            // Here we actually handle the notification
            print("Notification received with identifier \(notification.request.identifier)")
            // So we call the completionHandler telling that the notification should display a banner and play the notification sound - this will happen while the app is in foreground
            completionHandler([.banner, .sound])
        }
    
    func getNotifications() {
        //notificationCenter.removeAllPendingNotificationRequests()
        scheduledNotifications.removeAll()
        notificationCenter.getPendingNotificationRequests { (notificationRequests) in
            DispatchQueue.main.async {
                for notificationRequest: UNNotificationRequest in notificationRequests {
                    
                    let scheduledDate = notificationRequest.content.userInfo["scheduledDate"] as! Date
                    let payMethodID = notificationRequest.content.userInfo["payMethodID"] as! String
                    
                    let notification = PaymentDueNotification(
                       identifier: notificationRequest.identifier,
                       payMethodID: payMethodID,
                       scheduledDate: scheduledDate,
                       title: notificationRequest.content.title,
                       subtitle: notificationRequest.content.subtitle
                    )
                    
                    self.scheduledNotifications.append(notification)
                }
            }
        }
    }
    
    //@available(iOSApplicationExtension, unavailable)
    func registerForPushNotifications() async {
        print("-- \(#function)")
        
        do {
             if try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) == true {
                 let settings = await notificationCenter.notificationSettings()
                 switch settings.authorizationStatus {
                 case .notDetermined:
                     print("Notification Status: notDetermined")
                     notificationsAreAllowed = false
                 case .denied:
                     print("Notification Status: denied")
                     notificationsAreAllowed = false
                 case .authorized:
                     print("Notification Status: authorized")
                     notificationsAreAllowed = true
                     DispatchQueue.main.async {
                         #if os(macOS)
                         NSApplication.shared.registerForRemoteNotifications()
                         #else
                         UIApplication.shared.registerForRemoteNotifications()
                         #endif
                     }
                 case .provisional:
                     print("Notification Status: provisional")
                 case .ephemeral:
                     print("Notification Status: ephemeral")
                 @unknown default:
                     print("Notification Status: unknown")
                     notificationsAreAllowed = false
                 }
                 
             } else {
                 print("notificationCenter.requestAuthorization is unauthorized")
                 notificationsAreAllowed = false
             }
        } catch {
            print("notificationCenter.requestAuthorization failed with error")
            print(error.localizedDescription)
            notificationsAreAllowed = false
        }
    }
    
    
    func sendNotification(title: String, subtitle: String?, body: String?) {
        print("-- \(#function)")
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle { content.subtitle = subtitle }
        if let body { content.body = body }
        
        content.sound = .none
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        NotificationManager.shared.notificationCenter.add(request)
    }
    
    
    func createReminder2(payMethod: CBPaymentMethod) {
        let notifications = scheduledNotifications.filter { $0.payMethodID == payMethod.id }
        if !notifications.isEmpty {
            let identifiers = notifications.map { $0.identifier }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
        
        
        //let reminderMessage: String? = ""
        let calendar = Calendar.current
        
        var date = Date()
        for _ in 0..<12 {
            
            //print(payMethod.dueDate)
            //print(payMethod.notificationOffset)
            //print((payMethod.dueDate ?? 0) - payMethod.notificationOffset)
            
            #warning("FIX ME")
            //date = nextDate(for: reminderDay, startDate: date)
            date = nextDate(for: (payMethod.dueDate ?? 0) - (payMethod.notificationOffset ?? 0), startDate: date)
            let components = calendar.dateComponents(in: calendar.timeZone, from: date)
            
            let content = UNMutableNotificationContent()
            content.title = "Payment Reminder for \(payMethod.title)"
            content.subtitle = "\(payMethod.title) is due today"
            //content.subtitle = (reminderMessage ?? "").isEmpty ? "\(payMethod.title) is due today" : reminderMessage ?? "\(payMethod.title) is due today"
            content.sound = UNNotificationSound.default
            content.userInfo = [
                "scheduledDate": date,
                "payMethodID": payMethod.id
            ]
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            //print(trigger.nextTriggerDate())
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            NotificationManager.shared.notificationCenter.add(request) {
                if let error = $0 {
                    print(error)
                    return
                } else {
                    print("scheduled")
                }
            }
        }
        
        NotificationManager.shared.getNotifications()
                        
        func nextDate(for dayOfMonth: Int, startDate: Date) -> Date {
            var components = DateComponents()
            components.day = dayOfMonth
            components.hour = 9
            components.minute = 0
            components.second = 0
            components.timeZone = calendar.timeZone
            components.quarter = nil
            
            return calendar.nextDate(after: startDate, matching: components, matchingPolicy: .previousTimePreservingSmallerComponents)!
        }
    }
    
    
    
    
    
    

//    func registerForPushNotifications() {
//        LogManager.log()
//        //let notificationCenter = UNUserNotificationCenter.current()
//        
//        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge, .carPlay, .providesAppNotificationSettings, .criticalAlert]) { granted, _ in
//            //print("Permission granted: \(granted)")
//            guard granted else { return }
//            
//            // Define the buttons I want
//            let yesAction = UNNotificationAction(identifier: "YES_BUTTON", title: "Yes", options: UNNotificationActionOptions(rawValue: 0))
//            let noAction = UNNotificationAction(identifier: "NO_BUTTON", title: "No", options: UNNotificationActionOptions(rawValue: 0))
//            
//    
//            // Define the notification category
//            let yesNoCategory = UNNotificationCategory(identifier: "YES_NO", actions: [yesAction, noAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
//            
//            let bankBalances = UNNotificationCategory(identifier: "BANK_BALANCES", actions: [], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
//            
//            self.notificationCenter.setNotificationCategories([yesNoCategory, bankBalances])
//            
//            self.notificationCenter.getNotificationSettings { settings in
//                //print("Notification settings: \(settings)")
//                guard settings.authorizationStatus == .authorized else { return }
//                DispatchQueue.main.async {
//                    UIApplication.shared.registerForRemoteNotifications()
//                }
//            }
//        }
//    }
//    
//    
//    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        LogManager.log()
//        
//        let userInfo = response.notification.request.content.userInfo
//        LogManager.log(String(describing: userInfo))
//        //let meetingID = userInfo["MEETING_ID"] as! String
//        //let userID = userInfo["USER_ID"] as! String
//        if response.notification.request.identifier == "YES_NO" {
//            switch response.actionIdentifier {
//            case "YES_BUTTON":
//                break
//                
//            case "NO_BUTTON":
//                break
//            default:
//                print("Other actions")
//            }
//        }
//        completionHandler()
//    }
//    
//    
//    
//    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        print("-- \(#function)")
//        guard let aps = notification.request.content.userInfo["aps"] as? [String: AnyObject] else {
//            completionHandler([.banner,.badge,.sound])
//            return
//        }
//        print(aps)
//        //self.didReceiveMicPrompt = true
//        completionHandler([])
//        //print(notificatonManager.didReceiveMicPrompt)
//    }
//    
//    
//
    /// `@MainActor`  is required to fix the data race that occurs when `CBUser` tries to get send to the server, and this is trying to set the token inside it.
    @MainActor
    func sendNotificationTokenToServer(token: String) {
        print("-- \(#function)")
        AppState.shared.user?.notificationToken = token
        let user = AppState.shared.user
        //user?.notificationToken = token
        //let tokenModel = NotificationToken(token: token)
        let model = RequestModel(requestType: "add_new_notification_token_for_budget_app", model: user)
        Task {
            typealias ResultResponse = Result<ResultCompleteModel?, AppError>
            async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                        
            switch await result {
            case .success:
                print("Successfully sent token")
                LogManager.networkingSuccessful()
                break
                
            case .failure(let error):
                LogManager.error("Failed to send token \(error.localizedDescription)")
            }
        }
    }
}
