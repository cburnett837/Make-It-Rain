//
//  PhotoPickerAndCameraSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/4/25.
//


import Foundation
import SwiftUI

extension View {
    func photoPickerAndCameraSheet(
        fileUploadCompletedDelegate: FileUploadCompletedDelegate,
        parentType: XrefEnum,
        allowMultiSelection: Bool,
        showPhotosPicker: Binding<Bool>,
        showCamera: Binding<Bool>,
    ) -> some View {
        modifier(PhotoPickerAndCameraSheet(
            fileUploadCompletedDelegate: fileUploadCompletedDelegate,
            parentType: parentType,
            allowMultiSelection: allowMultiSelection,
            showPhotosPicker: showPhotosPicker,
            showCamera: showCamera
        ))
    }
}


struct PhotoPickerAndCameraSheet: ViewModifier {
    var fileUploadCompletedDelegate: FileUploadCompletedDelegate
    var parentType: XrefEnum
    var allowMultiSelection: Bool = false
    @Binding var showPhotosPicker: Bool
    @Binding var showCamera: Bool
    
    var parentTypeXr: XrefItem {
        XrefModel.getItem(from: .fileTypes, byEnumID: parentType)
    }
    
    //XrefModel.getItem(from: .fileTypes, byEnumID: .transaction)

    func body(content: Content) -> some View {
        @Bindable var photoModel = FileModel.shared
        
        return content
            .if(allowMultiSelection) {
                $0.photosPicker(
                    isPresented: $showPhotosPicker,
                    selection: $photoModel.imagesFromLibrary,
                    selectionBehavior: .continuousAndOrdered,
                    matching: .images,
                    photoLibrary: .shared()
                )
            }
        /// Only allow 1 photo since this is happening only for smart transactions.
            .if(!allowMultiSelection) {
                $0.photosPicker(
                    isPresented: $showPhotosPicker,
                    selection: $photoModel.imagesFromLibrary,
                    maxSelectionCount: 1,
                    matching: .images,
                    photoLibrary: .shared()
                )
            }
            
            /// Upload the picture from the selectedt photos when the photo picker sheet closes.
            .onChange(of: showPhotosPicker) {
                if !$1 {
                    if FileModel.shared.imagesFromLibrary.isEmpty {
                        fileUploadCompletedDelegate.cleanUpPhotoVariables()
                    } else {
                        FileModel.shared.uploadPicturesFromLibrary(
                            delegate: fileUploadCompletedDelegate,
                            parentType: parentTypeXr
                        )
                    }
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showCamera) {
                AccessCameraView(selectedImage: $photoModel.imageFromCamera)
                    .background(.black)
            }
            /// Upload the picture from the camera when the camera sheet closes.
            .onChange(of: showCamera) {
                if !$1 {
                    FileModel.shared.uploadPictureFromCamera(
                        delegate: fileUploadCompletedDelegate,
                        parentType: parentTypeXr
                    )
                }
            }
            #endif
            
    }
}
