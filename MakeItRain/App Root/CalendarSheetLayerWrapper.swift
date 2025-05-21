//
//  CalendarSheetLayerWrapper.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/6/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct CalendarSheetLayerWrapper<Content: View>: View {
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    @Environment(EventModel.self) private var eventModel
    //@Environment(MapModel.self) private var mapModel
    
    let monthNavigationNamespace: Namespace.ID
    
    var content: Content
        
    #if os(iOS)
    @State private var window: UIWindow?
    #else
    @State private var window: NSWindow?
    #endif
    
    init(monthNavigationNamespace: Namespace.ID, @ViewBuilder content: @escaping () -> Content) {
        self.monthNavigationNamespace = monthNavigationNamespace
        self.content = content()
    }
                        
    var body: some View {
        @Bindable var appState = AppState.shared
        content
            #if os(iOS)
            .onAppear(perform: createOverlayWindow)
            #else
            .onAppear {
//                guard window == nil else { return }
//
//                let overlay = NSHostingView(rootView:
//                    CalendarSheetLayerView()
//                        .environment(funcModel)
//                        .environment(calModel)
//                        .environment(payModel)
//                        .environment(catModel)
//                        .environment(keyModel)
//                        .environment(repModel)
//                        .environment(eventModel)
//                )
//
//                let window = OverlayWindow(
//                    contentRect: NSScreen.main?.frame ?? .zero,
//                    styleMask: [.borderless],
//                    backing: .buffered,
//                    defer: false
//                )
//                window.isOpaque = false
//                window.backgroundColor = .clear
//                window.level = .floating
//                window.contentView = overlay
//                window.makeKeyAndOrderFront(nil)
//
//                self.window = window
            }
            #endif
    }
    
    #if os(iOS)
    private func createOverlayWindow() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, window == nil {
            let rootVC = UIHostingController(rootView:
                CalendarSheetLayerView(monthNavigationNamespace: monthNavigationNamespace)
                    .environment(funcModel)
                    .environment(calModel)
                    .environment(payModel)
                    .environment(catModel)
                    .environment(keyModel)
                    .environment(repModel)
                    .environment(eventModel)
                    //.environment(mapModel)
            )
            rootVC.view.backgroundColor = .clear
            
            let window = PassThroughWindowPhone(windowScene: windowScene)
            window.isHidden = false
            window.isUserInteractionEnabled = true
            window.rootViewController = rootVC
            self.window = window
        }
    }
    #endif
}
