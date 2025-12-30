//
//  PhotoWebPreview.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/22/25.
//


import SwiftUI
import WebKit
import PDFKit

struct PhotoWebPreview: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var localFileURL: URL?
    @State private var isDownloading = false
    
    let file: CBFile
    
    var backgroundColor: Color {
        if file.fileType == .photo {
            .black
        } else {
            colorScheme == .dark ? .white : .black
        }
    }

    var body: some View {
        NavigationStack {
            #if os(iOS)
            WebViewRep(backgroundColor: backgroundColor, requestModel: RequestModel(
                requestType: "download_file",
                model: FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
            ))
            .task { await downloadFileForShareLink() }
            .navigationTitle("File Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { shareLink }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
    }

    @ViewBuilder
    var shareLink: some View {
        if let fileURL = localFileURL {
            ShareLink(item: fileURL) {
                Image(systemName: "square.and.arrow.up")
            }
            .schemeBasedForegroundStyle()
        } else {
            ProgressView()
                .schemeBasedTint()
        }
    }

    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    func downloadFileForShareLink() async {
        isDownloading = true
        defer { isDownloading = false }
        
        let requestModel = RequestModel(
            requestType: "download_file",
            model: FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
        )
        
        let jsonData = try? JSONEncoder().encode(requestModel)
        var request = NetworkManager().request
        request!.setValue(AppState.shared.apiKey, forHTTPHeaderField: "Api-Key")
        request!.httpBody = jsonData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request!)
            let now = Date().string(to: .serverDateTime)
            let fileName = "make_it_rain_document_\(now)"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).\(file.fileType.ext)")
            try data.write(to: tempURL)
            await MainActor.run {
                localFileURL = tempURL
            }
        } catch {
            print("Download failed: \(error)")
        }
    }
}