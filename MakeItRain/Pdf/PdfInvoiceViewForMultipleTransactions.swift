//
//  InvoicePdfViewForMultipleTransactions.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/19/26.
//


import SwiftUI

struct PdfInvoiceViewForMultipleTransactions: View {
    var pageIndex: Int
    var trans: CBTransaction
    var invoiceType: PdfInvoiceCreatorModel.InvoiceType
    
    
    var body: some View {
        VStack {
            headerView()
            
            Text("Transaction ID: \(trans.id)")
                .padding()
            
            if let files = trans.files {
                ForEach(files) { file in
                    if let image = ImageCache.shared.loadFromCache(
                        parentTypeId: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction).id,
                        parentId: trans.id,
                        id: file.id
                    ) {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 200, height: 300)
                    }
                }
            }
            
            
            //Text("Date: \(trans.date, formatter: dateFormatter)")
        }
        .padding(15)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay(alignment: .bottom) {
            Text("\(pageIndex + 1)")
                .font(.caption)
                .fontWeight(.semibold)
                .offset(y: -8)
        }
        .background(.white)
        .environment(\.colorScheme, .light)
    }
    
    
    @ViewBuilder
    func headerView() -> some View {
        HStack(spacing: 10) {
            Image(systemName: "cloud.rain")
                .font(.largeTitle)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(.black, in: .rect(cornerRadius: 15))
            
            VStack(alignment: .leading) {
                Text("Invoice")
                    .font(.largeTitle)
                
                Text(trans.date?.string(to: .monthDayShortYear) ?? "N/A")
                    .font(.largeTitle)
            }
            .padding()
        }
        .frame(height: 50)
        .frame(height: 80, alignment: .top)
    }
}
