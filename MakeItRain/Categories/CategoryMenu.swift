//
//  CategoryMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/18/24.
//

import SwiftUI

struct CategoryMenu<Content: View>: View {
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title

    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    
    @Binding var category: CBCategory?
    var trans: CBTransaction?
    let saveOnChange: Bool
    let menuItemOnly: Bool
    @ViewBuilder let content: Content
    
    
    
    init(category: Binding<CBCategory?>, menuItemsOnly: Bool = false, @ViewBuilder content: () -> Content) {
        self._category = category
        self.trans = nil
        self.saveOnChange = false
        self.content = content()
        self.menuItemOnly = menuItemsOnly
    }
    
    
    init(category: Binding<CBCategory?>, trans: CBTransaction?, saveOnChange: Bool, menuItemsOnly: Bool = false, @ViewBuilder content: () -> Content) {
        self._category = category
        self.trans = trans
        self.saveOnChange = saveOnChange
        self.content = content()
        self.menuItemOnly = menuItemsOnly
    }
    
    var sortedCategories: Array<CBCategory> {
        return catModel.categories
            .sorted {
                categorySortMode == .title
                ? $0.title.lowercased() < $1.title.lowercased()
                : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
            }
    }
    
    
    var body: some View {
        if menuItemOnly {
            menuItems
        } else {
            Menu {
                menuItems
            } label: {
                content
                    .foregroundStyle((category?.title ?? "").isEmpty ? .gray : .primary)
            }
        }
    }
    
    var menuItems: some View {
        Group {
            Button {
                if saveOnChange && trans != nil {
                    trans!.log(field: .category, old: trans!.category?.id, new: nil)
                    category = nil
                    calModel.saveTransaction(id: trans!.id)
                } else {
                    category = nil
                }
            } label: {
                HStack {
                    Text("None")
                        .strikethrough(true)
                }
            }
                            
            ForEach(sortedCategories) { cat in
                Button {
                    if saveOnChange && trans != nil {
                        trans!.log(field: .category, old: trans!.category?.id, new: cat.id)
                        category = cat
                        calModel.saveTransaction(id: trans!.id)
                    } else {
                        category = cat
                    }
                                        
                } label: {
                    HStack {
                        
                        if lineItemIndicator == .dot {
                            HStack { /// This can be a button or whatever you want
                                Text(cat.title)
                                Image(systemName: "circle.fill")
                                    //.foregroundStyle(cat.color)
                                    .foregroundStyle(cat.color, cat.color, cat.color)
                            }
                        } else {
                            if let emoji = cat.emoji {
                                HStack { /// This can be a button or whatever you want
                                    Text(cat.title)
                                    Image(systemName: emoji)
                                        //.foregroundStyle(cat.color)
                                        .foregroundStyle(cat.color, cat.color, cat.color)
                                }
                            } else {
                                Text(cat.title)
                            }
                        }
                    }
                }
            }
        }
        
    }
}

