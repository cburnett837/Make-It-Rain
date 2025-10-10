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



struct CategorySheetButton2: View {
    @State private var showCategorySheet = false
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    @Binding var category: CBCategory?
    
    var title: String {
        if let category {
            return category.isNil ? "Select" : category.title
        }
        return "Select"
    }
    
    var body: some View {
        Button {
            showCategorySheet = true
        } label: {
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Text(title)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .tint(.none)
                #if os(iOS)
                .foregroundStyle(Color(.secondaryLabel))
                #else
                .foregroundStyle(.secondary)
                #endif
            }
        }
        .contentShape(Rectangle())
        .focusable(false)
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



struct CategorySheetButton3: View {
    @State private var showCategorySheet = false
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    @Binding var category: CBCategory?
    
    var body: some View {
        HStack {
            Label {
                Text("Category")
            } icon: {
                if let cat = category {
                    if cat.isNil {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.gray)
                    } else {
                        Image(systemName: cat.emoji ?? "questionmark.circle")
                            .foregroundStyle(cat.color)
                    }
                } else {
                    Image(systemName: category?.emoji ?? "questionmark.circle")
                        .foregroundStyle(category?.color ?? .gray)
                }
            }
            
            Spacer()
            CategorySheetButton2(category: $category)
        }
    }
}



