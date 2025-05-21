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
    
    var title: String {
        if let category {
            return category.isNil ? "Select Category" : category.title
        } else {
            return "Select Category"
        }
    }
    
    var body: some View {
        StandardRectangle(fill: categoryMenuColor) {
//            MenuOrListButton(title: category?.title, alternateTitle: "Select Category") {
//                showCategorySheet = true
//            }
            
            
            HStack {
                if let category = category {
                    Text(title)
                        .foregroundStyle(category.isNil ? .gray : .primary)
                } else {
                    Text(title)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
            }
            .chevronMenuOverlay()
        }
        .contentShape(Rectangle())
        .focusable(false)
        .onTapGesture {
            showCategorySheet = true
        }
        .onHover { categoryMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
        .sheet(isPresented: $showCategorySheet) {
            CategorySheet(category: $category)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
    }
}



