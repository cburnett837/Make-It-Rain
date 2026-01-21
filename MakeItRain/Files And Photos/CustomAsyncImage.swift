//
//  CustomAsyncImage.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/26/25.
//


import SwiftUI
import WebKit
import PDFKit

struct CustomAsyncImage<Content: View, Placeholder: View>: View {
    @Environment(FuncModel.self) var funcModel
    #if os(iOS)
    @State private var uiImage: UIImage?
    #else
    @State private var nsImage: NSImage?
    #endif

    var file: CBFile
    @ViewBuilder var content: (Image) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    var body: some View {
        #if os(iOS)
            if let uiImage = uiImage {
                content(Image(uiImage: uiImage))
            } else if let image = ImageCache.shared.loadFromCache(
                parentTypeId: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction).id,
                parentId: file.relatedID,
                id: file.id
            ) {
                content(Image(uiImage: image))
            } else {
                placeholder().task { await getImage() }
            }
        #else
            if let nsImage = nsImage {
                content(Image(nsImage: nsImage))
            } else {
                placeholder().task { await getImage() }
            }
        #endif
    }
    
    func getImage() async {
        
        if let data = await funcModel.downloadFile(file: file) {
            #if os(iOS)
                self.uiImage = UIImage(data: data)
            #else
                self.nsImage = NSImage(data: data)
            #endif
        }
    }
}
