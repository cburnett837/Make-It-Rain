//
//  Toasts.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/22/24.
//

import SwiftUI

struct Toast {
    var header: String
    var title: String? = nil
    var message: String? = nil
    var symbol: String
    var symbolColor: Color? = nil
    var autoDismiss = true
    var action: () -> Void = {}
}

struct ToastView: View {
    //@Local(\.colorTheme) var colorTheme
    var toast: Toast?
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var buzz = false
        
    var body: some View {
        HStack(spacing: 12) {
            symbol
            
            VStack(alignment: .leading, spacing: 0) {
                header
                title
                message
            }
            
            Spacer(minLength: 0)
            
            closeButton
        }
        #if os(macOS)
            .frame(maxWidth: 400)
        #else
            .if(AppState.shared.isIpad) {
                $0.frame(maxWidth: 400)
            }
        #endif
        .foregroundStyle(.primary)
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        #if os(iOS)
        .glassEffect(in: .rect(cornerRadius: 24))        
        #endif
        //.sensoryFeedback(.warning, trigger: buzz) { $1 }
        .scenePadding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .center)
        .contentShape(Rectangle())
        .transition(.asymmetric(insertion: .offset(y: -200), removal: .offset(y: -200))) // top
        .onReceive(timer) { _ in dismissToast() }
        .onTapGesture {
            print("Toast tapped")
            if let toast = toast {
                toast.action()
            }
        }
        
//        .onAppear {
//            buzz.toggle()
//        }
        .gesture(DragGesture() .onEnded { if $0.translation.height < 50 { dismissToast() } })
    }
    
    @ViewBuilder var symbol: some View {
        Image(systemName: toast?.symbol ?? "")
            .if(toast?.symbolColor == Color.white || toast?.symbolColor == Color.black) {
                $0.foregroundStyle(toast?.symbolColor == Color.white ? Color.black : Color.white)
            }
            .padding(10)
            .background(symbolBackground)
    }
    
    @ViewBuilder var symbolBackground: some View {
        if let toast = toast {
            RoundedRectangle(cornerRadius: 8)
                .fill(toast.symbolColor == nil ? Color.theme : Color(toast.symbolColor!))
                .frame(width: 30, height: 30)
        }
    }
    
    @ViewBuilder var header: some View {
        Text(toast?.header ?? "")
            .font(.callout)
            .bold()
    }
    
    @ViewBuilder var title: some View {
        if let title = toast?.title {
            Text(title)
                .font(.caption2)
        }
    }
    
    @ViewBuilder var message: some View {
        if let message = toast?.message {
            Text(message)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }
    
    var closeButton: some View {
        Button {
            dismissToast()
        } label: {
            Image(systemName: "xmark")
                .padding(4)
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }
    
    func dismissToast() {
        timer.upstream.connect().cancel()
        if let toast = toast {
            if toast.autoDismiss {
                withAnimation(.bouncy) {
                    AppState.shared.toast = nil
                }
            }
        }
    }
}
