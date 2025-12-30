//
//  StandardPhotoViews.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/3/25.
//

import SwiftUI
import WebKit

fileprivate let fileWidth: CGFloat = 125
fileprivate let fileHeight: CGFloat = 250
fileprivate let symbolWidth: CGFloat = 26

enum FileSectionDisplayStyle {
    case standard, grid
}

struct StandardFileSection: View {
    struct SelectFileButtonType: Identifiable {
        var id: String { return title }
        var title: String
        var symbol: String
        var action: () -> Void
    }
            
    private struct MaxSymbolHeightPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = .zero

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

        
    @Binding var files: [CBFile]?
    var fileUploadCompletedDelegate: FileUploadCompletedDelegate
    var parentType: XrefEnum
    var displayStyle: FileSectionDisplayStyle = .standard
    var showInScrollView: Bool = true
    
    @Binding var showCamera: Bool
    @Binding var showPhotosPicker: Bool
    @State private var addFileButtonHoverColor2: Color = Color(.tertiarySystemFill)
    //@State private var safariUrl: URL?
    @State private var showFileWebView: Bool = false
    @State private var props = FileViewProps()
    @State private var selectedFile: CBFile?
    
    @State private var showFileImporter = false
    //@State private var selectedFileURL: URL?
    
    
    @State private var symbolHeight: CGFloat = 20.0
    
