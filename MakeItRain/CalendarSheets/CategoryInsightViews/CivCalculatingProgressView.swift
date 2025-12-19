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
            .background(Color(.systemBackground))
            .opacity(model.showLoadingSpinner ? 1 : 0)
            .scenePadding(.horizontal)
    }
}
