//
//  MessageComposerView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/19/26.
//


import SwiftUI
import ContactsUI
import Contacts
import MessageUI

struct MessageComposerView: UIViewControllerRepresentable {
    let phoneNumber: String?
    let messageBody: String
    let pdfURL: URL

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = context.coordinator
        vc.body = messageBody
        
        if let phoneNumber = phoneNumber {
            vc.recipients = [phoneNumber]
        }
        
//        if let sender = AppState.shared.user?.name {
//            vc.subject = "Invoice From \(sender)"
//        }

        if let data = try? Data(contentsOf: pdfURL) {
            vc.addAttachmentData(data, typeIdentifier: "com.adobe.pdf", filename: pdfURL.lastPathComponent)
        }

        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            dismiss()
        }
    }
}


struct MailComposerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss

    let subject: String
    let recipients: [String]
    let body: String

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView

        init(parent: MailComposerView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(subject)
        vc.setToRecipients(recipients)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}
