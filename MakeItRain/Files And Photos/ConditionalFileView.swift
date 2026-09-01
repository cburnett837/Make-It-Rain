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
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    #if os(macOS)
    @Environment(\.openURL) var openURL
    #endif
    
    var file: CBFile
    //@Binding var safariUrl: URL?
    @Binding var selectedFile: CBFile?
    var displayStyle: FileSectionDisplayStyle
    var parentType: XrefFileType
    var fileUploadCompletedDelegate: FileUploadCompletedDelegate
    var transLocation: WhereToLookForTransaction /// Needed only for the reciept itemizer from OpenAI
    @ViewBuilder var placeholderView: () -> Placeholder
    @ViewBuilder var photoView: () -> PhotoView
    @ViewBuilder var pdfView: () -> PdfView
    @ViewBuilder var csvView: () -> CsvView
    
    @State private var showDeleteFileAlert = false
    @State private var showFileOptions = false
    
    var body: some View {
        @Bindable var props = props
        VStack {
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
                        //FileButtons(file: file)
                    }
                    #endif
                }
            }
//            .popover(isPresented: $showFileOptions) {
//                Menu("Options") {
//                    Button("Open") {
//                        selectedFile = file
//                    }
//                    Button {
//                        //buzzPhone(.warning)
//                        props.deleteFile = file
//                        showDeleteFileAlert = true
//                    } label: {
//                        Text("Delete")
//                    }
//                    
//                    Button {
//                        itemize()
//                    } label: {
//                        Text("Itemize")
//                    }
//                }
//                .padding()
//                .presentationCompactAdaptation(.popover)
//            }
            .confirmationDialog("Options", isPresented: $showFileOptions) {
                Section {
                    Button("Open") {
                        selectedFile = file
                    }
                    
                    if file.fileType == .photo {
                        Button {
                            withAnimation {
                                file.isItemizing = true
                                funcModel.itemizeReceipt(file: file, transLocation: transLocation)
                            }
                            
                        } label: {
                            Text("Itemize")
                        }
                    }
                }
                
                Button("Delete", role: .destructive) {
                    //buzzPhone(.warning)
                    props.deleteFile = file
                    showDeleteFileAlert = true
                }
            }
//            .contextMenu {
//                Button {
//                    //buzzPhone(.warning)
//                    props.deleteFile = file
//                    showDeleteFileAlert = true
//                } label: {
//                    Text("Delete")
//                }
//                
//                Button {
//                    itemize()
//                } label: {
//                    Text("Itemize")
//                }
//
//            }
            .overlay {
                Color.gray.opacity(0.01)
                /// Open inline safari-sheet
                .onTapGesture {
//                    showFileOptions = true
                    selectedFile = file
                }
                /// Long press to show delete (no share sheet option. Can share directly from safari sheet)
                .onLongPressGesture {
                    //buzzPhone(.warning)
//                    props.deleteFile = file
//                    showDeleteFileAlert = true
                    showFileOptions = true
                }
//                
            }
            #if os(macOS)
            /// Open in safari browser
            .onTapGesture {
                openURL(URL(string: "https://\(Keys.prodBaseURL)/files/\(file.fileType.rawValue).photo.\(file.uuid).\(file.fileType.ext)")!)
            }
            /// Hover to show share button and delete button.
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    //props.hoverFile = file
                    file.isHovered = true
                case .ended:
                    file.isHovered = false
                    //props.hoverFile = nil
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
                #if os(iOS)
                Button("No", role: .close) {
                    file.isHovered = false
                    //props.hoverFile = nil
                    props.deleteFile = nil
                }
                #else
                Button("No") {
                    file.isHovered = false
                    //props.hoverFile = nil
                    props.deleteFile = nil
                }
                #endif
            } message: {
                Text("Delete this \(file.fileType.rawValue)?")
            }
            
            
            //itemizeButton
        }
        
    }
    
//    var itemizeButton: some View {
//        Button {
//            itemize()
//            
//        } label: {
//            Text("Itemize")
//        }
//        .buttonStyle(.borderedProminent)
//    }
    
    func deleteFile(fileType: FileType) {
        Task {
            file.isDeleting = true
            let _ = await fileUploadCompletedDelegate.delete(file: props.deleteFile!, parentType: parentType, fileType: fileType)
            file.isDeleting = false
            props.deleteFile = nil
        }
    }
    
//    func itemize() {
//        Task {
//            if let data = await funcModel.downloadFile(file: file),
//               let uiImage = UIImage(data: data),
//               let data = uiImage.jpegData(compressionQuality: 0) {
//                let base = data.base64EncodedString()
//                
//                let manager = IntelligenceManager()
//                
//                typealias ResultResponse = Result<ReceiptResponse?, AppError>
//                async let result: ResultResponse = await manager.request(base64Image: base)
//                await print(result)
//                
//                switch await result {
//                case .success(let receipt):
//                    if let receipt {
//                        guard receipt.isReceipt else {
//                            print("Photo was not a receipt")
//                            return
//                        }
//                        
//                        let lineItems = receipt.items
//                            .map { "\($0.itemName) - \($0.cost)" }
//                            .joined(separator: "\n")
//
//                        let result = """
//                        \(lineItems)
//
//                        (Line items extracted from receipt via OpenAI)
//                        """
//
//                        print(result)
//                        
//                        
//                        if let trans = calModel.getTransaction(by: file.relatedID) {
//                            if trans.notes == "" {
//                                trans.notes = AttributedString(result)
//                            } else {
//                                trans.notes += AttributedString("\n\n\(result)")
//                            }
//                        }
//                    }
//                    
//                    
//                    
//                case .failure(let error):
//                    switch error {
//                    case .taskCancelled:
//                        print("\(#function) Task Cancelled")
//                    default:
//                        LogManager.error(error.localizedDescription)
//                        AppState.shared.showAlert("There was a problem trying to save the starting amount.")
//                    }
//                }
//                
//                props.isItemizing = false
//            }
//            
//            
//        }
//    }
}
