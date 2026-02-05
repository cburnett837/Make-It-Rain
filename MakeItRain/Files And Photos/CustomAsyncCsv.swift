//
//  CustomAsyncCsv.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/26/25.
//


import SwiftUI
import WebKit
import PDFKit

#if os(iOS)
struct CustomAsyncCsv: View {
    var file: CBFile
    var displayStyle: FileSectionDisplayStyle
    var useDefaultFrame: Bool = true
    
    @State private var page = WebPage()
    
    var body: some View {
        Group {
            if page.isLoading {
                LoadingPlaceholder(text: "Downloading…", displayStyle: displayStyle, useDefaultFrame: useDefaultFrame)
            } else {
                WebView(page)
            }
        }
        .if(useDefaultFrame) {
            $0
            .frame(width: 125, height: 250)
            .clipShape(.rect(cornerRadius: 14))
        }
        .task {
            let requestModel = RequestModel(
                requestType: "download_file",
                model: FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
            )
            
            let jsonData = try? JSONEncoder().encode(requestModel)
            var request = NetworkManager().request
            request!.setValue(AppState.shared.apiKey, forHTTPHeaderField: "Api-Key")
            request!.httpBody = jsonData
            
            page.load(request!)
        }
            
            
            
                
            
//            WebViewRep(requestModel: RequestModel(
//                requestType: "download_file",
//                model: FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
//            ))
//            .frame(width: fileWidth, height: fileHeight)
//            .clipShape(.rect(cornerRadius: 14))
    }
}
#endif
