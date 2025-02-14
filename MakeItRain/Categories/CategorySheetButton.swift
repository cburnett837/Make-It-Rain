//
//  CategorySheetButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/24.
//

import SwiftUI

struct CategorySheetButton: View {
    @State private var showCategorySheet = false
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    @Binding var category: CBCategory?
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(categoryMenuColor)
            #if os(macOS)
            .frame(height: 27)
            #else
            .frame(height: 34)
            #endif
            .overlay {
                MenuOrListButton(title: category?.title, alternateTitle: "Select Category") {
                    showCategorySheet = true
                }
            }
            .onHover { categoryMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
            .sheet(isPresented: $showCategorySheet) {
                CategorySheet(category: $category)
                    /// For transactions only.
                    //.onAppear { UndodoManager.shared.commitChangeInTask(value: category?.id, field: .category) }
                #if os(macOS)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.fitted)
                #endif
            }
    }
}
