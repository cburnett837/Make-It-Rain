//
//  ToolbarLongPollButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/31/25.
//

import SwiftUI

struct ToolbarLongPollButton: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @Environment(FuncModel.self) var funcModel
    
    var body: some View {
        Group {
            if AppState.shared.longPollFailed {
                Button {
                    let config = AlertConfig(
                        title: "Attempting to resubscribe to multi-device updates",
                        subtitle: "If this keeps failing please contact the developer.",
                        symbol: .init(name: "ipad.and.iphone", color: .green)
                    )
                    AppState.shared.showAlert(config: config)
                    
                    Task {
                        AppState.shared.longPollFailed = false
                        await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: false, refreshTechnique: .viaButton)
                        //funcModel.longPollServerForChanges()
                    }
                } label: {
                    Image(systemName: "ipad.and.iphone.slash")
                        .foregroundStyle(Color.fromName(appColorTheme) == .red ? .orange : .red)
                }
            }
        }
    }
}
