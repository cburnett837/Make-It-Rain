//
//  ConditionalFileView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/26/25.
//


import SwiftUI
import WebKit
import PDFKit

struct ConditionalFileView<Placeholder: View, PhotoView: View, PdfView: View, CsvView: View>: View {
    @Environment(FileViewProps.self) var props
    #if os(macOS)
    @Environment(\.openURL) var openURL
    #endif
    
    var file: CBFile
    //@Binding var safariUrl: URL?
    @Binding var selectedFile: CBFile?
    var displayStyle: FileSectionDisplayStyle
    var parentType: XrefItem
    var fileUploadCompletedDelegate: FileUploadCompletedDelegate
    @State private var showDeleteFileAlert = false
    
    @ViewBuilder var placeholderView: () -> Placeholder
    @ViewBuilder var photoView: () -> PhotoView
    @ViewBuilder var pdfView: () -> PdfView
    @ViewBuilder var csvView: () -> CsvView
    
    var body: some View {
        @Bindable var props = props
        VStack {
            ZStack {
                if file.isPlaceholder {
                    placeholderView()
                    //LoadingPlaceholder(text: "Uploading…", displayStyle: displayStyle)
                } else {
                    
                    switch file.fileType {
                    case .photo:
                        photoView()
                        //FileImage(file: file, displayStyle: displayStyle)
                    case .pdf:
                        pdfView()
                        //CustomAsyncPdf(file: file, displayStyle: displayStyle)
                    case .csv, .spreadsheet:
                        csvView()
                        //CustomAsyncCsv(file: file, displayStyle: displayStyle)
                    }
                }
                
                #if os(macOS)
                if props.hoverFile == file {
                    FileButtons(file: file)
                }
                #endif
            }
        }        
        .overlay {
            Color.gray.opacity(0.01)
            /// Open inline safari-sheet
            .onTapGesture {
                selectedFile = file
            }
            /// Long press to show delete (no share sheet option. Can share directly from safari sheet)
            .onLongPressGesture {
                //buzzPhone(.warning)
                props.deleteFile = file
                showDeleteFileAlert = true
            }
        }
        #if os(macOS)
        /// Open in safari browser
        .onTapGesture {
            openURL(URL(string: "https://\(Keys.baseURL):8676/files/\(file.fileType.rawValue).photo.\(file.uuid).\(file.fileType.ext)")!)
        }
        /// Hover to show share button and delete button.
        .onContinuousHover { phase in
            switch phase {
            case .active:
                props.hoverFile = file
            case .ended:
                props.hoverFile = nil
            }
        }
        #else
        /// Open inline safari-sheet
//            .onTapGesture {
//                selectedFile = file
//            }
        /// Long press to show delete (no share sheet option. Can share directly from safari sheet)
//            .onLongPressGesture {
//                props.deleteFile = file
//                showDeleteFileAlert = true
//            }
        .sensoryFeedback(.warning, trigger: props.showDeleteFileAlert) { !$0 && $1 }
        #endif
        .confirmationDialog("Delete this \(file.fileType.rawValue)?", isPresented: $showDeleteFileAlert) {
            Button("Yes", role: .destructive) {
                deleteFile(fileType: .photo)
            }
            Button("No", role: .close) {
                props.hoverFile = nil
                props.deleteFile = nil
            }
        } message: {
            Text("Delete this \(file.fileType.rawValue)?")
        }
    }
    
    func deleteFile(fileType: FileType) {
        Task {
            props.isDeletingFile = true
            let _ = await fileUploadCompletedDelegate.delete(file: props.deleteFile!, parentType: parentType, fileType: fileType)
            props.isDeletingFile = false
            props.deleteFile = nil
        }
    }
}
