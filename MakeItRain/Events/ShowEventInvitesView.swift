//
//  ShowEventInvitesView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/24/25.
//

import SwiftUI

struct ShowEventInvitesView: View {
    @State private var showPendingInviteSheet = false

    var body: some View {
        Button {
            showPendingInviteSheet = true
        } label: {
            Image(systemName: "envelope.badge")
                .foregroundStyle(.red)
        }
        .sheet(isPresented: $showPendingInviteSheet) {
            EventPendingInviteView()
        }
    }
}
