//
//  FileModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/7/25.
//

import Foundation
import SwiftUI
import PhotosUI
import CoreTransferable
#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif


struct FileData {
    var fileType: FileType
    var data: Data
}

@MainActor
@Observable
class FileModel {
    static let shared = FileModel()
    var fileParent: FileParent?
    let compressionQuality: CGFloat = 0

    /// This is the photo from the photo library.
    var imagesFromLibrary: Array<PhotosPickerItem> = []
    #if os(iOS)
    /// This is the photo from the camera.
    var imageFromCamera: UIImage?
    #endif
            
    
    func uploadFilesFromLibrary(files: Array<FileData>, delegate: FileUploadCompletedDelegate, parentType: XrefItem) {
        if files.isEmpty { return }
        Task {
            await withTaskGroup(of: Void.self) { group in
                for each in files {
                    group.addTask {
                        await self.handleFileProgress(with: each.data, fileType: each.fileType, delegate: delegate, parentType: parentType)
                    }
                }
            }
        }
    }
    
    
    func uploadPicturesFromLibrary(delegate: FileUploadCompletedDelegate, parentType: XrefItem) {
        if imagesFromLibrary.isEmpty { return }
        delegate.alertUploadingSmartReceiptIfApplicable()
        Task {
            await withTaskGroup(of: Void.self) { group in
                let localImages = imagesFromLibrary
                imagesFromLibrary.removeAll()
                
                for each in localImages {
                    group.addTask {
                        if let data = await self.prepareDataFromPhotoPickerItem(image: each) {
                            await self.handleFileProgress(with: data, fileType: .photo, delegate: delegate, parentType: parentType)
                        }
                    }
                }
            }
        }
    }
        