    var parentTypeXr: XrefItem {
        XrefModel.getItem(from: .fileTypes, byEnumID: parentType)
    }
    
    
    var fileButtons: Array<SelectFileButtonType> {[
        .init(title: "Camera", symbol: "camera", action: { showCamera = true }),
        .init(title: "Library", symbol: "photo.on.rectangle", action: { showPhotosPicker = true }),
        .init(title: "Files", symbol: "document.on.document", action: { showFileImporter = true })
    ]}
    
    
    let threeColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 5, alignment: .top), count: 3)
    
    var body: some View {
        @Bindable var fileModel = FileModel.shared
        HStack(alignment: .top) {
            /// Check for active for 1 situation only - if a file fails to upload, we deactivate it to hide the view.
            if let files = files?.filter({ $0.active }), !files.isEmpty {
                if displayStyle == .grid {
                    if files.isEmpty {
                        noFilesInGridView
                    } else {
                        if showInScrollView {
                            ScrollView {
                                photoGrid(files)
                            }
                        } else {
                            photoGrid(files)
                        }
                    }
                } else {
                    if showInScrollView {
                        ScrollView(.horizontal, showsIndicators: false) {
                            photoHstack(files)
                        }
                    } else {
                        photoHstack(files)
                    }
                }
            } else {
                if displayStyle == .grid {
                    noFilesInGridView
                } else {
                    fileSelectionButtons
                    //Spacer()
                }
            }
        }
        #if os(iOS)
        .sheet(item: $selectedFile) { file in
            PhotoWebPreview(file: file)
        }
        #endif
        .photoPickerAndCameraSheet(
            fileUploadCompletedDelegate: fileUploadCompletedDelegate,
            parentType: parentType,
            allowMultiSelection: true,
            showPhotosPicker: $showPhotosPicker,
            showCamera: $showCamera
        )
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .plainText, .commaSeparatedText, .spreadsheet],
            allowsMultipleSelection: true
        ) {
            handleFileSelection(result: $0)
        }
        .environment(props)
        .onPreferenceChange(MaxSymbolHeightPreferenceKey.self) { symbolHeight = max(symbolHeight, $0) }
    }

    var noFilesInGridView: some View {
        VStack {
            Spacer()
            ContentUnavailableView("No Files", systemImage: "photo.on.rectangle.angled", description: Text("Click below to add a file."))
            HStack {
                Button("Select Photo") {
                    showPhotosPicker = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("Take Photo") {
                    showCamera = true
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
    }
    
    
    @ViewBuilder func photoGrid(_ files: Array<CBFile>) -> some View {
        LazyVGrid(columns: threeColumnGrid, spacing: 5) {
            ForEach(files) { file in
                ConditionalFileView(
                    file: file,
                    selectedFile: $selectedFile,
                    displayStyle: displayStyle,
                    parentType: parentTypeXr,
                    fileUploadCompletedDelegate: fileUploadCompletedDelegate,
                    placeholderView: {
                        LoadingPlaceholder(text: "Uploading…", displayStyle: displayStyle)
                    }, photoView: {
                        FileImage(file: file, displayStyle: displayStyle)
                    }
                )
            }
        }
    }
    
    
    @ViewBuilder func photoHstack(_ files: Array<CBFile>) -> some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(files) { file in
                ConditionalFileView(
                    file: file,
                    selectedFile: $selectedFile,
                    displayStyle: displayStyle,
                    parentType: parentTypeXr,
                    fileUploadCompletedDelegate: fileUploadCompletedDelegate,
                    placeholderView: {
                        LoadingPlaceholder(text: "Uploading…", displayStyle: displayStyle)
                    }, photoView: {
                        FileImage(file: file, displayStyle: displayStyle)
                    }
                )
            }
            fileSelectionButtons
        }
    }
    
    
    @ViewBuilder
    var fileSelectionButtons: some View {
        let loop = ForEach(fileButtons) {
            fileButton(for: $0)
        }
        
        if files?.filter({ $0.active }).count ?? 0 > 0 {
            VStack(spacing: 6) { loop }
        } else {
            HStack(spacing: 6) { loop }
        }
    }
    
    
    
//    
//    @ViewBuilder
//    var fileButton: some View {
//        let thereAreFiles = files?.filter({ $0.active }).count ?? 0 > 0
//        
//        let tallRectangle = RoundedRectangle(cornerRadius: 14)
//            .fill(addFileButtonHoverColor2)
//            .frame(width: fileWidth, height: (fileHeight / 3) - 3)
//        
//        let shortRectangle = RoundedRectangle(cornerRadius: 14)
//            .fill(addFileButtonHoverColor2)
//            .frame(maxWidth: .infinity)
//            .frame(height: (fileHeight / 3) - 3)
//        
//        Button(action: {
//            showFileImporter = true
//        }, label: {
//            VStack {
//                if thereAreFiles {
//                    tallRectangle
//                } else {
//                    shortRectangle
//                }
//            }
//            .overlay {
//                VStack {
//                    Image(systemName: "document.badge.plus")
//                        .font(.title)
//                    Text("Files")
//                }
//                .foregroundStyle(.gray)
//            }
//        })
//        .buttonStyle(.plain)
//        .onHover { isHovered in addFileButtonHoverColor2 = isHovered ? Color(.systemFill) : Color(.tertiarySystemFill) }
//        .focusEffectDisabled(true)
//        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf, .plainText, .commaSeparatedText], allowsMultipleSelection: true) { handleFileSelection(result: $0) }
//    }
//    
    
    func handleFileSelection(result: Result<[URL], any Error>) {
        fileUploadCompletedDelegate.cleanUpPhotoVariables()
        
        switch result {
        case .success(let urls):
            var files: Array<FileData> = []
            for url in urls {
                
                var type: FileType?
                let gotAccess = url.startAccessingSecurityScopedResource()
                if !gotAccess { return }
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
                    if let contentType = resourceValues.contentType {
                        if contentType.conforms(to: .pdf) {
                            type = .pdf
                        } else if contentType.conforms(to: .image) {
                            type = .photo
                        } else if contentType.conforms(to: .commaSeparatedText) {
                            type = .csv
                        } else if contentType.conforms(to: .spreadsheet) {
                            type = .spreadsheet
                        }
                    }
                } catch {
                    print("File import failed: \(error.localizedDescription)")
                }
                                
                if let fileData = try? Data(contentsOf: url), let type = type {
                    files.append(FileData(fileType: type, data: fileData))
                }
                
                url.stopAccessingSecurityScopedResource()
            }
            
            if files.isEmpty { return }
            FileModel.shared.uploadFilesFromLibrary(files: files, delegate: fileUploadCompletedDelegate, parentType: parentTypeXr)
            
        case .failure(let error):
            print("Error selecting file: \(error.localizedDescription)")
        }
    }
    
    
    @ViewBuilder
    func fileButton(for button: SelectFileButtonType) -> some View {
        let thereAreFiles = files?.filter({ $0.active }).count ?? 0 > 0
        
        let tallRectangle = RoundedRectangle(cornerRadius: 14)
            .fill(addFileButtonHoverColor2)
            .frame(width: fileWidth/*, height: (fileHeight / 3) - 3*/) /// -4 to account for the padding
        
        let shortRectangle = RoundedRectangle(cornerRadius: 14)
            .fill(addFileButtonHoverColor2)
            .frame(maxWidth: .infinity)
            .frame(height: (fileHeight / 3))
        
        Button(action: button.action, label: {
            VStack {
                if thereAreFiles {
                    tallRectangle
                } else {
                    shortRectangle
                }
            }
            .overlay {
                VStack {
                    Image(systemName: button.symbol)
                        .font(.title)
                        /// Monitor the background size so all symbols are the same height.
                        .background { GeometryReader {
                            Color.clear.preference(key: MaxSymbolHeightPreferenceKey.self, value: $0.size.height) }
                        }
                        .frame(height: symbolHeight, alignment: .center)
                    Text(button.title)
                }
                .foregroundStyle(.gray)
            }
        })
        .buttonStyle(.plain)
        .onHover { isHovered in addFileButtonHoverColor2 = isHovered ? Color(.systemFill) : Color(.tertiarySystemFill) }
        .focusEffectDisabled(true)
    }
    
    
    
    
    
    
    
    
    struct FileImage: View {
        @Environment(FileViewProps.self) var props
        var file: CBFile
        var displayStyle: FileSectionDisplayStyle
        
        var isDeletingFile: Bool { props.isDeletingFile && file.id == props.deleteFile?.id }
        var dimImage: Bool { isDeletingFile || props.hoverFile == file || file.isPlaceholder }
        
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
                case .grid:
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 14))
                }
            } placeholder: {
                LoadingPlaceholder(text: "Downloading…", displayStyle: displayStyle)
            }

