//
//  PdfInvoiceCreatorMessagingUnavailableView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/26.
//


import SwiftUI

struct ThereWasAProblemFullScreenView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let text: LocalizedStringKey

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom))
            
            Text(title)
                .font(.title)
            
            Text(text)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .schemeBasedForegroundStyle()
            }
            #if os(iOS)
            .buttonStyle(.glassProminent)
            #endif
        }
        .scenePadding()
    }
}
