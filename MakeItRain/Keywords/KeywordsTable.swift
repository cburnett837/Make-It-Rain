//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI

struct KeywordsTable: View {
    @Environment(\.dismiss) var dismiss
    
    #if os(macOS)
    @AppStorage("keywordsTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBKeyword>
    #endif
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @State private var searchText = ""
    @State private var editKeyword: CBKeyword?
    @State private var keywordEditID: CBKeyword.ID?
    @State private var sortOrder = [KeyPathComparator(\CBKeyword.keyword)]
    @State private var labelWidth: CGFloat = 20.0
    
    var filteredKeywords: [CBKeyword] {
        keyModel.keywords
            .filter { searchText.isEmpty ? !$0.keyword.isEmpty : $0.keyword.localizedCaseInsensitiveContains(searchText) }
            //.sorted { $0.keyword.lowercased() < $1.keyword.lowercased() }
    }
    
    var body: some View {
        @Bindable var keyModel = keyModel
        
        Group {
            if !keyModel.keywords.isEmpty {
                #if os(macOS)
                macTable
                #else
                
                if filteredKeywords.isEmpty {
                    ContentUnavailableView("No rules found", systemImage: "exclamationmark.magnifyingglass")
                } else {
                    phoneList
                }
                
                #endif
            } else {
                ContentUnavailableView("No Keywords", systemImage: "textformat.abc.dottedunderline", description: Text("Click the plus button above to add a keyword."))
            }
        }
        #if os(iOS)
        .navigationTitle("Rules")
        //.navigationBarTitleDisplayMode(.inline)
        #endif
        /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new keyword, and then trying to edit it.
        /// When I add a new keyword, and then update `model.keywords` with the new ID from the server, the table still contains an ID of 0 on the newly created keyword.
        /// Setting this id forces the view to refresh and update the relevant keyword with the new ID.
        .id(keyModel.fuckYouSwiftuiTableRefreshID)
        //.navigationBarBackButtonHidden(true)
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
        .searchable(text: $searchText)
        .sheet(item: $editKeyword, onDismiss: {
            keywordEditID = nil
        }) { key in
            KeywordView(keyword: key, editID: $keywordEditID)
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 700)
                .presentationSizing(.fitted)
                #endif                
        }
        .onChange(of: keywordEditID) {
            if $1 != nil {
                editKeyword = keyModel.getKeyword(by: $1!)
            } else {
                keyModel.saveKeyword(id: $0!)
            }
        }
        .onChange(of: sortOrder) {
            keyModel.keywords.sort(using: $1)
        }
    }
    
    
    #if os(macOS)
    @ToolbarContentBuilder
    func macToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack {
                Button {
                    keywordEditID = UUID().uuidString
                } label: {
                    Image(systemName: "plus")
                }
                .toolbarBorder()
                //.disabled(keyModel.isThinking)
                
                ToolbarNowButton()
                ToolbarRefreshButton()
                    .toolbarBorder()
            }
        }
        
        ToolbarItem(placement: .principal) {
            ToolbarCenterView(enumID: .keywords)
        }
        ToolbarItem {
            Spacer()
        }
    }
            
    var macTable: some View {
        Table(filteredKeywords, selection: $keywordEditID, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumn("Keyword", value: \.keyword) { key in
                Text(key.keyword)
            }
            .customizationID("keyword")
            
            TableColumn("Trigger", value: \.keyword) { key in
                Text(key.triggerType.rawValue)
            }
            .customizationID("trigger")
                        
            TableColumn("Category", value: \.category?.title) { key in
                HStack {
                    if let cat = key.category {
                        Image(systemName: cat.emoji ?? "")
                            .foregroundStyle(cat.color)
                            .frame(minWidth: labelWidth, alignment: .center)
                        Text(cat.title)
                    } else {
                        Circle()
                            .fill(key.category?.color ?? .primary)
                            .frame(width: labelWidth, height: labelWidth)
                        Text(key.category?.title ?? "N/A")
                    }
                }
            }
            .customizationID("category")                        
        }
        .clipped()
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }
    #endif
    
    #if os(iOS)
            
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) { ToolbarLongPollButton() }
        ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton() }
        //ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                keywordEditID = UUID().uuidString
            } label: {
                Image(systemName: "plus")
            }
            .tint(.none)
        }
    }
    
    var phoneList: some View {
        List(filteredKeywords, selection: $keywordEditID) { key in
            HStack(alignment: .center) {
                Text(key.keyword)
                Spacer()
                Text(key.category?.title ?? "-")
                    .foregroundStyle(.gray)
                    .font(.caption)
            }
        }
        .listStyle(.plain)
    }
    #endif
}
