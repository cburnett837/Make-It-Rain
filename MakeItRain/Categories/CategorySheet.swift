//
//  CategorySheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/21/24.
//

import SwiftUI

struct CategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @State private var editCategory: CBCategory?
    @State private var categoryEditID: CBCategory.ID?
    @State private var labelWidth: CGFloat = 20.0
    
    @Binding var category: CBCategory?
    var trans: CBTransaction?
    let saveOnChange: Bool
        
    init(category: Binding<CBCategory?>) {
        self._category = category
        self.trans = nil
        self.saveOnChange = false
    }
    
    init(category: Binding<CBCategory?>, trans: CBTransaction?, saveOnChange: Bool) {
        self._category = category
        self.trans = trans
        self.saveOnChange = saveOnChange
    }
    
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    
    var filteredCategories: Array<CBCategory> {
        if searchText.isEmpty {
            return catModel.categories
                .sorted {
                    categorySortMode == .title
                    ? $0.title.lowercased() < $1.title.lowercased()
                    : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
                }
        } else {
            return catModel.categories.filter { $0.title.localizedStandardContains(searchText) }
                .sorted {
                    categorySortMode == .title
                    ? $0.title.lowercased() < $1.title.lowercased()
                    : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
                }
        }
    }
    
    var sortMenu: some View {
        Menu {
            Button {
                categorySortMode = .title
            } label: {
                Label {
                    Text("Title")
                } icon: {
                    Image(systemName: categorySortMode == .title ? "checkmark" : "textformat.abc")
                }
            }
            
            Button {
                categorySortMode = .listOrder
            } label: {
                Label {
                    Text("Custom")
                } icon: {
                    Image(systemName: categorySortMode == .listOrder ? "checkmark" : "list.bullet")
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
    
    
    var body: some View {
        StandardContainer(.list) {
            noneSection
            yourCategoriesSection
        } header: {
            SheetHeader(title: "Categories", close: { dismiss() }, view1: { sortMenu })
        } subHeader: {
            SearchTextField(title: "Categories", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)
                .padding(.horizontal, -20)
                #if os(macOS)
                .focusable(false) /// prevent mac from auto focusing
                #endif
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .sheet(item: $editCategory, onDismiss: {
            categoryEditID = nil
        }, content: { cat in
            CategoryView(category: cat, catModel: catModel, calModel: calModel, keyModel: keyModel, editID: $categoryEditID)
            //#if os(iOS)
            //.presentationDetents([.medium, .large])
            //#endif
            #if os(macOS)
                .frame(maxWidth: 300)
            #endif
        })
        
        .onChange(of: categoryEditID) { oldValue, newValue in
            if let newValue {
                editCategory = catModel.getCategory(by: newValue)
            } else {
                catModel.saveCategory(id: oldValue!, calModel: calModel)
            }
        }
    }
    
    var noneSection: some View {
        Section("None") {
            HStack {
                Text("None")
                    .strikethrough(true)
                Spacer()
                if category?.id == nil {
                    Image(systemName: "checkmark")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { doIt(nil) }
        }
    }
    
    var yourCategoriesSection: some View {
        Section("Your Categories") {
            ForEach(filteredCategories) { cat in
                HStack {
                    if lineItemIndicator == .dot {
                        HStack { /// This can be a button or whatever you want
                            Image(systemName: "circle.fill")
                                .foregroundStyle(cat.color.gradient, .primary, .secondary)
                            Text(cat.title)
                            Spacer()
                            if category?.id == cat.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    } else {
                        if let emoji = cat.emoji {
                            HStack {
                                Image(systemName: emoji)
                                    .foregroundStyle(cat.color.gradient)
                                    .frame(minWidth: labelWidth, alignment: .center)
                                    .maxViewWidthObserver()
                                Text(cat.title)
                                //Text("\(emoji) \(cat.title)")
                                Spacer()
                                if category?.id == cat.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        } else {
                            HStack {
                                Text(cat.title)
                                Spacer()
                                if category?.id == cat.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { doIt(cat) }
            }
            
            Button("New Category") {
                categoryEditID = UUID().uuidString
            }
        }
    }
    
    func doIt(_ cat: CBCategory?) {
        category = cat
        if saveOnChange && trans != nil {
            //trans!.updatedBy = AppState.shared.user!
            //Task { await calModel.submit(trans!) }
            calModel.saveTransaction(id: trans!.id)
        }
        dismiss()
    }
}





