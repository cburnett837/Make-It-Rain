//
//  SheetHeader.swift
//  JarvisPhoneApp
//
//  Created by Cody Burnett on 8/8/24.
//

import SwiftUI

struct SheetHeader<Content: View, Content2: View, Content3: View>: View {
    let title: String
    let subtitle: String?
    var close: (() -> Void)?
    var view1: () -> Content?
    var view2: () -> Content2?
    var view3: () -> Content3?
    
    
    init(title: String,
         subtitle: String? = nil,
         close: @escaping (() -> Void),
         @ViewBuilder view1: @escaping () -> Content? = { EmptyView() },
         @ViewBuilder view2: @escaping () -> Content2? = { EmptyView() },
         @ViewBuilder view3: @escaping () -> Content3? = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.close = close
        self.view1 = view1
        self.view2 = view2
        self.view3 = view3
    }
                
    var body: some View {
        Group {
            if let subtitle = subtitle {
                VStack(spacing: 0) {
                    Text(title)
                        .frame(maxWidth: .infinity)
                        .font(.title3)
                        .overlay { theOverlay }
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            } else {
                Text(title)
                    .frame(maxWidth: .infinity)
                    .font(.title3)
                    .overlay { theOverlay }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
    }
        
    
    var theOverlay: some View {
        HStack {
            if let view1 = view1() {
                view1
                    .buttonStyle(.sheetHeader)
                    .focusable(false)
            }
            
            if let view2 = view2() {
                view2
                    .buttonStyle(.sheetHeader)
                    .focusable(false)
            }
                        
            Spacer()
                        
            if let view3 = view3() {
                view3
                    .buttonStyle(.sheetHeader)
                    .focusable(false)
            }
            
            Button {
                if let close {
                    close()
                }
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.sheetHeader)
            .focusable(false)
        }
        .padding(.top, 4)
        //.padding(.trailing, 8)
    }
}

//
//
//struct SheetHeader: View {
//    let title: String
//    let subtitle: String?
//    var delete: (() -> Void)?
//    var close: (() -> Void)?
//    var action1: (() -> Void)?
//    var image1: String?
//    var action2: (() -> Void)?
//    var image2: String?
//    
//    init(title: String,
//         subtitle: String? = nil,
//         close: @escaping (() -> Void),
//         delete: (() -> Void)? = nil,
//         action1: (() -> Void)? = nil,
//         image1: String? = nil,
//         action2: (() -> Void)? = nil,
//         image2: String? = nil)
//    {
//        self.title = title
//        self.subtitle = subtitle
//        self.delete = delete
//        self.close = close
//        self.action1 = action1
//        self.image1 = image1
//        self.action2 = action2
//        self.image2 = image2
//    }
//                
//    var body: some View {
//        Group {
//            if let subtitle = subtitle {
//                VStack(spacing: 0) {
//                    Text(title)
//                        .frame(maxWidth: .infinity)
//                        .font(.title3)
//                        .overlay { theOverlay }
//                    Text(subtitle)
//                        .font(.subheadline)
//                        .foregroundStyle(.gray)
//                }
//            } else {
//                Text(title)
//                    .frame(maxWidth: .infinity)
//                    .font(.title3)
//                    .overlay { theOverlay }
//            }
//        }
//        .frame(maxWidth: .infinity)
//        .padding(8)
//    }
//        
//    
//    var theOverlay: some View {
//        HStack {
//            if let image1 {
//                Button {
//                    action1?()
//                } label: {
//                    Image(systemName: image1)
//                }
//                .buttonStyle(.sheetHeader)
//                .focusable(false)
//            }
//            
//            if let image2 {
//                Button {
//                    action2?()
//                } label: {
//                    Image(systemName: image2)
//                }
//                .buttonStyle(.sheetHeader)
//                .focusable(false)
//            }
//            
//            Spacer()
//            
//            if let delete {
//                Button {
//                    #if os(iOS)
//                    Helpers.buzzPhone(.warning)
//                    #endif
//                    delete()
//                } label: {
//                    Image(systemName: "trash")
//                }
//                .buttonStyle(.sheetHeader)
//                .focusable(false)
//            }
//            
//            Button {
//                if let close = close {
//                    close()
//                }
//            } label: {
//                Image(systemName: "xmark")
//            }
//            .buttonStyle(.sheetHeader)
//            .focusable(false)
//        }
//        //.padding(.top, 4)
//        //.padding(.trailing, 8)
//    }
//}
//
//
