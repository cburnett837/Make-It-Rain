//
//  CustomAsyncPdf.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/26/25.
//


import SwiftUI
import WebKit
import PDFKit

fileprivate let fileWidth: CGFloat = 125
fileprivate let fileHeight: CGFloat = 250
fileprivate let symbolWidth: CGFloat = 26


struct CustomAsyncPdf: View {
    var file: CBFile
    var displayStyle: FileSectionDisplayStyle

    @State private var data: Data?
            
    var body: some View {
        if let data = data {
            PDFKitRepresentedView(pdfData: data)
                .frame(width: fileWidth, height: fileHeight)
                .clipShape(.rect(cornerRadius: 14))
        } else {
            LoadingPlaceholder(text: "Downloading…", displayStyle: displayStyle)
                .task { await getFile() }
        }
    }
    
    func getFile() async {
        let fileModel = FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
        let requestModel = RequestModel(requestType: "download_file", model: fileModel)
        let result = await NetworkManager().downloadFile(requestModel: requestModel)
        
        switch result {
        case .success(let data):
            self.data = data
            
        case .failure:
            AppState.shared.showAlert("There was a problem downloading the file.")
        }
    }
}
