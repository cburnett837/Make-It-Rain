//
//  InvoiceCreationModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/26.
//


import SwiftUI
import MessageUI
import Contacts

@Observable
class PdfInvoiceCreatorModel {
    enum InvoiceType: String, CaseIterable {
        case invoice, receipt
    }
    var trans: CBTransaction?
    var date: Date = Date()
    var amountString: String = ""
    
    var selectedPhone: String?
    var selectedContact: CNContact?
    var selectedReceipt: CBFile?
    var pdfUrl: URL?
    var invoiceType: InvoiceType = .invoice

    var canSendTextAndAttachments: Bool {
        MFMessageComposeViewController.canSendText() && MFMessageComposeViewController.canSendAttachments()
    }
    
    var amount: Double {
        Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    
    var messagePlaceholder: String {
        let contactString = contactName.isEmpty ? "" : " \(contactName)"
        let lingo = invoiceType == .invoice ? "an invoice" : "a receipt"
        let title = trans?.title ?? "N/A"
        let date = trans?.date?.string(to: .monthDayShortYear) ?? "N/A"
        return "Hey\(contactString), here is \(lingo) for \(title) from \(date)"
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
        let properAmount = trans.amount < 0 ? trans.amount * -1 : trans.amount
        self.amountString = properAmount.currencyWithDecimals()
        if let date = trans.date { self.date = date }
    }
    
    func createInvoice() async {
        if let trans = trans {
            let properAmount = amount < 0 ? amount * -1 : amount
            
            let fileUrl: URL? = try? await PdfMaker.create(pageCount: 1, fileName: fileName) { pageIndex in
                PdfInvoiceViewForSingleTransaction(
                    pageIndex: pageIndex,
                    trans: trans,
                    contact: selectedContact,
                    amount: properAmount,
                    date: date,
                    receipt: selectedReceipt,
                    invoiceType: invoiceType
                )
            }
            
            if let url = fileUrl {
                self.pdfUrl = url
            }
        }
    }
}
