//
//  InvoiceCreationModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/26.
//


import SwiftUI
#if os(iOS)
import MessageUI
#endif
import Contacts

@Observable
class PdfInvoiceCreatorModel {
    enum InvoiceType: String, CaseIterable {
        case invoice, receipt
    }
    var trans: CBTransaction?
    var title: String = ""
    var amountString: String = ""
    var date: Date = Date()
    var recipient: String = ""
    var contactSearchResults: [CNContact] = []
    private let store = CNContactStore()
    
    //var selectedPhone: String?
    var selectedContact: CNContact?
    var selectedReceipt: CBFile?
    var pdfUrl: URL?
    var invoiceType: InvoiceType = .invoice
        
    
    var canSendTextAndAttachments: Bool {
        #if os(iOS)
        MFMessageComposeViewController.canSendText() && MFMessageComposeViewController.canSendAttachments()
        #else
        return false
        #endif
    }
    
    
    var amount: Double {
        Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    
    
    var messagePlaceholder: String {
        let contactString = contactName.isEmpty ? "" : " \(contactName)"
        //let lingoLower = invoiceTypeLingo.lowercased()
        let lingo = invoiceType == .invoice ? "an invoice" : "a receipt"
        let title = trans?.title ?? "N/A"
        let date = trans?.date?.string(to: .monthDayShortYear) ?? "N/A"
        return "Hey\(contactString), here is \(lingo) for \(title) from \(date)"
    }
    
    
    var cantSendMessageReason: LocalizedStringKey {
        #if os(iOS)
        if let contact = selectedContact, contact.phoneNumbers.first?.value == nil {
            return "**\(contactName)** does not have a phone number associated with them."
            
        } else if pdfUrl == nil {
            return "There was a problem generating the PDF."
            
        } else if !MFMessageComposeViewController.canSendText() {
            return "This device is not capable of sending text messages."
            
        } else if !MFMessageComposeViewController.canSendAttachments() {
            return "This device is not capable of sending attachments."
        }
        return "An unknown error occured."
        #else
        return "Not available on Mac."
        #endif
    }
    
    
    var invoiceTypeLingo: String {
        switch invoiceType {
        case .invoice: "Invoice"
        case .receipt: "Receipt"
        }
    }
    
    
    var fileName: String {
        return "\(invoiceTypeLingo)-\(trans?.title ?? "")-\(trans?.date?.string(to: .invoiceDate) ?? "N/A")"
    }
    
    
    var contactName: String {
        if let name = selectedContact?.givenName { return "\(name)" }
        return ""
    }
    
    
    func prepareSelf(trans: CBTransaction) {
        self.trans = trans
        
        self.title = trans.title
        
        let properAmount = trans.amount < 0 ? trans.amount * -1 : trans.amount
        self.amountString = properAmount.currencyWithDecimals()
        
//        if let date = trans.date {
//            self.date = date
//        }
    }
    
    
    func createInvoice() async {
        if let trans = trans {
            let properAmount = amount < 0 ? amount * -1 : amount
            
            #if os(iOS)
            let fileUrl: URL? = try? await PdfMaker.create(pageCount: 1, fileName: fileName) { pageIndex in
                PdfInvoiceViewForSingleTransaction(
                    pageIndex: pageIndex,
                    trans: trans,
                    contact: selectedContact,
                    title: title,
                    amount: properAmount,
                    date: date,
                    receipt: selectedReceipt,
                    invoiceType: invoiceType
                )
            }
            
            if let url = fileUrl {
                self.pdfUrl = url
            }
            #endif
        }
    }
    

    func liveSearchContacts() {
        guard !recipient.isEmpty else {
            contactSearchResults = []
            return
        }

        let predicate = CNContact.predicateForContacts(matchingName: recipient)
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactImageDataKey as any CNKeyDescriptor,
            CNContactImageDataAvailableKey as any CNKeyDescriptor,
            CNContactThumbnailImageDataKey as any CNKeyDescriptor
        ]

        do {
            contactSearchResults = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
        } catch {
            print("Contact search failed:", error)
        }
    }
}
