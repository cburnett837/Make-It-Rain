//
//  InsightCalculatingProgressView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/19/25.
//


import SwiftUI
import Charts

struct CivCalculatingProgressView: View {
    @Bindable var model: CivViewModel

    var body: some View {
        ProgressView(value: model.progress)
            #if os(iOS)
            .background(Color(.systemBackground))
            #endif
            .opacity(model.showLoadingSpinner ? 1 : 0)
            .scenePadding(.horizontal)
    }
}
