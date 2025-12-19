//
//  CustomPhotoPicker.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/26/25.
//

import SwiftUI

enum ImageSourceType: String, Identifiable {
    var id: String { self.rawValue }
    case camera
    case photoLibrary
}

struct CustomImageAndCameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    let imageSourceType: ImageSourceType
    @Binding var selectedImage: UIImage?
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, selectedImage: $selectedImage)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.allowsEditing = true
        
        switch imageSourceType {
        case .camera:
            imagePicker.sourceType = .camera
            imagePicker.cameraCaptureMode = .photo
        case .photoLibrary:
            imagePicker.mediaTypes = ["public.image"]
            imagePicker.sourceType = .photoLibrary
        }
                        
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    typealias UIViewControllerType = UIImagePickerController
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CustomImageAndCameraPicker
        @Binding var selectedImage: UIImage?
        
        init(parent: CustomImageAndCameraPicker, selectedImage: Binding<UIImage?>) {
            self.parent = parent
            self._selectedImage = selectedImage
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            self.selectedImage = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            parent.dismiss()
        }
    }
}
