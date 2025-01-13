//
//  ReminderCreator.swift
//  Wittwer Digital Filecart
//
//  Created by Cody Burnett on 8/10/23.
//

import Foundation
import SwiftUI
import UserNotifications

struct ReminderCreator: View {
    enum Offset {
        case dayBack0, dayBack1, dayBack2
    }
    
    @Environment(\.dismiss) var dismiss
    
    var payMethod: CBPaymentMethod
    @State private var reminderOffset: Offset = .dayBack0
    @State private var reminderMessage: String?
    
    var body: some View {
        VStack {
            Group {
                Spacer()
                    .frame(height: 30)
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 72))
                    .foregroundColor(payMethod.color)
                Text(payMethod.title)
                    .font(.title)
                Text("Payment Reminder")
                    .font(.headline)
                    .foregroundStyle(.gray)
                Spacer()
                    .frame(height: 30)
                Divider()
                Spacer()
                    .frame(height: 30)
            }
            Group {
                //StandardTextField("Enter a reminder message", text: $reminderMessage ?? "", keyboardType: .text)
                
                Spacer()
                
                Picker(selection: $reminderOffset) {
                    Text("2 days before")
                        .tag(Offset.dayBack2)
                    Text("1 day before")
                        .tag(Offset.dayBack1)
                    Text("Day of")
                        .tag(Offset.dayBack0)
                } label: {
                    Text("Reminder Date")
                }
                .pickerStyle(.palette)
                .tint(payMethod.color)
                .onChange(of: reminderOffset) { oldValue, newValue in
                    switch newValue {
                    case .dayBack0:
                        payMethod.notificationOffset = 0
                    case .dayBack1:
                        payMethod.notificationOffset = 1
                    case .dayBack2:
                        payMethod.notificationOffset = 2
                    }
                }
            }
            
            Spacer()
            
            Button("Add Reminder") {
                NotificationManager.shared.createReminder2(payMethod: payMethod)
                dismiss()
            }
            .tint(payMethod.color)
            .buttonStyle(.borderedProminent)
            //.buttonBorderShape(.capsule)
            Spacer()
        }
        
        .padding(.horizontal)
    }
}
    

