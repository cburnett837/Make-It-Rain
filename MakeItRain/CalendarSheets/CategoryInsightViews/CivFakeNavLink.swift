//
//  FakeNavLink.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/19/25.
//


import SwiftUI
import Charts

struct CivFakeNavLink<Content: View>: View {
    @ViewBuilder var label: () -> Content
    var action: () -> Void
    
    var body: some View {
        
        Button {
            action()
        } label: {
            HStack {
                label()
                    .schemeBasedForegroundStyle()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
        }
    }
}
