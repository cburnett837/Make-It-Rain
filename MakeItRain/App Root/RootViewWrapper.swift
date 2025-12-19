//
//  RootViewWrapper.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/6/25.
//


import SwiftUI
#if os(iOS)
import UIKit
#endif

struct RootViewWrapper<Content: View>: View {
    @Environment(FuncModel.self) var funcModel
    @Environment(DataChangeTriggers.self) var dataChangeTriggers
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    
    @Environment(PlaidModel.self) private var plaidModel
    //@Environment(MapModel.self) private var mapModel
    
    @Binding var showCamera: Bool

    
    @ViewBuilder var content: Content
        
    #if os(iOS)
    @State private var window: UIWindow?
    #endif
    
//    init(showCamera: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
//        self._showCamera = showCamera
//        self.content = content()
//    }
                        
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var appState = AppState.shared
        content
            #if os(iOS)
            .onAppear(perform: createOverlayWindow)
            .fullScreenCover(isPresented: $appState.showPaymentMethodNeededSheet, onDismiss: funcModel.downloadInitial) {
                PayMethodRequiredView()
            }
            .fullScreenCover(isPresented: $appState.hasBadConnection) {
                TempTransactionList()
            }
            #else
            .overlay {
                AlertAndToastLayerView()
                    .environment(funcModel)
                    .environment(calModel)
                    .environment(payModel)
                    .environment(catModel)
                    .environment(keyModel)
                    .environment(repModel)
                    .environment(plaidModel)
                    .environment(calProps)
                    .environment(dataChangeTriggers)
                    //.environment(mapModel)
            }
            .sheet(isPresented: $appState.showPaymentMethodNeededSheet, onDismiss: funcModel.downloadInitial) {
                PayMethodRequiredView()
                    .padding()
            }
            #endif
    }
    
    #if os(iOS)
    private func createOverlayWindow() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, window == nil {
            let rootVC = UIHostingController(rootView:
                AlertAndToastLayerView(showCamera: $showCamera)
                    .environment(funcModel)
                    .environment(calModel)
                    .environment(payModel)
                    .environment(catModel)
                    .environment(keyModel)
                    .environment(repModel)
                    .environment(plaidModel)
                    .environment(calProps)
                    .environment(dataChangeTriggers)
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
