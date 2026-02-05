//
//  PDFKitView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/4/25.
//


import SwiftUI
import PDFKit

#if os(iOS)
struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        pdfView.autoScales = true // Adjusts the PDF to fit the view
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update the view if the URL changes, for instance
        uiView.document = PDFDocument(url: self.url)
    }
}
#endif
