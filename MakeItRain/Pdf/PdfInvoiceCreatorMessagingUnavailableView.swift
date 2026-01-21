//
//  PdfInvoiceCreatorMessagingUnavailableView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/26.
//


import SwiftUI
import MessageUI
import Contacts

struct PdfInvoiceCreatorMessagingUnavailableView: View {
    @Environment(\.dismiss) var dismiss

    var model: PdfInvoiceCreatorModel
    
    var reasonText: LocalizedStringKey {
        if model.selectedPhone == nil {
            if model.contactName.isEmpty {
               return "Please select a valid contact."
            } else {
                return "**\(model.contactName)** does not have a phone number associated with them."
            }
            
        } else if model.pdfUrl == nil {
            return "There was a problem generating the PDF."
            
        } else if !MFMessageComposeViewController.canSendText() {
            return "This device is not capable of sending text messages."
            
        } else if !MFMessageComposeViewController.canSendAttachments() {
            return "This device is not capable of sending attachments."
        }
        return "An unknown error occured."
    }
    
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom))
            
            Text("Messaging Error")
                .font(.title)
            
            Text(reasonText)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .schemeBasedForegroundStyle()
            }
            .buttonStyle(.glassProminent)
        }
        .scenePadding()
    }
}
