//
//  AlertStuff.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/28/25.
//

import SwiftUI



struct CustomAlert: View {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    
    let config: AlertConfig
    var body: some View {
        VStack {
            Image(systemName: config.symbol.name)
                .font(.title)
                .foregroundStyle(.primary)
                .frame(width: 65, height: 65)
                .background((config.symbol.color ?? .primary).gradient, in: .circle)
                .background {
                    Circle()
                        .stroke(.background, lineWidth: 8)
                }
            
            Group {
                Text(config.title)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                
                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .lineLimit(5)
                        .foregroundStyle(.gray)
                    //.padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 15)
                
            if !config.views.isEmpty {
                ForEach(config.views) { viewConfig in
                    Divider()
                    viewConfig.content
                }
            }
        
                                    
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 0) {
                    if let button = config.secondaryButton {
                        button
                        Divider()
                    } else {
                        if let _ = config.primaryButton {
                            AlertConfig.CancelButton(isAlone: false)
                            Divider()
                        } else {
                            AlertConfig.CancelButton(isAlone: true)
                        }
                    }
                    
                    if let button = config.primaryButton {
                        button
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        //.padding([.horizontal, .bottom], 15)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThickMaterial)
                .padding(.top, 30)
        }
        .frame(maxWidth: 310)
        .compositingGroup()
    }
}


struct AlertConfig {
    var title: String
    var subtitle: String?
    var symbol: SymbolConfig = .init(name: "exclamationmark.triangle.fill", color: .orange)
    var primaryButton: AlertButton?
    var secondaryButton: AlertButton?
    var views: [ViewConfig] = []
    
    struct SymbolConfig {
        var name: String
        var color: Color? = .primary
    }
    
    struct ViewConfig: Identifiable {
        var id: UUID = UUID()
        var content: AnyView
    }
    
    struct ButtonConfig: Identifiable {
        var id: UUID = UUID()
        var text: String
        var role: AlertConfig.ButtonRole? = nil
        var function: () -> Void
        var color: Color {
            switch role {
            case .cancel, .primary, .some(.none), nil:
                .primary
            case .destructive:
                .red
            }
        }
        var edge: Edge = .trailing
    }
    
    enum ButtonRole {
        case cancel, destructive, primary, none
    }
    
    
    struct AlertButton: View {
        @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
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
                    .foregroundStyle(config.role == .destructive ? .red : .primary)
                    //.padding(.vertical, 14)
                    //.frame(maxWidth: .infinity)
                    //.background(config.color/*.gradient*/, in: .rect(cornerRadius: 10))
            }
            .buttonStyle(.codyAlert)
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: config.edge == .trailing ? 0 : 15,
                    bottomTrailingRadius: config.edge == .trailing ? 15 : 0,
                    topTrailingRadius: 0
                )
            )
            .opacity(showSpinner ? 0 : 1)
            .overlay(ProgressView().opacity(showSpinner ? 1 : 0))
            .disabled(showSpinner)
        }
        
    }
    
    struct CancelButton: View {
        //@AppStorage("preferDarkMode") var preferDarkMode: Bool = true
        var isAlone: Bool
        
        var body: some View {
            Button {
                AppState.shared.closeAlert()
            } label: {
                Text("Cancel")
            }
            .buttonStyle(.codyAlert)
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 15,
                    bottomTrailingRadius: isAlone ? 15 : 0,
                    topTrailingRadius: 0
                )
            )
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
