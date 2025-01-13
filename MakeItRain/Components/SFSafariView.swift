//
//  SafariViewStuff.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/24/24.
//

import SwiftUI
import SafariServices

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
#endif
