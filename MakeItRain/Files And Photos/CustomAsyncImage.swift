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
        let fileModel = FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
        let requestModel = RequestModel(requestType: "download_file", model: fileModel)
        let result = await NetworkManager().downloadFile(requestModel: requestModel)
        
        switch result {
        case .success(let data):
            if let data = data {
                
                await ImageCache.shared.saveToCache(
                    parentTypeId: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction).id,
                    parentId: file.relatedID,
                    id: file.id,
                    data: data
                )
                
                #if os(iOS)
                    self.uiImage = UIImage(data: data)
                #else
                    self.nsImage = NSImage(data: data)
                #endif
            }
            
        case .failure(let error):
            switch error {
            case .taskCancelled:
                print("\(#function) Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem downloading the image.")
            }
        }
    }
}
