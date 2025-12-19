//
//  LogoPickerRow.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/8/25.
//

import SwiftUI

struct LogoPickerRow<T: CanHandleLogo & Observation.Observable>: View {
    @State private var showLogoSearchPage = false
    let parent: T
    let parentType: XrefEnum
    let fallbackType: LogoFallBackType
    
    var body: some View {
        logoRow
    }
    
    
    @ViewBuilder
    var logoRow: some View {
        #if os(iOS)
        Group {
            if parent.logo == nil {
                Button {
                    showLogoSearchPage = true
                } label: {
                    logoLabel
                }
            } else {
                Menu {
                    Button("Clear Logo") { parent.logo = nil }
                    Button("Change Logo") { showLogoSearchPage = true }
                } label: {
                    logoLabel
                }
            }
        }
        .sheet(isPresented: $showLogoSearchPage) {
            LogoSearchPage(parent: parent, parentType: parentType)
        }
        
        #else
        LabeledRow("Color", labelWidth) {
            HStack {
                ColorPicker("", selection: $payMethod.color, supportsOpacity: false)
                    .labelsHidden()
                Capsule()
                    .fill(payMethod.color)
                    .onTapGesture {
                        AppState.shared.showToast(title: "Color Picker", subtitle: "Click the circle to the left to change the color.", body: nil, symbol: "theatermask.and.paintbrush", symbolColor: payMethod.color)
                    }
            }
        }
        #endif
    }
    
    
    var logoLabel: some View {
        HStack {
            Label {
                Text("Logo")
                    .schemeBasedForegroundStyle()
            } icon: {
                Image(systemName: "circle.hexagongrid")
                    .foregroundStyle(.gray)
            }
            Spacer()
            //StandardColorPicker(color: $payMethod.color)
            BusinessLogo(config: .init(parent: parent, fallBackType: fallbackType))
            
            //BusinessLogo(parent: payMethod, fallBackType: payMethod.isUnified ? .gradient : .color)
        }
    }
}
