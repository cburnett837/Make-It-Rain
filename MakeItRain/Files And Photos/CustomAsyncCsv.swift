//
//  CustomAsyncCsv.swift
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


struct CustomAsyncCsv: View {
    var file: CBFile
    var displayStyle: FileSectionDisplayStyle
    
    @State private var page = WebPage()
    
    var body: some View {
        Group {
            if page.isLoading {
                LoadingPlaceholder(text: "Downloading…", displayStyle: displayStyle)
            } else {
                WebView(page)
            }
        }
        .frame(width: fileWidth, height: fileHeight)
        .clipShape(.rect(cornerRadius: 14))
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
