//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI

struct TagsTable: View {
//    @Environment(CategoryModel.self) private var catModel
//    @Environment(TagModel.self) private var keyModel
//    
//    @State private var searchText = ""
//    
//    @State private var deleteTag: CBTag?
//    @State private var editTag: CBTag?
//    @State private var tagEditID: CBTag.ID?
//    
//    @State private var sortOrder = [KeyPathComparator(\CBTag.tag)]
//    
//    @State private var showDeleteAlert = false
//    
//    var showMenu: () -> Void
//    let downloadEverything: (_ setDefaultPayMethod: Bool, _ createNewStructs: Bool, _ refreshTechnique: RefreshTechnique) async -> Void
//    
//    var filteredTags: [CBTag] {
//        keyModel.tags.filter { searchText.isEmpty ? !$0.tag.isEmpty : $0.tag.lowercased().contains(searchText.lowercased()) }
//    }
    
    var body: some View {
        Text("Nope")
//        @Bindable var keyModel = keyModel
//        
//        Group {
//            if !keyModel.tags.isEmpty {
//                Group {
//                    #if os(macOS)
//                    macTable
//                    #else
//                    phoneList
//                    #endif
//                }
//            } else {
//                ContentUnavailableView("No Tags", systemImage: "tag", description: Text("Click the plus button above to add a tag."))
//                    #if os(iOS)
//                    .standardBackground()
//                    #endif
//            }
//        }
//        #if os(iOS)
//        .navigationTitle("Tags")
//        .navigationBarTitleDisplayMode(.inline)
//        #endif
//        /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new tag, and then trying to edit it.
//        /// When I add a new tag, and then update `model.tags` with the new ID from the server, the table still contains an ID of 0 on the newly created tag.
//        /// Setting this id forces the view to refresh and update the relevant tag with the new ID.
//        .id(keyModel.fuckYouSwiftuiTableRefreshID)
//        .toolbar {
//            #if os(macOS)
//            macToolbar()
//            #else
//            phoneToolbar()
//            #endif
//        }
//        .searchable(text: $searchText) {
//            #if os(macOS)
//            let relevantTitles: Array<String> = keyModel.tags
//                .compactMap { $0.tag }
//                .uniqued()
//                .filter { $0.lowercased().contains(searchText.lowercased()) }
//                    
//            ForEach(relevantTitles, id: \.self) { title in
//                Text(title)
//                    .searchCompletion(title)
//            }
//            #endif
//        }
//        
//        .sheet(item: $editTag, onDismiss: {
//            tagEditID = nil
//        }, content: { cat in
//            TagView(tag: cat, keyModel: keyModel, catModel: catModel, editID: $tagEditID)
//                //#if os(iOS)
//                //.presentationDetents([.medium, .large])
//                //#endif
//                #if os(macOS)
//                .frame(minWidth: 700)
//                #endif
//                //.frame(maxWidth: 300)
//        })
//        .onChange(of: sortOrder) { _, sortOrder in
//            keyModel.tags.sort(using: sortOrder)
//        }
//        .onChange(of: tagEditID) { oldValue, newValue in
//            if let newValue {
//                editTag = keyModel.getTag(by: newValue)
//            } else {
//                keyModel.saveTag(id: oldValue!)
//            }
//        }
//        .alert("Delete tag \(deleteTag == nil ? "N/A" : deleteTag!.tag)?", isPresented: $showDeleteAlert) {
//            Button("Yes", role: .destructive) {
//                if let deleteTag = deleteTag {
//                    Task {
//                        await keyModel.delete(deleteTag, andSubmit: true)
//                    }
//                }
//            }
//            
//            Button("Cancel", role: .cancel) {
//                deleteTag = nil
//                showDeleteAlert = false
//            }
//        }
//        .sensoryFeedback(.warning, trigger: showDeleteAlert) { oldValue, newValue in
//            !oldValue && newValue
//        }
    }
    
//    @ToolbarContentBuilder
//    func macToolbar() -> some ToolbarContent {
//        ToolbarItem(placement: .navigation) {
//            HStack {
//                Button {
//                    //editTag = CBTag.empty
//                    tagEditID = 0
//                } label: {
//                    Image(systemName: "plus")
//                }
//                .toolbarBorder()
//                
//                ToolbarNowButton()
//                ToolbarRefreshButton(downloadEverything: downloadEverything)
//                    .toolbarBorder()
//                
////                Button("Delete All") {
////                    Task {
////                        await keyModel.deleteAll()
////                    }
////                }
////                .toolbarBorder()
//            }
//        }
//        
//        ToolbarItem(placement: .principal) {
//            ToolbarCenterView()
//        }
//        ToolbarItem {
//            Spacer()
//        }
//    }
//    
//    
//    
//    var macTable: some View {
//        Table(filteredTags, selection: $tagEditID, sortOrder: $sortOrder) {
//            TableColumn("Tag", value: \.tag) { tag in
//                Text(tag.tag)
//            }
//                        
//            
//            TableColumn("Delete") { tag in
//                Button {
//                    deleteTag = tag
//                    showDeleteAlert = true
//                } label: {
//                    Image(systemName: "trash")
//                }
//                .buttonStyle(.borderedProminent)
//                .tint(.red)
//            }
//            .width(min: 20, ideal: 30, max: 50)
//        }
//        .clipped()
//    }
//    
//    
//    
//    #if os(iOS)
//    @ToolbarContentBuilder
//    func phoneToolbar() -> some ToolbarContent {
//        ToolbarItem(placement: .topBarLeading) {
//            Button {
//                showMenu()
//            } label: {
//                Image(systemName: "line.3.horizontal")
//            }
//        }
//        
//        ToolbarItem(placement: .topBarTrailing) {
//            HStack {
//                ToolbarRefreshButton(downloadEverything: downloadEverything)
//                Button {
//                    //editTag = CBTag.empty
//                    tagEditID = 0
//                } label: {
//                    Image(systemName: "plus")
//                }
//            }
//            
//        }
//    }
//    
//    var phoneList: some View {
//        List(filteredTags, selection: $tagEditID) { tag in
//            HStack(alignment: .top) {
//                VStack(alignment: .leading) {
//                    Text(tag.tag)
//                }
//                Spacer()
//            }
//            .rowBackgroundWithSelection(id: tag.id, selectedID: tagEditID)
//            .swipeActions(allowsFullSwipe: false) {
//                Button {
//                    deleteTag = tag
//                    showDeleteAlert = true
//                } label: {
//                    Label {
//                        Text("Delete")
//                    } icon: {
//                        Image(systemName: "trash")
//                    }
//                }
//                .tint(.red)
//            }
//        }
//        .listStyle(.plain)
//        .standardBackground()
//    }
//    #endif
}
