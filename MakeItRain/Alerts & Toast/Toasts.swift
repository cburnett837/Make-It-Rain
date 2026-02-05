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
    var logo: LogoConfig?
    //var logoStrokeColor: Color?
    var autoDismiss = true
    var action: () -> Void = {}
}

extension AppState {
    func alertBasedOnScenePhase(
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        symbol: String = "exclamationmark.triangle",
        symbolColor: Color? = .orange,
        logo: LogoConfig? = nil,
        inAppPreference: InAppAlertPreference = .toast
    ) {
        #if os(iOS)
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            NotificationManager.shared.sendNotification(title: title, subtitle: subtitle, body: body)
        } else {
            switch inAppPreference {
            case .alert:
                //showAlert(title)
                
                let alertConfig = AlertConfig(title: title, subtitle: subtitle, symbol: .init(name: symbol, color: symbolColor))
                showAlert(config: alertConfig)
                
            case .toast:
                showToast(
                    title: title,
                    subtitle: subtitle,
                    body: body,
                    symbol: symbol,
                    symbolColor: symbolColor,
                    logo: logo
                )
            }
        }
        #else
        switch inAppPreference {
        case .alert:
            showAlert(title)
        case .toast:
            showToast(
                title: title,
                subtitle: subtitle,
                body: body,
                symbol: symbol,
                symbolColor: symbolColor,
                logo: logo
            )
        }
        #endif
    }
    
    
    func showToast(
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        symbol: String = "coloncurrencysign.circle",
        symbolColor: Color? = nil,
        logo: LogoConfig? = nil,
        autoDismiss: Bool = true,
        action: @escaping () -> Void = {}
    ) {
        withAnimation(.bouncy) {
            //DispatchQueue.main.async {
            #if os(iOS)
            Helpers.buzzPhone(.success)
            #endif
            self.toast = Toast(
                header: title,
                title: subtitle,
                message: body,
                symbol: symbol,
                symbolColor: symbolColor,
                logo: logo,
                autoDismiss: autoDismiss,
                action: action
            )
            //}
        }
        
        
        let id = UUID().uuidString
        
        AppState.shared.unreadToasts.append(id)
        
        let context = DataManager.shared.container.viewContext
        
        if let perToast = DataManager.shared.getOne(context: context, type: PersistentToast.self, predicate: .byId(.string(id)), createIfNotFound: true) {
            perToast.id = id
            perToast.title = title
            perToast.subtitle = subtitle ?? ""
            perToast.body = body ?? ""
            perToast.symbol = symbol
            perToast.hexCode = symbolColor?.toHex() ?? ""
            perToast.enteredDate = Date()
            print(perToast)
            let saveResult = DataManager.shared.save(context: context)
            print(saveResult)
        } else {
            print("no per toast")
        }
        
    }
}

struct ToastView: View {
    //@Local(\.colorTheme) var colorTheme
    var toast: Toast?
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var buzz = false
        
    var body: some View {
        HStack(spacing: 12) {            
            logoOrSymbol
            
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
        #else
        .background(.thinMaterial, in: .rect(cornerRadius: 24))
        #endif
        .padding(.top, 40)
        //.sensoryFeedback(.warning, trigger: buzz) { $1 }
        .scenePadding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .center)
        .contentShape(Rectangle())
        .transition(.asymmetric(insertion: .offset(y: -200), removal: .offset(y: -200))) // top
        .onReceive(timer) { _ in dismissToast(wasFromUser: false) }
        .onTapGesture {
            print("Toast tapped")
            if let toast = toast {
                toast.action()
            }
        }
        
//        .onAppear {
//            buzz.toggle()
//        }
        .gesture(DragGesture() .onEnded { if $0.translation.height < 50 { dismissToast(wasFromUser: true) } })
    }
    
    @ViewBuilder var logoOrSymbol: some View {
        if let logoConfig = toast?.logo, let _ = logoConfig.parent?.logo {
            BusinessLogo(config: .init(
                parent: logoConfig.parent,
                fallBackType: logoConfig.fallBackType,
                size: logoConfig.size
            ))
            
        } else if case let .customImage(imageConfig) = toast?.logo?.fallBackType {
            symbolImage(name: imageConfig?.name, color: imageConfig?.color)
            
        } else {
            symbolImage(name: toast?.symbol, color: toast?.symbolColor)
        }
    }
    
    @ViewBuilder
    func symbolImage(name: String?, color: Color?) -> some View {
//        Image(systemName: name ?? "exclamationmark.triangle.fill")
//            .font(.title)
//            .foregroundStyle(.primary)
//            .frame(width: 65, height: 65)
//            .background((color ?? .primary).gradient, in: .circle)
//            .background {
//                Circle()
//                    .stroke(.background, lineWidth: 8)
//            }
        
        
        Image(systemName: name ?? "exclamationmark.triangle.fill")
            .if(toast?.symbolColor == Color.white || toast?.symbolColor == Color.black) {
                $0.foregroundStyle(toast?.symbolColor == Color.white ? Color.black : Color.white)
            }
            .padding(10)
            .background(symbolBackground(color: color))
    }
    
    
//    @ViewBuilder var symbol: some View {
//        Image(systemName: toast?.symbol ?? "")
//            .if(toast?.symbolColor == Color.white || toast?.symbolColor == Color.black) {
//                $0.foregroundStyle(toast?.symbolColor == Color.white ? Color.black : Color.white)
//            }
//            .padding(10)
//            .background(symbolBackground)
//    }
    
    @ViewBuilder func symbolBackground(color: Color?) -> some View {
        Circle()
            .fill(color ?? Color.theme)
            .frame(width: 30, height: 30)
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
            dismissToast(wasFromUser: true)
        } label: {
            Image(systemName: "xmark")
                .padding(4)
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }
    
    func dismissToast(wasFromUser: Bool) {
        timer.upstream.connect().cancel()
        if let toast = toast {
            if toast.autoDismiss || wasFromUser {
                withAnimation(.bouncy) {
                    AppState.shared.toast = nil
                }
            }
        }
    }
}
