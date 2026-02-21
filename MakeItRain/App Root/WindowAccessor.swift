//
//  WindowAccessor.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/5/26.
//


import SwiftUI

#if os(macOS)
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
