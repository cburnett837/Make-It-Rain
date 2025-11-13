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
    
    @Observable
    class FileViewProps {
        var hoverFile: CBFile?
        var deleteFile: CBFile?
        var isDeletingFile = false
        var showDeleteFileAlert = false
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
                    Spacer()
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
                    fileUploadCompletedDelegate: fileUploadCompletedDelegate
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
                    fileUploadCompletedDelegate: fileUploadCompletedDelegate
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
    
    
    struct ConditionalFileView: View {
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
        
        var body: some View {
            @Bindable var props = props
            VStack {
                ZStack {
                    if file.isPlaceholder {
                        LoadingPlaceholder(text: "Uploading…", displayStyle: displayStyle)
                    } else {
                        
                        switch file.fileType {
                        case .photo:
                            FileImage(file: file, displayStyle: displayStyle)
                        case .pdf:
                            CustomAsyncPdf(file: file, displayStyle: displayStyle)
                        case .csv, .spreadsheet:
                            CustomAsyncCsv(file: file, displayStyle: displayStyle)
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
    
    
    struct LoadingPlaceholder: View {
        let text: String
        var displayStyle: FileSectionDisplayStyle
        
        var body: some View {
            Group {
                switch displayStyle {
                case .standard:
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: fileWidth, height: fileHeight)
                case .grid:
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.gray.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .overlay {
                VStack {
                    ProgressView()
                        .tint(.none)
                    Text(text)
                }
            }
        }
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
    
    
    struct CustomAsyncImage<Content: View, Placeholder: View>: View {
        #if os(iOS)
        @State var uiImage: UIImage?
        #else
        @State var nsImage: NSImage?
        #endif

        var file: CBFile
        @ViewBuilder var content: (Image) -> Content
        @ViewBuilder var placeholder: () -> Placeholder

        var body: some View {
            #if os(iOS)
                if let uiImage = uiImage {
                    content(Image(uiImage: uiImage))
                } else {
                    placeholder().task { await getImage() }
                }
            #else
                if let nsImage = nsImage {
                    content(Image(nsImage: nsImage))
                } else {
                    placeholder().task { await getImage() }
                }
            #endif
        }
        
        func getImage() async {
            let fileModel = FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
            let requestModel = RequestModel(requestType: "download_file", model: fileModel)
            let result = await NetworkManager().downloadFile(requestModel: requestModel)
            
            switch result {
            case .success(let data):
                if let data = data {
                    #if os(iOS)
                        self.uiImage = UIImage(data: data)
                    #else
                        self.nsImage = NSImage(data: data)
                    #endif
                }
                
            case .failure:
                AppState.shared.showAlert("There was a problem downloading the image.")
            }
        }
    }
    
    
    struct CustomAsyncPdf: View {
        var file: CBFile
        var displayStyle: FileSectionDisplayStyle

        @State private var data: Data?
                
        var body: some View {
            if let data = data {
                PDFKitRepresentedView(pdfData: data)
                    .frame(width: fileWidth, height: fileHeight)
                    .clipShape(.rect(cornerRadius: 14))
            } else {
                LoadingPlaceholder(text: "Downloading…", displayStyle: displayStyle)
                    .task { await getFile() }
            }
        }
        
        func getFile() async {
            let fileModel = FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
            let requestModel = RequestModel(requestType: "download_file", model: fileModel)
            let result = await NetworkManager().downloadFile(requestModel: requestModel)
            
            switch result {
            case .success(let data):
                self.data = data
                
            case .failure:
                AppState.shared.showAlert("There was a problem downloading the file.")
            }
        }
    }
    
    
    struct CustomAsyncCsv: View {
        var file: CBFile
        var displayStyle: FileSectionDisplayStyle
        
        @State private var page = WebPage()
        
        var body: some View {
            Group {
                if page.isLoading {
                    LoadingPlaceholder(text: "Downloading…", displayStyle: displayStyle)
                } else {
                    WebView(page)
                }
            }
            .frame(width: fileWidth, height: fileHeight)
            .clipShape(.rect(cornerRadius: 14))
            .task {
                let requestModel = RequestModel(
                    requestType: "download_file",
                    model: FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
                )
                
                let jsonData = try? JSONEncoder().encode(requestModel)
                var request = NetworkManager().request
                request!.setValue(AppState.shared.apiKey, forHTTPHeaderField: "Api-Key")
                request!.httpBody = jsonData
                
                page.load(request!)
            }
            
            
            
                
            
//            WebViewRep(requestModel: RequestModel(
//                requestType: "download_file",
//                model: FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
//            ))
//            .frame(width: fileWidth, height: fileHeight)
//            .clipShape(.rect(cornerRadius: 14))
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
    
    
    
    
    
    struct PhotoWebPreview: View {
        @Environment(\.colorScheme) var colorScheme
        @Environment(\.dismiss) var dismiss
        @State private var localFileURL: URL?
        @State private var isDownloading = false
        
        let file: CBFile
        
        var backgroundColor: Color {
            if file.fileType == .photo {
                .black
            } else {
                colorScheme == .dark ? .white : .black
            }   
        }

        var body: some View {
            NavigationStack {
                #if os(iOS)
                WebViewRep(backgroundColor: backgroundColor, requestModel: RequestModel(
                    requestType: "download_file",
                    model: FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
                ))
                .task { await downloadFileForShareLink() }
                .navigationTitle("File Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { shareLink }
                    ToolbarItem(placement: .topBarTrailing) { closeButton }
                }
                #endif
            }
        }

        @ViewBuilder
        var shareLink: some View {
            if let fileURL = localFileURL {
                ShareLink(item: fileURL) {
                    Image(systemName: "square.and.arrow.up")
                }
                .schemeBasedForegroundStyle()
            } else {
                ProgressView()
                    .schemeBasedTint()
            }
        }

        var closeButton: some View {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .schemeBasedForegroundStyle()
            }
        }
        
        func downloadFileForShareLink() async {
            isDownloading = true
            defer { isDownloading = false }
            
            let requestModel = RequestModel(
                requestType: "download_file",
                model: FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
            )
            
            let jsonData = try? JSONEncoder().encode(requestModel)
            var request = NetworkManager().request
            request!.setValue(AppState.shared.apiKey, forHTTPHeaderField: "Api-Key")
            request!.httpBody = jsonData
            
            do {
                let (data, _) = try await URLSession.shared.data(for: request!)
                let now = Date().string(to: .serverDateTime)
                let fileName = "make_it_rain_document_\(now)"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).\(file.fileType.ext)")
                try data.write(to: tempURL)
                await MainActor.run {
                    localFileURL = tempURL
                }
            } catch {
                print("Download failed: \(error)")
            }
        }
    }
                 
    
    
    
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
