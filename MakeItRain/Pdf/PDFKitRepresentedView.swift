//
//  PDFKitRepresentedView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/22/26.
//

import SwiftUI
import PDFKit

struct PDFKitRepresentedView: UIViewRepresentable {
    @Environment(\.colorScheme) var colorScheme

    let pdfData: Data?
    let url: URL?
    
    init(pdfData: Data) {
        self.pdfData = pdfData
        self.url = nil
    }
    
    init(url: URL) {
        self.url = url
        self.pdfData = nil
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        if let url = url {
            pdfView.document = PDFDocument(url: url)
        } else if let pdfData = pdfData {
            pdfView.document = PDFDocument(data: pdfData)
        }
        
        pdfView.autoScales = true // Adjusts the PDF to fit the view
        pdfView.isUserInteractionEnabled = false
        //pdfView.backgroundColor = colorScheme == .dark ? .black : .white
        //pdfView.backgroundColor = .white
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let url = url {
            uiView.document = PDFDocument(url: url)
        } else if let pdfData = pdfData {
            uiView.document = PDFDocument(data: pdfData)
        }
    }
}
