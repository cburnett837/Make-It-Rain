//
//  EventItemSheetButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/2/25.
//


import SwiftUI

struct EventItemSheetButton: View {
    @State private var showItemSheet = false
    @State private var itemMenuColor: Color = Color(.tertiarySystemFill)
    @Binding var item: CBEventItem?
    @Bindable var trans: CBEventTransaction
    @Bindable var event: CBEvent
    
    var body: some View {
        StandardRectangle(fill: itemMenuColor) {
            MenuOrListButton(title: item?.title, alternateTitle: "Select Item") {
                showItemSheet = true
            }
        }
        .onHover { itemMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
        .sheet(isPresented: $showItemSheet) {
            EventItemSheet(item: $item, trans: trans, event: event)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
    }
}
