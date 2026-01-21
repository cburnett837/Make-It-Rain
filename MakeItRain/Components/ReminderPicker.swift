//
//  ReminderPicker.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/17/25.
//

import SwiftUI

struct ReminderPicker: View {
    var title = "Reminder"
    @Binding var notificationOffset: Int
    
    var body: some View {
        HStack {
            Picker(selection: $notificationOffset) {
                Text("2 days before").tag(2)
                Text("1 day before").tag(1)
                Text("The day of").tag(0)
            } label: {
                Label {
                    Text(title)
                        .schemeBasedForegroundStyle()
                } icon: {
                    Image(systemName: "alarm")
                        .foregroundStyle(.gray)
                }
            }
        }
    }
}
