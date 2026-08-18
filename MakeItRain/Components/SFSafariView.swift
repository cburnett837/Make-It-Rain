//
//  SafariViewStuff.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/24/24.
//

import SwiftUI
import SafariServices
import WebKit

#if os(iOS)
struct SFSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SFSafariView>) {
        // No need to do anything here
    }
}


struct WebViewRep: UIViewRepresentable {
    let backgroundColor: Color?
    let requestModel: RequestModel<FileRequestModel>
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = UIColor(backgroundColor ?? .primary)
        
        do {
            let networkManager = NetworkManager()
            var request = networkManager.createRequest()
            request.setValue(AppState.shared.apiKey, forHTTPHeaderField: "Api-Key")
            request.httpBody = try JSONEncoder().encode(requestModel)
            webView.load(request)
            return webView
            
        } catch {
            let html = """
            <html>
                <body>
                    Could not create webview \(error)
                </body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: nil)
            return webView
        }
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) { }
}



#endif
