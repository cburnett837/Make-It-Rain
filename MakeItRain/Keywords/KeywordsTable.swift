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
    
    @State private var deleteKeyword: CBKeyword?
    @State private var editKeyword: CBKeyword?
    @State private var keywordEditID: CBKeyword.ID?
    
    @State private var sortOrder = [KeyPathComparator(\CBKeyword.keyword)]
    
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    
    var filteredKeywords: [CBKeyword] {
        keyModel.keywords
            .filter { searchText.isEmpty ? !$0.keyword.isEmpty : $0.keyword.localizedStandardContains(searchText) }
            //.sorted { $0.keyword.lowercased() < $1.keyword.lowercased() }
    }
    
    var body: some View {
        @Bindable var keyModel = keyModel
        
        Group {
            if !keyModel.keywords.isEmpty {
                Group {
                    #if os(macOS)
                    macTable
                    #else
                    phoneList
                    #endif
                }
            } else {
                ContentUnavailableView("No Keywords", systemImage: "textformat.abc.dottedunderline", description: Text("Click the plus button above to add a keyword."))
                    #if os(iOS)
                    .standardBackground()
                    #endif
            }
        }
        #if os(iOS)
        .navigationTitle("Keywords")
        .navigationBarTitleDisplayMode(.inline)
        #endif
        /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new keyword, and then trying to edit it.
        /// When I add a new keyword, and then update `model.keywords` with the new ID from the server, the table still contains an ID of 0 on the newly created keyword.
        /// Setting this id forces the view to refresh and update the relevant keyword with the new ID.
        .id(keyModel.fuckYouSwiftuiTableRefreshID)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
        .searchable(text: $searchText) {
            #if os(macOS)
            let relevantTitles: Array<String> = keyModel.keywords
                .compactMap { $0.keyword }
                .uniqued()
                .filter { $0.localizedStandardContains(searchText) }
                    
            ForEach(relevantTitles, id: \.self) { title in
                Text(title)
                    .searchCompletion(title)
            }
            #endif
        }
        
        .sheet(item: $editKeyword, onDismiss: {
            keywordEditID = nil
        }, content: { key in
            KeywordView(keyword: key, keyModel: keyModel, catModel: catModel, editID: $keywordEditID)
                #if os(macOS)
                .frame(minWidth: 700)
                #endif
        })
        .onChange(of: sortOrder) { _, sortOrder in
            keyModel.keywords.sort(using: sortOrder)
        }
        .onChange(of: keywordEditID) { oldValue, newValue in
            if let newValue {
                editKeyword = keyModel.getKeyword(by: newValue)
            } else {
                keyModel.saveKeyword(id: oldValue!)                
            }
        }
        .confirmationDialog("Delete keyword \(deleteKeyword == nil ? "N/A" : deleteKeyword!.keyword)?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                if let deleteKeyword = deleteKeyword {
                    Task {
                        await keyModel.delete(deleteKeyword, andSubmit: true)
                    }
                }
            }
            
            Button("No", role: .cancel) {
                deleteKeyword = nil
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete keyword \"\(deleteKeyword == nil ? "N/A" : deleteKeyword!.keyword)\"?")
            #endif
        })
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { oldValue, newValue in
            !oldValue && newValue
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
            ToolbarCenterView()
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
            
            TableColumn("Delete") { key in
                Button {
                    deleteKeyword = key
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .width(min: 20, ideal: 30, max: 50)
        }
        .clipped()
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }
    #endif
    
    #if os(iOS)
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !AppState.shared.isIpad {
                Button {
                    dismiss() //NavigationManager.shared.selection = nil // NavigationManager.shared.navPath.removeLast()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            } else {
                HStack {
                    ToolbarRefreshButton()
                    Button {
                        keywordEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                    //.disabled(keyModel.isThinking)
                }
            }
        }
        
        if !AppState.shared.isIpad {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    ToolbarRefreshButton()
                    Button {
                        keywordEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                    //.disabled(keyModel.isThinking)
                }                
            }
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
            .rowBackgroundWithSelection(id: key.id, selectedID: keywordEditID)
            .swipeActions(allowsFullSwipe: false) {
                Button {
                    deleteKeyword = key
                    showDeleteAlert = true
                } label: {
                    Label {
                        Text("Delete")
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
                .tint(.red)
            }
        }
        .listStyle(.plain)
        .standardBackground()
    }
    #endif
}
