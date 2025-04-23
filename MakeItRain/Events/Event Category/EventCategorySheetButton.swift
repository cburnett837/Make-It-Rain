//
//  EventCategorySheetButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/2/25.
//


import SwiftUI

struct EventCategorySheetButton: View {
    @State private var showCategorySheet = false
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    @Binding var category: CBEventCategory?
    @Bindable var trans: CBEventTransaction
    @Bindable var event: CBEvent
    
    var body: some View {
        StandardRectangle(fill: categoryMenuColor) {
            MenuOrListButton(title: category?.title, alternateTitle: "Select Category") {
                showCategorySheet = true
            }
        }
        .onHover { categoryMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
        .sheet(isPresented: $showCategorySheet) {
            EventCategorySheet(category: $category, trans: trans, event: event)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
    }
}
