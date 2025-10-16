//
//  CategorySheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/21/24.
//

import SwiftUI

struct CategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

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
                .filter { !$0.isHidden }
                .filter { !$0.isNil }
                .sorted {
                    categorySortMode == .title
                    ? $0.title.lowercased() < $1.title.lowercased()
                    : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
                }
        } else {
            return catModel.categories
                .filter { $0.title.localizedStandardContains(searchText) }
                .filter { !$0.isHidden }
                .filter { !$0.isNil }
                .sorted {
                    categorySortMode == .title
                    ? $0.title.lowercased() < $1.title.lowercased()
                    : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
                }
        }
    }
    
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                if filteredCategories.isEmpty {
                    ContentUnavailableView("No categories found", systemImage: "exclamationmark.magnifyingglass")
                } else {
                    noneSection
                    yourCategoriesSection
                }
            }
            //.scrollEdgeEffectStyle(.hard, for: .all)
            .searchable(text: $searchText, prompt: Text("Search"))
            #if os(iOS)
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { sortMenu }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        
//        
//        StandardContainer(.list) {
//            noneSection
//            yourCategoriesSection
//        } header: {
//            SheetHeader(title: "Select Category", close: { dismiss() }, view1: { sortMenu })
//        } subHeader: {
//            SearchTextField(title: "Categories", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)
//                .padding(.horizontal, -20)
//                #if os(macOS)
//                .focusable(false) /// prevent mac from auto focusing
//                #endif
//        }
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
                catModel.saveCategory(id: oldValue!, calModel: calModel, keyModel: keyModel)
            }
        }
    }
    
    var noneSection: some View {
        let theNil = catModel.categories.filter { $0.isNil }.first!
        return Section("None") {
            HStack {
                Text("None")
                    .strikethrough(true)
                Spacer()
                if category?.id == theNil.id {
                    Image(systemName: "checkmark")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { doIt(theNil) }
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
    
    
    var sortMenu: some View {
        Menu {
            Button {
                withAnimation {
                    categorySortMode = .title
                }
            } label: {
                Label {
                    Text("Title")
                } icon: {
                    Image(systemName: categorySortMode == .title ? "checkmark" : "textformat.abc")
                }
            }
            
            Button {
                withAnimation {
                    categorySortMode = .listOrder
                }
            } label: {
                Label {
                    Text("Custom")
                } icon: {
                    Image(systemName: categorySortMode == .listOrder ? "checkmark" : "list.bullet")
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
        
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
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





