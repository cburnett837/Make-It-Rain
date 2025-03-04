//
//  AlertStuff.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/28/25.
//

import SwiftUI

struct AlertAndToastLayerView: View {
    @Environment(CalendarModel.self) private var calModel
    
    var body: some View {
        @Bindable var appState = AppState.shared
        @Bindable var calModel = calModel
        @Bindable var undoManager = UndodoManager.shared
        
        Group {}
        .toast()
        .alert("Undo / Redo", isPresented: $undoManager.showAlert) {
            VStack {
                if UndodoManager.shared.canUndo {
                    Button {
                        if let old = UndodoManager.shared.undo() {
                            undoManager.returnMe = old
                        }
                    } label: {
                        Text("Undo")
                    }
                }
                
                if UndodoManager.shared.canRedo {
                    Button {
                        if let new = UndodoManager.shared.redo() {
                            undoManager.returnMe = new
                        }
                    } label: {
                        Text("Redo")
                    }
                }
                
                Button(role: .cancel) {
                } label: {
                    Text("Cancel")
                }
            }
        }
        
//        .sheet(isPresented: $calModel.showSmartTransactionPaymentMethodSheet) {
//            PaymentMethodSheet(
//                payMethod: Binding(get: { CBPaymentMethod() }, set: { calModel.pendingSmartTransaction!.payMethod = $0 }),
//                trans: calModel.pendingSmartTransaction,
//                calcAndSaveOnChange: true,
//                whichPaymentMethods: .allExceptUnified,
//                isPendingSmartTransaction: true
//            )
//        }
//
//
//        .sheet(isPresented: $calModel.showSmartTransactionDatePickerSheet, onDismiss: {
//            if calModel.pendingSmartTransaction!.date == nil {
//                calModel.pendingSmartTransaction!.date = Date()
//            }
//
//            calModel.saveTransaction(id: calModel.pendingSmartTransaction!.id, location: .smartList)
//            calModel.tempTransactions.removeAll()
//            calModel.pendingSmartTransaction = nil
//        }, content: {
//            GeometryReader { geo in
//                ScrollView {
//                    VStack {
//                        SheetHeader(title: "Select Receipt Date", subtitle: calModel.pendingSmartTransaction!.title) {
//                            calModel.showSmartTransactionDatePickerSheet = false
//                        }
//
//                        Divider()
//
//                        DatePicker(selection: Binding($calModel.pendingSmartTransaction)!.date ?? Date(), displayedComponents: [.date]) {
//                            EmptyView()
//                        }
//                        .datePickerStyle(.graphical)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .labelsHidden()
//
//                        Spacer()
//                        Button("Done") {
//                            calModel.showSmartTransactionDatePickerSheet = false
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .padding(.bottom, 12)
//                    }
//                    .frame(minHeight: geo.size.height)
//                }
//                .padding([.top, .horizontal])
//            }
//            //.presentationDetents([.medium])
//        })
//        .opacity((AppState.shared.showAlert || AppState.shared.toast != nil) ? 1 : 0)
//        .alert(AppState.shared.alertText, isPresented: $appState.showAlert) {
//            if let function = AppState.shared.alertFunction {
//                Button(AppState.shared.alertButtonText ?? "", action: function)
//            }
//            if let function = AppState.shared.alertFunction2 {
//                Button(AppState.shared.alertButtonText2 ?? "", action: function)
//            } else {
//                Button("Close", action: {})
//            }
//        }
        .overlay {
            if let config = AppState.shared.alertConfig {
                Rectangle()
                    //.fill(.ultraThickMaterial)
                    .fill(Color.darkGray3)
                    .opacity(0.8)
                    .ignoresSafeArea()
                    .overlay { CustomAlert(config: config) }
                    .opacity(appState.showCustomAlert ? 1 : 0)
                                        
            }
        }
    }
}


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
                        .lineLimit(3)
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
        var config: ButtonConfig
        
        var body: some View {
            Button {
                AppState.shared.closeAlert()
                config.function()
            } label: {
                Text(config.text)
                    .fontWeight(config.role == .primary ? .bold : .regular)
                    .foregroundStyle(config.role == .destructive ? .red : (preferDarkMode ? .white : .black))
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
        }
        
    }
    
    struct CancelButton: View {
        @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
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
