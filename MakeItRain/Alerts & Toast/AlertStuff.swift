//
//  AlertStuff.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/28/25.
//

import SwiftUI


struct CustomAlert: View {
    let config: AlertConfig
    
    let cancelButtonConfig = AlertConfig.ButtonConfig(text: "Cancel", role: .cancel) {
        AppState.shared.closeAlert()
    }
    
    var body: some View {
        VStack {
            if let logoConfig = config.logo, let image = logoConfig.parent?.logo {
                BusinessLogo(config: .init(
                    parent: logoConfig.parent,
                    fallBackType: logoConfig.fallBackType,
                    size: logoConfig.size
                ))
                .frame(width: 65, height: 65)
                .background {
                    Circle()
                        #if os(iOS)
                        .stroke(config.logoStrokeColor ?? Color(uiColor: .systemBackground), lineWidth: 8)
                        #endif
                }
            } else if case let .customImage(imageConfig) = config.logo?.fallBackType {
                symbolImage(name: imageConfig?.name, color: imageConfig?.color)
                
            } else {
                symbolImage(name: config.symbol.name, color: config.symbol.color)
            }
            
            VStack(spacing: 4) {
                title
                if let subtitleView = config.subtitleView {
                    subtitleView
                } else {
                    subtitle
                }
                
            }
            .padding(.bottom, 8)
            
                        
            if !config.views.isEmpty {
                List(config.views) { view in
                    view.content
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
            
            if config.primaryButton == nil && config.secondaryButton == nil {
                AlertConfig.AlertButton(config: cancelButtonConfig)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                buttonGroup
            }
        }
        .padding(.vertical, 12)
        .scenePadding(.horizontal)
        .background(glassBackground)
        .frame(maxWidth: 310)
        .compositingGroup()
    }
    
    
    @ViewBuilder
    func symbolImage(name: String?, color: Color?) -> some View {
        Image(systemName: name ?? "exclamationmark.triangle.fill")
            .font(.title)
            .foregroundStyle(.primary)
            .frame(width: 65, height: 65)
            .background((color ?? .primary).gradient, in: .circle)
            .background {
                Circle()
                    .stroke(.background, lineWidth: 8)
            }
    }
    
    @ViewBuilder
    var title: some View {
        Text(config.title)
            .font(.title3.bold())
            .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    var subtitle: some View {
        if let subtitle = config.subtitle {
            Text(subtitle)
                .font(.callout)
                .multilineTextAlignment(.center)
                .lineLimit(5)
                .foregroundStyle(.gray)
            //.padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    var glassBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .opacity(0)
            #if os(iOS)
            .glassEffect(.regular, in: .rect(cornerRadius: 24))
            #endif
            .padding(.top, 40)
    }
    
    @ViewBuilder
    var buttonGroup: some View {
        HStack(spacing: 4) {
            if let button = config.secondaryButton {
                button
            } else {
                if let _ = config.primaryButton {
                    AlertConfig.AlertButton(config: cancelButtonConfig)
                } else {
                    AlertConfig.AlertButton(config: cancelButtonConfig)
                }
            }
            
            if let button = config.primaryButton {
                button
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}




extension AppState {
    func showAlert(_ text: String) {
        withAnimation(.snappy(duration: 0.2)) {
            let config = AlertConfig(title: text)
            self.alertConfig = config
            self.showCustomAlert = true
        }
    }
    
    func showAlert(title: String, subtitle: String) {
        withAnimation(.snappy(duration: 0.2)) {
            let config = AlertConfig(title: title, subtitle: subtitle)
            self.alertConfig = config
            self.showCustomAlert = true
        }
    }
            
    func showAlert(config: AlertConfig) {
        withAnimation(.snappy(duration: 0.2)) {
            self.alertConfig = config
            self.showCustomAlert = true
        }
    }
    
    func closeAlert() {
        withAnimation(.snappy(duration: 0.2)) {
            self.alertConfig = nil
            self.showCustomAlert = false
        }
    }
}


struct SymbolConfig {
    var name: String?
    var color: Color? = .primary
}


struct AlertConfig {
    var title: String
    var subtitle: String?
    var subtitleView: AnyView?
    var symbol: SymbolConfig = .init(name: "exclamationmark.triangle.fill", color: .orange)
    var logo: LogoConfig?
    var logoStrokeColor: Color?
    var primaryButton: AlertButton?
    var secondaryButton: AlertButton?
    var views: [ViewConfig] = []
    
    struct ViewConfig: Identifiable {
        var id: UUID = UUID()
        var content: AnyView
    }
    
    struct ButtonConfig: Identifiable {
        var id: UUID = UUID()
        var text: String
        var role: AlertConfig.ButtonRole? = nil
        var color: Color {
            switch role {
            case .cancel, .primary, .some(.none), nil:
                .primary
            case .destructive:
                .red
            }
        }
        var function: () -> Void
    }
    
    enum ButtonRole {
        case cancel, destructive, primary, none
    }
    
    
    struct AlertButton: View {
        var closeOnFunction: Bool = true
        var showSpinnerOnClick: Bool = false
        var config: ButtonConfig
        
        @State private var showSpinner: Bool = false
        
        var body: some View {
            Button {
                if closeOnFunction {
                    AppState.shared.closeAlert()
                }
                if showSpinnerOnClick {
                    showSpinner = true
                }
                config.function()
            } label: {
                Text(config.text)
                    .fontWeight(config.role == .primary ? .bold : .regular)
                    .foregroundStyle(config.role == .destructive ? .red : Color.theme)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .opacity(showSpinner ? 0 : 1)
            .overlay(ProgressView().opacity(showSpinner ? 1 : 0))
            .disabled(showSpinner)
        }
    }
}



let alertConfigExample = AlertConfig(
    title: "Title",
    subtitle: "Subtitle",
    symbol: .init(name: "calendar.badge.exclamationmark", color: .orange),
    primaryButton:
        AlertConfig.AlertButton(config: .init(text: "Change", role: .primary, function: {
        /// actions here
    })),
    secondaryButton:
        AlertConfig.AlertButton(config: .init(text: "Don't Change", function: {
        ///actions here
    })),
    views: [
        AlertConfig.ViewConfig(content: AnyView(Text("hey"))),
        AlertConfig.ViewConfig(content: AnyView(Text("hey")))
    ]
)
//AppState.shared.showAlert(config: alertConfigExample)



//
//struct CustomAlertOG: View {
//
//    let config: AlertConfig
//    var body: some View {
//        VStack {
//            Image(systemName: config.symbol.name)
//                .font(.title)
//                .foregroundStyle(.primary)
//                .frame(width: 65, height: 65)
//                .background((config.symbol.color ?? .primary).gradient, in: .circle)
//                .background {
//                    Circle()
//                        .stroke(.background, lineWidth: 8)
//                }
//
//            Group {
//                Text(config.title)
//                    .font(.title3.bold())
//                    .multilineTextAlignment(.center)
//
//                if let subtitle = config.subtitle {
//                    Text(subtitle)
//                        .font(.callout)
//                        .multilineTextAlignment(.center)
//                        .lineLimit(5)
//                        .foregroundStyle(.gray)
//                    //.padding(.vertical, 4)
//                }
//            }
//            .padding(.horizontal, 15)
//
//            if !config.views.isEmpty {
//                ForEach(config.views) { viewConfig in
//                    Divider()
//                    viewConfig.content
//                }
//            }
//
//
//            VStack(spacing: 0) {
//                Divider()
//
//                if config.primaryButton == nil && config.secondaryButton == nil {
//                    let buttonConfig = AlertConfig.ButtonConfig(
//                        text: "Cancel",
//                        role: .cancel,
//                        //edge: .horizontal
//                    ) {
//                        AppState.shared.closeAlert()
//                    }
//
//                    AlertConfig.AlertButton(config: buttonConfig)
//
//                    //AlertConfig.CancelButton(isAlone: true)
//                        .fixedSize(horizontal: false, vertical: true)
//                } else {
//                    HStack(spacing: 0) {
//                        if let button = config.secondaryButton {
//                            button
//                            Divider()
//                        } else {
//                            if let _ = config.primaryButton {
//                                //AlertConfig.CancelButton(isAlone: false)
//                                let buttonConfig = AlertConfig.ButtonConfig(
//                                    text: "Cancel",
//                                    role: .cancel,
//                                    //edge: .leading
//                                ) {
//                                    AppState.shared.closeAlert()
//                                }
//                                AlertConfig.AlertButton(config: buttonConfig)
//                                Divider()
//                            } else {
//                                let buttonConfig = AlertConfig.ButtonConfig(
//                                    text: "Cancel",
//                                    role: .cancel,
//                                    //edge: .horizontal
//                                ) {
//                                    AppState.shared.closeAlert()
//                                }
//                                AlertConfig.AlertButton(config: buttonConfig)
//                                //AlertConfig.CancelButton(isAlone: true)
//                            }
//                        }
//
//                        if let button = config.primaryButton {
//                            button
//                        }
//                    }
//                    .fixedSize(horizontal: false, vertical: true)
//                }
//
//
//            }
//        }
//        //.glassEffect(in: .rect(cornerRadius: 15))
//        //.padding(.top, 30)
//        //.padding([.horizontal, .bottom], 15)
//        .background {
//            RoundedRectangle(cornerRadius: 25)
//                .opacity(0)
//                #if os(iOS)
//                .glassEffect(.regular, in: .rect(cornerRadius: 25))
//                #endif
//                //.glassEffect(in: .rect(cornerRadius: 15))
//                //.fill(.ultraThickMaterial)
//                .padding(.top, 30)
//        }
//        .frame(maxWidth: 310)
//        .compositingGroup()
//    }
//}
//
//


