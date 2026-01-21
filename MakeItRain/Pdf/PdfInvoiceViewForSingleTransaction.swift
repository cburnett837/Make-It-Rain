//
//  InvoicePdfViewForSingleTransaction.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/19/26.
//


import SwiftUI
import Contacts

struct PdfInvoiceViewForSingleTransaction: View {
    var pageIndex: Int
    var trans: CBTransaction
    var contact: CNContact?
    var amount: Double
    var date: Date
    var receipt: CBFile?
    var invoiceType: PdfInvoiceCreatorModel.InvoiceType
            
    var invoiceTypeLingo: String {
        switch invoiceType {
        case .invoice: "INVOICE"
        case .receipt: "RECEIPT"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 10) {
                Text(invoiceTypeLingo)
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
            }
            .frame(height: 50)
            
            Spacer()
                .frame(height: 75)
            
            HStack(alignment: .circleAndTitle) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        if let contact = contact {
                            Text("ISSUED TO:")
                                .bold()
                            Text(CNContactFormatter().string(from: contact) ?? "N/A")
                        }
                    }
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.top] })
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(invoiceTypeLingo) NO:")
                    Text("\(invoiceTypeLingo) DATE:")
                    Text("DUE DATE:")
                }
                .bold()
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.top] })
                                
                VStack(alignment: .trailing) {
                    Text("\(trans.id)")
                    Text("\(date.string(to: .monthDayShortYear))")
                    Text("N/A")
                }
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.top] })
            }
                
            
            Divider()
            
            
            Grid(alignment: .leading) {
                GridRow(alignment: .top) {
                    Text("Title")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Amount")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !trans.locations.isEmpty {
                        Text("Location")
                    }
                }
                .bold()
                
                GridRow(alignment: .top) {
                    Text(trans.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(amount.currencyWithDecimals())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !trans.locations.isEmpty {
                        Text(trans.locations.first?.mapItem?.address?.shortAddress ?? "N/A")
                    }
                }
            }
            
            if let receipt = receipt {
                if let image = ImageCache.shared.loadFromCache(
                    parentTypeId: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction).id,
                    parentId: trans.id,
                    id: receipt.id
                ) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 325, height: 500)
                }
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ContentUnavailableView("No Scanned Images", systemImage: "receipt")
                    }
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white)
        .environment(\.colorScheme, .light)
    }
}
