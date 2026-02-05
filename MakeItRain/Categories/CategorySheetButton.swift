//
//  CategorySheetButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/24.
//

import SwiftUI

struct CategorySheetButtonWithNoSymbol: View {
    @State private var showCategorySheet = false
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    @Binding var category: CBCategory?
    
    var alignment: Alignment = .trailing
    
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
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: alignment)
            .tint(.none)
            #if os(iOS)
            .foregroundStyle(alignment == .trailing ? Color(.secondaryLabel) : .primary)
            #else
            .foregroundStyle(alignment == .trailing ? .secondary : .primary)
            #endif
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
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



struct CategorySheetButton: View {
    @Local(\.categoryIndicatorAsSymbol) var categoryIndicatorAsSymbol

    @State private var showCategorySheet = false
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    @Binding var category: CBCategory?
    
    var body: some View {
        HStack {
            Label {
                Text("Category")
            } icon: {
                icon
            }
            
            Spacer()
            CategorySheetButtonWithNoSymbol(category: $category)
        }
    }
    
    @ViewBuilder
    var icon: some View {
        if let cat = category {
            if cat.isNil {
                questionMark
            } else {
                categorySymbol(for: cat)
            }
        } else {
            noCategorySymbol
        }
    }
    
    var questionMark: some View {
        Image(systemName: "questionmark.circle")
            .foregroundStyle(.gray)
    }
    
    @ViewBuilder func categorySymbol(for cat: CBCategory) -> some View {
        Image(systemName: categoryIndicatorAsSymbol ? (cat.emoji ?? "circle.fill") : "circle.fill")
            .foregroundStyle(cat.color)
    }
    
    var noCategorySymbol: some View {
        Image(systemName: "circle.fill")
            .foregroundStyle(.gray)
    }
    
}