    #if os(iOS)
    func uploadPictureFromCamera(delegate: FileUploadCompletedDelegate, parentType: XrefItem) {
        if let imageFromCamera = imageFromCamera, let data = self.prepareDataFromUIImage(image: imageFromCamera) {
            Task {
                self.imageFromCamera = nil
                delegate.alertUploadingSmartReceiptIfApplicable()
                await self.handleFileProgress(with: data, fileType: .photo, delegate: delegate, parentType: parentType)
            }
            
        } else {
            delegate.cleanUpPhotoVariables()
        }
    }
    #endif
    
    
    /// Used to process images from the photo library.
    func prepareDataFromPhotoPickerItem(image: PhotosPickerItem) async -> Data? {
        guard let ogImageData = try? await image.loadTransferable(type: Data.self) else { return nil }
        
        #if os(iOS)
        guard let inputImage = UIImage(data: ogImageData) else { return nil }
        let data = inputImage.jpegData(compressionQuality: compressionQuality) ?? Data()
        
        #else
        guard let inputImage = NSImage(data: ogImageData) else { return nil }
        let cgImage = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        let data = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:]) ?? Data()
        
        #endif
        
        return data
    }
    
    
    /// This is only used to process photos from the camera on iPhone.
    #if os(iOS)
    func prepareDataFromUIImage(image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: compressionQuality)
    }
    #endif
    
       
    func handleFileProgress(with data: Data, fileType: FileType, delegate: FileUploadCompletedDelegate, parentType: XrefItem) async {
        //calModel.uploadFile(with: data)
        for await status in self.uploadFile(with: data, fileType: fileType, delegate: delegate) {
            switch status {
            case .performCleanup:
                delegate.cleanUpPhotoVariables()
                
            case .readyForPlaceholder(let recordID, let uuid):
                print("\(#function) - readyForPlaceholder - \(uuid)")
                if let recordID = recordID {
                    delegate.addPlaceholderFile(recordID: recordID, uuid: uuid, parentType: parentType, fileType: fileType)
                }
                
            case .uploaded(_, let uuid):
                print("\(#function) - uploaded - \(uuid)")
                //calModel.markPlaceholderFileAsReadyForDownload(recordID: transactionID, uuid: uuid)
                
            case .displayCompleteAlert(let recordID, let uuid):
                print("\(#function) - displayCompleteAlert - \(uuid)")
                if let recordID = recordID {
                    delegate.displayCompleteAlert(recordID: recordID, parentType: parentType, fileType: fileType)
                }
                
            case .readyForDownload(let recordID, let uuid):
                print("\(#function) - readyForDownload - \(uuid)")
                if let recordID = recordID {
                    delegate.markPlaceholderFileAsReadyForDownload(recordID: recordID, uuid: uuid, parentType: parentType, fileType: fileType)
                }
                
            case .failedToUpload(let recordID, let uuid):
                print("\(#function) - failedToUpload - \(uuid)")
                if let recordID = recordID {
                    delegate.markFileAsFailedToUpload(recordID: recordID, uuid: uuid, parentType: parentType, fileType: fileType)
                }
                
            case .done:
                print("done")
            }
        }
    }
       
    
    
    func uploadFile(with data: Data, fileType: FileType, delegate: FileUploadCompletedDelegate) -> AsyncStream<FileUploadProgress> {
        AsyncStream { continuation in
            //delegate.alertUploadingSmartReceiptIfApplicable()
            
            /// Capture the set variable because if you start uploading a file on a trans, and switch to another trans before the upload completes, you will change the fileTransactionID before the async task completes.
            let fileParent = self.fileParent
            let smartTransactionDate = delegate.smartTransactionDate
            let isUploadingSmartTransactionFile = delegate.isUploadingSmartTransactionFile
            
            /// Clean up the variables so other actions can use them.
            continuation.yield(FileUploadProgress.performCleanup)
            
            let uuid = UUID().uuidString
            //alertUploadingSmartReceiptIfApplicable()
            
            if !isUploadingSmartTransactionFile, let fileParentID = fileParent?.id {
                continuation.yield(FileUploadProgress.readyForPlaceholder(fileParentID, uuid))
            }
            
            Task {
                print("Uploading ID \(fileParent?.id ?? "nil") for type \(String(describing: fileParent?.type))")
                typealias ResultResponse = Result<ResultCompleteModel?, AppError>
                if let _ = await self.uploadFile(
                    data: data,
                    fileParent: fileParent, //--> will be nil when uploading a smart receipt.
                    fileType: fileType,
                    uuid: uuid,
                    isSmartTransaction: isUploadingSmartTransactionFile,
                    smartTransactionDate: smartTransactionDate,
                    responseType: ResultResponse.self
                ) {
                    continuation.yield(FileUploadProgress.uploaded(fileParent?.id, uuid))
                                        
                    if !isUploadingSmartTransactionFile, let fileParentID = fileParent?.id {
                        continuation.yield(FileUploadProgress.readyForDownload(fileParentID, uuid))
                    }
                                        
                    /// Alert if the transaction has changed, or the user left the app.
                    #if os(iOS)
                    let state = UIApplication.shared.applicationState
                    if fileParent?.id != self.fileParent?.id || (state == .background || state == .inactive) {
                        continuation.yield(FileUploadProgress.displayCompleteAlert(fileParent?.id, uuid))
                    }
                    #else
                    if fileParent?.id != self.fileParent?.id {
                        AppState.shared.showAlert("File Successfully Uploaded")
                    }
                    #endif
                    
                } else {
                    if !isUploadingSmartTransactionFile, let fileParentID = fileParent?.id {
                        continuation.yield(FileUploadProgress.failedToUpload(fileParentID, uuid))
                    }
                    
                    AppState.shared.alertBasedOnScenePhase(
                        title: "There was a problem uploading the file",
                        subtitle: "Please try again.",
                        symbol: "photo",
                        symbolColor: .orange,
                        inAppPreference: .alert
                    )
                }
            
                continuation.yield(FileUploadProgress.done(fileParent?.id, uuid))
                continuation.finish()
            }
        }
    }
    
    
    func uploadFile<U: Decodable>(
        data: Data,
        fileParent: FileParent?,
        fileType: FileType, 
        uuid: String,
        isSmartTransaction: Bool = false,
        smartTransactionDate: Date? = nil,
        responseType: Result<U?, AppError>.Type
    ) async -> U? {
        /// There's only 3 things that need to be changed to add photo abilities to another project - indicated by a **
            
        let application = "budget_app" /// ** 2. Change me to add to another project
                        
        #if os(iOS)
        var backgroundTaskID: UIBackgroundTaskIdentifier?
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "Upload File") {
            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            backgroundTaskID = .invalid
        }
        #endif
        
        /// Upload to Server. If successful, add image to persons gift array. If fails, throw up a warning on the page
        //typealias ResultResponse = Result<U?, AppError>
        async let result: Result<U?, AppError> = await NetworkManager().uploadFile(
            application: application,
            fileParent: fileParent,
            uuid: uuid,
            fileData: data,
            fileName: fileType.defaultName,
            fileType: fileType,
            isSmartTransaction: isSmartTransaction,
            smartTransactionDate: smartTransactionDate
        )
        
        switch await result {
        case .success(let model):
            #if os(iOS)
            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            backgroundTaskID = .invalid
            #endif
            return model
            
        case .failure(let error):
            print(error)
            #if os(iOS)
            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            backgroundTaskID = .invalid
            #endif
            return nil
        }
    }
    
    
    @MainActor
    func delete(_ file: CBFile) async -> Bool {
        let model = RequestModel(requestType: "budget_app_delete_file", model: file)
                    
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                
        switch await result {
        case .success:
            return true
                        
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            return false
        }
    }
    
    
    
    struct TransferableImage: Transferable {
        #if os(macOS)
            let image: NSImage
        #else
            let image: UIImage
        #endif
        
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
            #if os(macOS)
                guard let nsImage = NSImage(data: data) else {
                    throw TransferError.importFailed
                }
                return TransferableImage(image: nsImage)
                
            #elseif canImport(UIKit)
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                return TransferableImage(image: uiImage)
            #else
                throw TransferError.importFailed
            #endif
            }
        }
    }
}

struct FileParent {
    var id: String
    var type: XrefItem
}





