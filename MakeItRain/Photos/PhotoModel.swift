//
//  PhotoModel.swift
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

@MainActor
@Observable
class PhotoModel {
    static let shared = PhotoModel()
    var pictureParent: PictureParent?
    let compressionQuality: CGFloat = 0

    /// This is the photo from the photo library.
    var imagesFromLibrary: Array<PhotosPickerItem> = []
    #if os(iOS)
    /// This is the photo from the camera.
    var imageFromCamera: UIImage?
    #endif
    
    
    func uploadPicturesFromLibrary(delegate: PhotoUploadCompletedDelegate, photoType: XrefItem) {
        if imagesFromLibrary.isEmpty { return }
        delegate.alertUploadingSmartReceiptIfApplicable()
        Task {
            await withTaskGroup(of: Void.self) { group in
                let localImages = imagesFromLibrary
                imagesFromLibrary.removeAll()
                
                for each in localImages {
                    group.addTask {
                        if let imageData = await self.prepareDataFromPhotoPickerItem(image: each) {
                            await self.handlePhotoProgress(with: imageData, delegate: delegate, photoType: photoType)
                        }
                    }
                }
            }
        }
    }
        
    #if os(iOS)
    func uploadPictureFromCamera(delegate: PhotoUploadCompletedDelegate, photoType: XrefItem) {
        if let imageFromCamera = imageFromCamera, let imageData = self.prepareDataFromUIImage(image: imageFromCamera) {
            Task {
                self.imageFromCamera = nil
                delegate.alertUploadingSmartReceiptIfApplicable()
                await self.handlePhotoProgress(with: imageData, delegate: delegate, photoType: photoType)
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
        let imageData = inputImage.jpegData(compressionQuality: compressionQuality) ?? Data()
        
        #else
        guard let inputImage = NSImage(data: ogImageData) else { return nil }
        let cgImage = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        let imageData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:]) ?? Data()
        
        #endif
        
        return imageData
    }
    
    
    /// This is only used to process photos from the camera on iPhone.
    #if os(iOS)
    func prepareDataFromUIImage(image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: compressionQuality)
    }
    #endif
    
       
    func handlePhotoProgress(with imageData: Data, delegate: PhotoUploadCompletedDelegate, photoType: XrefItem) async {
        //calModel.uploadPicture(with: imageData)
        for await status in self.uploadPicture(with: imageData, delegate: delegate) {
            switch status {
            case .performCleanup:
                delegate.cleanUpPhotoVariables()
                
            case .readyForPlaceholder(let recordID, let uuid):
                print("\(#function) - readyForPlaceholder - \(uuid)")
                if let recordID = recordID {
                    delegate.addPlaceholderPicture(recordID: recordID, uuid: uuid, photoType: photoType)
                }
                
            case .uploaded(_, let uuid):
                print("\(#function) - uploaded - \(uuid)")
                //calModel.markPlaceholderPictureAsReadyForDownload(recordID: transactionID, uuid: uuid)
                
            case .displayCompleteAlert(let recordID, let uuid):
                print("\(#function) - displayCompleteAlert - \(uuid)")
                if let recordID = recordID {
                    delegate.displayCompleteAlert(recordID: recordID, photoType: photoType)
                }
                
            case .readyForDownload(let recordID, let uuid):
                print("\(#function) - readyForDownload - \(uuid)")
                if let recordID = recordID {
                    delegate.markPlaceholderPictureAsReadyForDownload(recordID: recordID, uuid: uuid, photoType: photoType)
                }
                
            case .failedToUpload(let recordID, let uuid):
                print("\(#function) - failedToUpload - \(uuid)")
                if let recordID = recordID {
                    delegate.markPictureAsFailedToUpload(recordID: recordID, uuid: uuid, photoType: photoType)
                }
                
            case .done:
                print("done")
            }
        }
    }
       
    
    
    func uploadPicture(with imageData: Data, delegate: PhotoUploadCompletedDelegate) -> AsyncStream<PhotoUploadProgress> {
        AsyncStream { continuation in
            delegate.alertUploadingSmartReceiptIfApplicable()
            
            /// Capture the set variable because if you start uploading a picture on a trans, and switch to another trans before the upload completes, you will change the pictureTransactionID before the async task completes.
            let pictureParent = self.pictureParent
            let smartTransactionDate = delegate.smartTransactionDate
            let isUploadingSmartTransactionPicture = delegate.isUploadingSmartTransactionPicture
            
            /// Clean up the variables so other actions can use them.
            continuation.yield(PhotoUploadProgress.performCleanup)
            
            let uuid = UUID().uuidString
            //alertUploadingSmartReceiptIfApplicable()
            
            if !isUploadingSmartTransactionPicture, let pictureParentID = pictureParent?.id {
                continuation.yield(PhotoUploadProgress.readyForPlaceholder(pictureParentID, uuid))
            }
            
            Task {
                print("Uploading ID \(pictureParent?.id ?? "nil") for type \(String(describing: pictureParent?.type))")
                typealias ResultResponse = Result<ResultCompleteModel?, AppError>
                if let _ = await self.uploadPicture(
                    imageData: imageData,
                    pictureParent: pictureParent, //--> will be nil when uploading a smart receipt.
                    uuid: uuid,
                    isSmartTransaction: isUploadingSmartTransactionPicture,
                    smartTransactionDate: smartTransactionDate,
                    responseType: ResultResponse.self
                ) {
                    continuation.yield(PhotoUploadProgress.uploaded(pictureParent?.id, uuid))
                                        
                    if !isUploadingSmartTransactionPicture, let pictureParentID = pictureParent?.id {
                        continuation.yield(PhotoUploadProgress.readyForDownload(pictureParentID, uuid))
                    }
                                        
                    /// Alert if the transaction has changed, or the user left the app.
                    #if os(iOS)
                    let state = UIApplication.shared.applicationState
                    if pictureParent?.id != self.pictureParent?.id || (state == .background || state == .inactive) {
                        continuation.yield(PhotoUploadProgress.displayCompleteAlert(pictureParent?.id, uuid))
                    }
                    #else
                    if pictureParent?.id != self.pictureParent?.id {
                        AppState.shared.showAlert("Picture Successfully Uploaded")
                    }
                    #endif
                    
                } else {
                    if !isUploadingSmartTransactionPicture, let pictureParentID = pictureParent?.id {
                        continuation.yield(PhotoUploadProgress.failedToUpload(pictureParentID, uuid))
                    }
                    
                    AppState.shared.alertBasedOnScenePhase(
                        title: "There was a problem uploading the picture",
                        subtitle: "Please try again.",
                        symbol: "photo",
                        symbolColor: .orange,
                        inAppPreference: .alert
                    )
                }
            
                continuation.yield(PhotoUploadProgress.done(pictureParent?.id, uuid))
                continuation.finish()
            }
        }
    }
    
    
    func uploadPicture<U: Decodable>(imageData: Data, pictureParent: PictureParent?, uuid: String, isSmartTransaction: Bool = false, smartTransactionDate: Date? = nil, responseType: Result<U?, AppError>.Type) async -> U? {
        /// There's only 3 things that need to be changed to add photo abilities to another project - indicated by a **
            
        let application = "budget_app" /// ** 2. Change me to add to another project
                        
        #if os(iOS)
        var backgroundTaskID: UIBackgroundTaskIdentifier?
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "Upload Photo") {
            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            backgroundTaskID = .invalid
        }
        #endif
        
        /// Upload to Server. If successful, add image to persons gift array. If fails, throw up a warning on the page
        //typealias ResultResponse = Result<U?, AppError>
        async let result: Result<U?, AppError> = await NetworkManager().uploadPicture(
            application: application,
            pictureParent: pictureParent,
            uuid: uuid,
            imageData: imageData,
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
    func delete(_ picture: CBPicture) async -> Bool {
        let model = RequestModel(requestType: "budget_app_delete_picture", model: picture)
                    
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

struct PictureParent {
    var id: String
    var type: XrefItem
}
