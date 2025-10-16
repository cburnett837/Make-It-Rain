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
    @Local(\.colorTheme) var colorTheme
    var toast: Toast?
    let timer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()
        
    var body: some View {
        HStack(spacing: 12) {
            symbol
            
            VStack(alignment: .leading, spacing: 0) {
                header
                title
                message
            }
            
            Spacer(minLength: 0)
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
        .glassEffect(in: .rect(cornerRadius: 24))
        .scenePadding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .center)
        .transition(.asymmetric(insertion: .offset(y: -200), removal: .offset(y: -200))) // top
        .onReceive(timer) { _ in dismissToast() }
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
                .fill(toast.symbolColor == nil ? Color.fromName(colorTheme) : Color(toast.symbolColor!))
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







struct ToastViewWithButtonThatDoesntWorkThanksToIos26: View {
    @Local(\.colorTheme) var colorTheme
    var toast: Toast?
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
        
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast?.symbol ?? "")
                .if(toast?.symbolColor == Color.white || toast?.symbolColor == Color.black) {
                    $0.foregroundStyle(toast?.symbolColor == Color.white ? Color.black : Color.white)
                }
                .padding(10)
                .background {
                    if let toast = toast {
                        RoundedRectangle(cornerRadius: 8)
                            //.fill(Color.fromName(toast.symbolColor == nil ? colorTheme : toast.symbolColor!.description))
                                                
                            .fill(
                                toast.symbolColor == nil
                                ? Color.fromName(colorTheme)
                                : Color(toast.symbolColor!)
                            )
                        
                            //.fill(.ultraThickMaterial)
                            .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
                            .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
                            .frame(width: 30, height: 30)
                    }
                }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(toast?.header ?? "")
                    .font(.callout)
                    .bold()
                
                if let title = toast?.title {
                    Text(title)
                        .font(.caption2)
                }
                
                if let message = toast?.message {
                    Text(message)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer(minLength: 0)
            
            Button {
                withAnimation(.bouncy) {
                    AppState.shared.toast = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .gesture(DragGesture()
            .onEnded { value in
                if value.translation.height < 50 {
                    withAnimation(.bouncy) {
                        AppState.shared.toast = nil
                    }
                }
            }
        )
        .onTapGesture {
            if let toast = toast {
                toast.action()
            }
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
        .padding(.leading, 15)
        .padding(.trailing, 10)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
        }
        .padding(.horizontal, 15)
        .offset(y: 15)
        #if os(macOS)
        .frame(maxWidth: .infinity, alignment: .center)
        #else
        .frame(maxWidth: .infinity)
        #endif
        .transition(.asymmetric(insertion: .offset(y: -200), removal: .offset(y: -200))) // top
        .onReceive(timer) { _ in
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
}


