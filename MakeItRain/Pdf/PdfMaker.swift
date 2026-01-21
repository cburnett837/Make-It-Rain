//
//  PdfMaker.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/19/26.
//


import SwiftUI

@MainActor
struct PdfMaker {
    
    static func create<PageContent: View>(
        _ pageSize: PageSize = .a4(),
        pageCount: Int,
        fileName: String,
        format: UIGraphicsPDFRendererFormat = .default(),
        @ViewBuilder pageContent: (_ pageIndex: Int) -> PageContent
    ) throws -> URL? {
        let fileURL = FileManager.default.temporaryDirectory.appending(path: "\(fileName).pdf")
        
        let size = pageSize.size
        let rect = CGRect(origin: .zero, size: size)
        
        let renderer = UIGraphicsPDFRenderer(bounds: rect, format: format)
        try renderer.writePDF(to: fileURL) { context in
            for index in 0..<pageCount {
                context.beginPage()
                
                let pageContent = pageContent(index)
                let swiftUiRendered = ImageRenderer(content: pageContent.frame(width: size.width, height: size.height))
                swiftUiRendered.proposedSize = .init(size)
                
                context.cgContext.translateBy(x: 0, y: size.height)
                context.cgContext.scaleBy(x: 1, y: -1)
                                
                swiftUiRendered.render { _, swiftUiContext in
                    swiftUiContext(context.cgContext)
                    
                }
            }
        }
        
        return fileURL
    }
    
    struct PageSize {
        let size: CGSize
        
        init(width: CGFloat, height: CGFloat) {
            self.size = .init(width: width, height: height)
        }
        
        static func a4() -> Self { .init(width: 595.2, height: 841.8) }
        static func usLetter() -> Self { .init(width: 612, height: 792) }
    }
}
