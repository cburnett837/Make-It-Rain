//
//  StandardPhotoViews.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/3/25.
//

import SwiftUI

fileprivate let photoWidth: CGFloat = 125
fileprivate let photoHeight: CGFloat = 200
fileprivate let symbolWidth: CGFloat = 26

enum PhotoSectionDisplayStyle {
    case standard, grid
}

struct StandardPhotoSection: View {
    @Observable
    class PhotoViewProps {
        var hoverPic: CBPicture?
        var deletePic: CBPicture?
        var isDeletingPic = false
        var showDeletePicAlert = false
    }
        
    @Binding var pictures: [CBPicture]?
    var photoUploadCompletedDelegate: PhotoUploadCompletedDelegate
    var parentType: XrefEnum
    var displayStyle: PhotoSectionDisplayStyle = .standard
    var showInScrollView: Bool = true
    
    @Binding var showCamera: Bool
    @Binding var showPhotosPicker: Bool
    @State private var addPhotoButtonHoverColor2: Color = Color(.tertiarySystemFill)
    @State private var safariUrl: URL?
    @State private var props = PhotoViewProps()
    
    
    var photoType: XrefItem {
        XrefModel.getItem(from: .photoTypes, byEnumID: parentType)
    }
    
    let threeColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 5, alignment: .top), count: 3)
    
    var body: some View {
        @Bindable var photoModel = PhotoModel.shared
        HStack(alignment: .top) {
            if displayStyle == .standard {
                
                Image(systemName: "photo.fill")
                    .foregroundColor(.gray)
                    .frame(width: symbolWidth)
            }
            
            /// Check for active for 1 situation only - if a photo fails to upload, we deactivate it to hide the view.
            if let pictures = pictures?.filter({ $0.active }) {
                if displayStyle == .grid {
                    
                    
                    if pictures.count == 0 {
                        noPhotoInGridView
                    } else {
                        if showInScrollView {
                            ScrollView {
                                LazyVGrid(columns: threeColumnGrid, spacing: 5) {
                                    ForEach(pictures) { pic in
                                        ConditionalPicView(pic: pic, safariUrl: $safariUrl, displayStyle: displayStyle)
                                    }
                                }
                            }
                        } else {
                            LazyVGrid(columns: threeColumnGrid, spacing: 5) {
                                ForEach(pictures) { pic in
                                    ConditionalPicView(pic: pic, safariUrl: $safariUrl, displayStyle: displayStyle)
                                }
                            }
                        }
                    }
                    
                    
                    
                } else {
                    if showInScrollView {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 4) {
                                ForEach(pictures) { pic in
                                    ConditionalPicView(pic: pic, safariUrl: $safariUrl, displayStyle: displayStyle)
                                }
                                photoPickerButton
                            }
                        }
                    } else {
                        HStack(alignment: .top, spacing: 4) {
                            ForEach(pictures) { pic in
                                ConditionalPicView(pic: pic, safariUrl: $safariUrl, displayStyle: displayStyle)
                            }
                            photoPickerButton
                        }
                    }
                }
            } else {
                if displayStyle == .grid {
                    noPhotoInGridView
                } else {
                    photoPickerButton
                    Spacer()
                }
                
            }
            
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $photoModel.imagesFromLibrary, selectionBehavior: .continuousAndOrdered, matching: .images, photoLibrary: .shared())
        .onChange(of: showPhotosPicker) { oldValue, newValue in
            if !newValue {
                if PhotoModel.shared.imagesFromLibrary.isEmpty {
                    photoUploadCompletedDelegate.cleanUpPhotoVariables()
                } else {
                    PhotoModel.shared.uploadPicturesFromLibrary(delegate: photoUploadCompletedDelegate, photoType: photoType)
                }
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showCamera) {
            AccessCameraView(selectedImage: $photoModel.imageFromCamera)
                .background(.black)
        }
        .onChange(of: showCamera) { oldValue, newValue in
            if !newValue {
                PhotoModel.shared.uploadPictureFromCamera(delegate: photoUploadCompletedDelegate, photoType: photoType)
            }
        }
        #endif
        
        .environment(props)
        #if os(iOS)
        .sheet(item: $safariUrl) { SFSafariView(url: $0) }
        #endif
        
        .confirmationDialog("Delete this picture?", isPresented: $props.showDeletePicAlert) {
            Button("Yes", role: .destructive) {
                deletePicture()
            }
            Button("No", role: .cancel) {
                props.hoverPic = nil
                props.deletePic = nil
            }
        } message: {
            Text("Delete this picture?")
        }
    }

    var noPhotoInGridView: some View {
        VStack {
            Spacer()
            ContentUnavailableView("No Photos", systemImage: "photo.on.rectangle.angled", description: Text("Click below to add a photo."))
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
    
    
    var photoPickerButton: some View {
        VStack(spacing: 6) {
            Button(action: {
                showPhotosPicker = true
            }, label: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(addPhotoButtonHoverColor2)
                    #if os(iOS)
                    .frame(width: photoWidth, height: (photoHeight / 2) - 3)
                    #else
                    .frame(width: photoWidth, height: photoHeight)
                    #endif
                
                    .overlay {
                        VStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.title)
                            Text("Library")
                        }
                        .foregroundStyle(.gray)
                    }
            })
            .buttonStyle(.plain)
            .onHover { isHovered in addPhotoButtonHoverColor2 = isHovered ? Color(.systemFill) : Color(.tertiarySystemFill) }
            .focusEffectDisabled(true)
            
            #if os(iOS)
            Button {
                showCamera = true
            } label: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(addPhotoButtonHoverColor2)
                    .frame(width: photoWidth, height: (photoHeight / 2) - 3)
                    .overlay {
                        VStack {
                            Image(systemName: "camera")
                                .font(.title)
                            Text("Camera")
                        }
                        .foregroundStyle(.gray)
                    }
            }
            .buttonStyle(.plain)
            .onHover { isHovered in addPhotoButtonHoverColor2 = isHovered ? Color(.systemFill) : Color(.tertiarySystemFill) }
            .focusEffectDisabled(true)
            #endif
            
        }
    }

    
    struct ConditionalPicView: View {
        @Environment(PhotoViewProps.self) var props
        #if os(macOS)
        @Environment(\.openURL) var openURL
        #endif
        
        var pic: CBPicture
        @Binding var safariUrl: URL?
        var displayStyle: PhotoSectionDisplayStyle
        
        var body: some View {
            VStack {
                ZStack {
                    if pic.isPlaceholder {
                        PicPlaceholder(text: "Uploading…", displayStyle: displayStyle)
                    } else {
                        PicImage(pic: pic, displayStyle: displayStyle)
                    }
                    
                    #if os(macOS)
                    if props.hoverPic == pic {
                        PicButtons(pic: pic)
                    }
                    #endif
                }
            }
            #if os(macOS)
            /// Open in safari browser
            .onTapGesture {
                openURL(URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg")!)
            }
            /// Hover to show share button and delete button.
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    props.hoverPic = pic
                case .ended:
                    props.hoverPic = nil
                }
            }
            #else
            
            /// Open inline safari-sheet
            .onTapGesture {
                safariUrl = URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg")!
            }
            /// Long press to show delete (no share sheet option. Can share directly from safari sheet)
            .onLongPressGesture {
                //buzzPhone(.warning)
                props.deletePic = pic
                props.showDeletePicAlert = true
            }
            .sensoryFeedback(.warning, trigger: props.showDeletePicAlert) { oldValue, newValue in
                !oldValue && newValue
            }
            #endif
        }
    }
                 
    
    struct PicImage: View {
        @Environment(PhotoViewProps.self) var props
        var pic: CBPicture
        var displayStyle: PhotoSectionDisplayStyle
        
        var body: some View {
            @Bindable var props = props
            AsyncImage(
                //url: URL(string: "http://www.codyburnett.com:8677/budget_app.photo.\(picture.path).jpg"),
                url: URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg"),
                content: { image in
                    image
                        .resizable()
                        .if(displayStyle == .grid) {
                            $0.aspectRatio(1, contentMode: .fit)
                        }
                        .if(displayStyle == .standard) {
                            $0.frame(width: photoWidth, height: photoHeight).aspectRatio(contentMode: .fill)
                        }
                                                
                        .clipShape(.rect(cornerRadius: 12))
                        //.frame(maxWidth: 300, maxHeight: 300)
                },
                placeholder: {
                    PicPlaceholder(text: "Downloading…", displayStyle: displayStyle)
                }
            )
            .opacity(((props.isDeletingPic && pic.id == props.deletePic?.id) || props.hoverPic == pic || pic.isPlaceholder) ? 0.2 : 1)
            .overlay(ProgressView().tint(.none).opacity(props.isDeletingPic && pic.id == props.deletePic?.id ? 1 : 0))
        }
    }


    struct PicPlaceholder: View {
        let text: String
        var displayStyle: PhotoSectionDisplayStyle
        
        var body: some View {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .if(displayStyle == .grid) {
                    $0.aspectRatio(1, contentMode: .fit)
                }
                .if(displayStyle == .standard) {
                    $0.frame(width: photoWidth, height: photoHeight)
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
    
    
    
    #if os(macOS)
    struct PicButtons: View {
        @Environment(PhotoViewProps.self) var props
        var pic: CBPicture

        var body: some View {
            @Bindable var props = props

            VStack {
                HStack {
//                    Link(destination: URL(string: "http://\(Keys.baseURL):8677/budget_app.photo.\(pic.uuid).jpg")!) {
//                        Image(systemName: "arrow.down.left.and.arrow.up.right")
//                            .frame(width: 30, height: 30)
//                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
//                    }

                    ShareLink(item: URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg")! /*, subject: Text(trans.title), message: Text(trans.amountString)*/) {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color.accentColor)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
                    }
                    .buttonStyle(.plain)

                    Button {
                        props.deletePic = pic
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

            .opacity(props.isDeletingPic && pic.id == props.deletePic?.id ? 0 : 1)
            .disabled(props.isDeletingPic && pic.id != props.deletePic?.id)
        }
    }
    #endif
    
    
    
    
    
    func deletePicture() {
        Task {
            props.isDeletingPic = true
            let _ = await photoUploadCompletedDelegate.delete(picture: props.deletePic!, photoType: photoType)
            props.isDeletingPic = false
            props.deletePic = nil
        }
    }
}
