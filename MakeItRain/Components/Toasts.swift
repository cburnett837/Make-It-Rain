//
//  Toasts.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/22/24.
//

import SwiftUI

struct Toast {
    var header: String
    var title: String?
    var message: String?
    var symbol: String
    var symbolColor: Color? = nil
}

struct ToastView: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    var toast: Toast?
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
        
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast?.symbol ?? "")
                .padding(10)
                .background {
                    if let toast = toast {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.fromName(toast.symbolColor == nil ? appColorTheme : toast.symbolColor!.description))
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
        #if os(macOS)
            .frame(maxWidth: 400)
        #endif
        .foregroundStyle(.primary)
        .padding(.vertical, 12)
        .padding(.leading, 15)
        .padding(.trailing, 10)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
        }
        .padding(.horizontal, 15)
        .offset(y: 15)
        #if os(macOS)
        .frame(maxWidth: .infinity, alignment: .trailing)
        #else
        .frame(maxWidth: .infinity)
        #endif
        .transition(.asymmetric(insertion: .offset(y: -200), removal: .offset(y: -200))) // top
        .onReceive(timer) { _ in
            timer.upstream.connect().cancel()
            
            withAnimation(.bouncy) {
                AppState.shared.toast = nil
            }
        }
    }
}
