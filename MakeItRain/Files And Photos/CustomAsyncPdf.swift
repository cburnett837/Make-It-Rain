//
//  CustomAsyncPdf.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/26/25.
//


import SwiftUI
import WebKit
import PDFKit

#if os(iOS)
struct CustomAsyncPdf: View {
    var file: CBFile
    var displayStyle: FileSectionDisplayStyle
    var useDefaultFrame: Bool = true
        
    @State private var data: Data?
            
    var body: some View {
        if let data = data {
            PDFKitRepresentedView(pdfData: data)
                .if(useDefaultFrame) {
                    $0
                    .frame(width: 125, height: 250)
                    .clipShape(.rect(cornerRadius: 14))
                }
        } else {
            LoadingPlaceholder(text: "Downloading…", displayStyle: displayStyle, useDefaultFrame: useDefaultFrame)
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
#endif
