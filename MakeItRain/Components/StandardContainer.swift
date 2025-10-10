//
//  SheetContainerView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/6/25.
//

import SwiftUI

enum SheetContainerContentType {
    case list, plainList, plainWithSelection, insetListWithSelection, scrolling, bottomPanel, sidebarList, sidebarScrolling
}

enum SheetHeaderContentType {
    case sheet, sidebar, bottomPanel
}

struct StandardContainer<Content: View, Content2: View, Content3: View, Content4: View>: View {
    @Environment(\.colorScheme) var colorScheme
    
    let contentType: SheetContainerContentType
    @ViewBuilder var content: Content
    var header: () -> Content2?
    var subHeader: () -> Content3?
    var footer: () -> Content4?
    @Binding var selectionID: String?
    var scrollDismissesKeyboard: ScrollDismissesKeyboardMode
    
    
    init(
        _ contentType: SheetContainerContentType = .scrolling,
        scrollDismissesKeyboard: ScrollDismissesKeyboardMode = .immediately,
        selectionID: Binding<String?> = .constant(nil),
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: @escaping () -> Content2 = { EmptyView() },
        @ViewBuilder subHeader: @escaping () -> Content3? = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Content4? = { EmptyView() }
    ) {
        self.contentType = contentType
        self.content = content()
        self.header = header
        self.subHeader = subHeader
        self.footer = footer
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
            headerChunk
            
            if isList { listContent } else { scrollingContent }
                                                
            footer()
                .padding(.top, 10)
                            
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
            .padding(.horizontal, isBottomPanel ? 0 : 12)
            .padding(.top, isBottomPanel ? 0 : 12)
        }
        .scrollDismissesKeyboard(.immediately)
    }
    
    
    var headerChunk: some View {
        Group {
            header()
            subHeader()
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            /// Ignore the divider if showing in an iPad sidebar.
            if isSheet || isBottomPanel || contentType == .plainWithSelection {
                /// Only show in dark mode since colors are inversed in light mode.
                if colorScheme == .dark {
                    Divider()
                        //.padding(.horizontal)
                }
            }
        }
    }
    
    
    var headerChunkOG: some View {
        Group {
            header()
                .if(isSheet) {
                    $0.padding()
                }
                /// Align the sidebar header with the custom fake toolbar on the calendar, and align the section header with the weekdays on the calendar.
                .if(isSidebar) {
                    $0
                    .padding(.top, 14)
                    .padding(.bottom, 5)
                    .padding(.horizontal, 20)
                }
            
            subHeader()
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            /// Ignore the divider if showing in an iPad sidebar.
            if isSheet {
                if colorScheme == .dark {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
    }
}





