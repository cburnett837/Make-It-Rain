//
//  FileImage.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/19/26.
//


import SwiftUI
import WebKit

fileprivate let fileWidth: CGFloat = 125
fileprivate let fileHeight: CGFloat = 250
fileprivate let symbolWidth: CGFloat = 26


struct FileImage: View {
    @Environment(FuncModel.self) var funcModel
    @Environment(FileViewProps.self) var props
    
    var file: CBFile
    var displayStyle: FileSectionDisplayStyle
    var transLocation: WhereToLookForTransaction /// Needed only for the reciept itemizer from OpenAI
    
//        var isDeletingFile: Bool { props.isDeletingFile && file.id == props.deleteFile?.id }
//        var dimImage: Bool { (props.isItemizing && props.itemizingFile == file) || isDeletingFile || props.hoverFile == file || file.isPlaceholder }
    
    var isDeletingFile: Bool { file.isDeleting }
    var dimImage: Bool { file.isItemizing || isDeletingFile || file.isHovered || file.isPlaceholder }
    
    var body: some View {
        @Bindable var props = props
        CustomAsyncImage(file: file) { image in
            switch displayStyle {
            case .standard:
                image
                    .resizable()
                    .frame(width: fileWidth, height: fileHeight)
                    .aspectRatio(contentMode: .fill)
                    .clipShape(.rect(cornerRadius: 14))
                    .onAppear {
                        if file.isItemizing {
                            funcModel.itemizeReceipt(file: file, transLocation: transLocation)
                        }
                    }
            case .grid:
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 14))
                    .onAppear {
                        if file.isItemizing {
                            funcModel.itemizeReceipt(file: file, transLocation: transLocation)
                        }
                    }
            }
        } placeholder: {
            LoadingPlaceholder(text: "Downloading…", displayStyle: displayStyle)
        }

//            AsyncImage(
//                url: URL(string: "https://\(Keys.baseURL):8676/files/budget_app.photo.\(file.uuid).jpg"),
//                content: { image in
//                    image
//                        .resizable()
//                        .if(displayStyle == .grid) {
//                            $0.aspectRatio(1, contentMode: .fit)
//                        }
//                        .if(displayStyle == .standard) {
//                            $0.frame(width: fileWidth, height: fileHeight).aspectRatio(contentMode: .fill)
//                        }
//
//                        .clipShape(.rect(cornerRadius: 12))
//                        //.frame(maxWidth: 300, maxHeight: 300)
//                },
//                placeholder: {
//                    LoadingPlaceholder(text: "Downloading…", displayStyle: displayStyle)
//                }
//            )
        .opacity(dimImage || file.isItemizing ? 0.2 : 1)
        //.overlay(ProgressView().tint(.none).opacity(dimImage ? 1 : 0))
        .overlay {
            if file.isItemizing {
                VStack {
                    AiAnimatedAliveSymbol(symbol: "brain", fontSize: .title)
                    AiAnimatedAliveLabel("Itemizing…", withGlow: true)
                }
                .opacity(file.isItemizing ? 1 : 0)
            }
        }
    }
}
