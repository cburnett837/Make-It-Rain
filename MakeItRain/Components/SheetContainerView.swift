//
//  SheetContainerView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/6/25.
//

import SwiftUI

enum SheetContainerContentType {
    case list, scrolling
}

//struct SheetContainerNavView<Content: View, Content2: View, Content3: View, Content4: View>: View {
//    let contentType: SheetContainerContentType
//    @ViewBuilder var content: Content
//    //@ViewBuilder var header: Content2
//    var header: () -> Content2?
//    var subHeader: () -> Content3?
//    var footer: () -> Content4?
//    
//    let title: String
//    let subtitle: String?
//    var close: (() -> Void)?
//    var view1: () -> Content?
//    var view2: () -> Content2?
//    var view3: () -> Content3?
//    
//    
//    
//    init(
//        _ contentType: SheetContainerContentType = .scrolling,
//        @ViewBuilder content: @escaping () -> Content,
//        @ViewBuilder header: @escaping () -> Content2 = { EmptyView() },
//        @ViewBuilder subHeader: @escaping () -> Content3? = { EmptyView() },
//        @ViewBuilder footer: @escaping () -> Content4? = { EmptyView() }
//    ) {
//        self.contentType = contentType
//        self.content = content()
//        self.header = header
//        self.subHeader = subHeader
//        self.footer = footer
//    }
//    
//    var body: some View {
//        if contentType == .list {
//            
//            NavigationStack {
//                List { content }
//                    .scrollDismissesKeyboard(.immediately)
//                                
//                footer()
//                    .padding(.top, 10)
//                
//                    .toolbar {
//                        ToolbarItemGroup(placement: .topBarLeading) {
//                            HStack {
//                                if let view1 = view1() {
//                                    view1
//                                        .buttonStyle(.sheetHeader)
//                                        .focusable(false)
//                                }
//                                
//                                if let view2 = view2() {
//                                    view2
//                                        .buttonStyle(.sheetHeader)
//                                        .focusable(false)
//                                }
//                            }
//                        }
//                        
//                        ToolbarItemGroup(placement: .topBarTrailing) {
//                            HStack {
//                                if let view3 = view3() {
//                                    view3
//                                        .buttonStyle(.sheetHeader)
//                                        .focusable(false)
//                                }
//                                
//                                Button {
//                                    if let close {
//                                        close()
//                                    }
//                                } label: {
//                                    Image(systemName: "xmark")
//                                }
//                                .buttonStyle(.sheetHeader)
//                                .focusable(false)
//                                .keyboardShortcut(.return, modifiers: [.command]) /// Just because I am used to it from the original app.
//                            }
//                        }
//                    }
//                    .navigationTitle(title)
//                    .navigationBarTitleDisplayMode(.inline)
//            }
//            #if os(macOS)
//            .padding(.bottom, 10)
//            #endif
//                        
//        } else {
//            VStack(spacing: 0) {
//                #if os(iOS)
//                if AppState.shared.isIpad || AppState.shared.isIphoneInPortrait {
//                    headerChunk
//                }
//                #else
//                headerChunk
//                #endif
//                
//                ScrollView {
//                    #if os(iOS)
//                    if AppState.shared.isIphoneInLandscape {
//                        headerChunk
//                    }
//                    #endif
//                    VStack(alignment: .leading, spacing: 6) {
//                        content
//                    }
//                    .padding(.horizontal)
//                    .padding(.top, 12)
//                }
//                .scrollDismissesKeyboard(.immediately)
//                
//                footer()
//                    .padding(.top, 10)
//            }
//            #if os(macOS)
//            .padding(.bottom, 10)
//            #endif
//        }
//    }
//    
//    var headerChunk: some View {
//        Group {
//            header()
//                .padding()
//            
//            subHeader()
//                .padding(.horizontal)
//                .padding(.bottom, 10)
//            
//            Divider()
//                .padding(.horizontal)
//        }
//    }
//}




struct SheetContainerView<Content: View, Content2: View, Content3: View, Content4: View>: View {
    let contentType: SheetContainerContentType
    @ViewBuilder var content: Content
    //@ViewBuilder var header: Content2
    var header: () -> Content2?
    var subHeader: () -> Content3?
    var footer: () -> Content4?
    
    init(
        _ contentType: SheetContainerContentType = .scrolling,
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
    }
    
    var body: some View {
        if contentType == .list {
            VStack(spacing: 0) {
                headerChunk
                            
                List { content }
                    .scrollDismissesKeyboard(.immediately)
                                
                footer()
                    .padding(.top, 10)
                                
            }
            #if os(macOS)
            .padding(.bottom, 10)
            #endif
                        
        } else {
            VStack(spacing: 0) {
                #if os(iOS)
                if AppState.shared.isIpad || AppState.shared.isIphoneInPortrait {
                    headerChunk
                }
                #else
                headerChunk
                #endif
                
                ScrollView {
                    #if os(iOS)
                    if AppState.shared.isIphoneInLandscape {
                        headerChunk
                    }
                    #endif
                    VStack(alignment: .leading, spacing: 6) {
                        content
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                .scrollDismissesKeyboard(.immediately)
                
                footer()
                    .padding(.top, 10)
            }
            #if os(macOS)
            .padding(.bottom, 10)
            #endif
        }
    }
    
    var headerChunk: some View {
        Group {
            header()
                .padding()
            
            subHeader()
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            Divider()
                .padding(.horizontal)
        }
    }
}