//            AsyncImage(
//                //url: URL(string: "http://www.codyburnett.com:8677/budget_app.photo.\(fileture.path).jpg"),
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
            .opacity(dimImage ? 0.2 : 1)
            .overlay(ProgressView().tint(.none).opacity(isDeletingFile ? 1 : 0))
        }
    }
    
    
    
    #if os(macOS)
    struct FileButtons: View {
        @Environment(FileViewProps.self) var props
        var file: CBFile

        var body: some View {
            @Bindable var props = props

            VStack {
                HStack {
//                    Link(destination: URL(string: "http://\(Keys.baseURL):8677/budget_app.photo.\(file.uuid).jpg")!) {
//                        Image(systemName: "arrow.down.left.and.arrow.up.right")
//                            .frame(width: 30, height: 30)
//                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
//                    }

                    ShareLink(item: URL(string: "https://\(Keys.baseURL):8676/files/budget_app.photo.\(file.uuid).jpg")! /*, subject: Text(trans.title), message: Text(trans.amountString)*/) {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color.accentColor)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
                    }
                    .buttonStyle(.plain)

                    Button {
                        props.deletePic = file
                        props.showDeletePicAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                            .frame(width: 30, height: 30)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
                    }
                    .buttonStyle(.plain)

                    //Spacer()
                }
                .padding(.leading, 4)
                Spacer()
            }
            .padding(.top, 4)

            .opacity(props.isDeletingPic && file.id == props.deletePic?.id ? 0 : 1)
            .disabled(props.isDeletingPic && file.id != props.deletePic?.id)
        }
    }
    #endif
    
    
//    func deleteFile() {
//        Task {
//            props.isDeletingPic = true
//            let _ = await fileUploadCompletedDelegate.delete(fileture: props.deletePic!, fileType: fileType)
//            props.isDeletingPic = false
//            props.deletePic = nil
//        }
//    }
}






import PDFKit

struct PDFKitRepresentedView: UIViewRepresentable {
    let pdfData: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: pdfData)
        pdfView.autoScales = true // Adjusts the PDF to fit the view
        pdfView.isUserInteractionEnabled = false
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update the view if needed, e.g., if pdfData changes
        uiView.document = PDFDocument(data: pdfData)
    }
}
