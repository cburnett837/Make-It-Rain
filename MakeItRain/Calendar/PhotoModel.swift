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
    
    /// Used to process images from the photo library.
    static func prepareDataFromPhotoPickerItem(image: PhotosPickerItem) async -> Data? {
        guard let ogImageData = try? await image.loadTransferable(type: Data.self) else { return nil }
        
        #if os(iOS)
        guard let inputImage = UIImage(data: ogImageData) else { return nil }
        let imageData = inputImage.jpegData(compressionQuality: 0.8) ?? Data()
        
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
    static func prepareDataFromUIImage(image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: 0.8)
    }
    #endif
    
   
    static func uploadPicture<U: Decodable>(
        imageData: Data,
        relatedID: String,
        uuid: String,
        isSmartTransaction: Bool = false,
        responseType: Result<U?, AppError>.Type
    ) async -> U? {
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
            recordID: relatedID,
            relatedTypeID: "5",
            uuid: uuid,
            imageData: imageData,
            isSmartTransaction: isSmartTransaction
        )
        
        switch await result {
        case .success(let model):
            print("photo upload succeeded")
            #if os(iOS)
            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            backgroundTaskID = .invalid
            #endif
            return model
            
        case .failure(let error):
            print(error)
            print("photo upload failed")
            
            #if os(iOS)
            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            backgroundTaskID = .invalid
            #endif
            return nil
        }
    }
    
    
    @MainActor
    static func delete(_ picture: CBPicture) async -> Bool {
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
