//
//  StandardContainerWithToolbar.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/1/25.
//


import SwiftUI

struct StandardContainerWithToolbar<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    
    let contentType: SheetContainerContentType
    @ViewBuilder var content: Content
    @Binding var selectionID: String?
    var scrollDismissesKeyboard: ScrollDismissesKeyboardMode
    
    
    init(
        _ contentType: SheetContainerContentType = .scrolling,
        scrollDismissesKeyboard: ScrollDismissesKeyboardMode = .interactively,
        selectionID: Binding<String?> = .constant(nil),
        @ViewBuilder content: @escaping () -> Content,
    ) {
        self.contentType = contentType
        self.content = content()
        self._selectionID = selectionID
        self.scrollDismissesKeyboard = scrollDismissesKeyboard
    }
    
    var isBottomPanel: Bool { contentType == .bottomPanel }
    var isSheet: Bool { contentType == .list || contentType == .scrolling }
    var isList: Bool {
        contentType == .list ||
        contentType == .plainList ||
        contentType == .sidebarList ||
        contentType == .plainWithSelection ||
        contentType == .insetListWithSelection
    }
    var isSidebar: Bool { contentType == .sidebarList || contentType == .sidebarScrolling }
    
    var body: some View {
        VStack(spacing: 0) {
            if isList { listContent } else { scrollingContent }
        }
        #if os(macOS)
        .padding(.bottom, 10)
        #endif
        
    }
    
    
    var listContent: some View {
        Group {
            if contentType == .plainWithSelection || contentType == .insetListWithSelection {
                List(selection: $selectionID) { content }
                    .if(contentType == .plainWithSelection) {
                        $0.listStyle(.plain)
                    }
            } else {
                List { content }
                    .if(contentType == .plainList) {
                        $0.listStyle(.plain)
                    }
            }
        }
        .scrollDismissesKeyboard(scrollDismissesKeyboard)
        #if os(macOS)
        .scrollContentBackground(.hidden)
        #endif
    }
    
    
    var scrollingContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                content
            }
            .if(!isBottomPanel) {
                $0.scenePadding(.horizontal)
            }
            //.padding(.horizontal, isBottomPanel ? 0 : 12)
            .padding(.top, isBottomPanel ? 0 : 12)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}
