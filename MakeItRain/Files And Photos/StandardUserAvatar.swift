//
//  StandardUserAvatar.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/26/25.
//

import SwiftUI
//
//struct StandardUserAvatar: View {
//    @Binding var avatar: CBFile?
//    var fileUploadCompletedDelegate: FileUploadCompletedDelegate?
//    
//    var body: some View {
//        if let avatar = avatar {
//            ConditionalFileView(
//                file: avatar,
//                selectedFile: $avatar,
//                displayStyle: .standard,
//                parentType: XrefModel.getItem(from: .fileTypes, byEnumID: .avatar),
//                fileUploadCompletedDelegate: fileUploadCompletedDelegate,
//                placeholderView: {
//                    ProgressView()
//                        .tint(.none)
//                }, photoView: {
//                    CustomAsyncImage(file: avatar) { image in
//                        image
//                            .resizable()
//                            .frame(width: 30, height: 30)
//                            .aspectRatio(contentMode: .fill)
//                            .clipShape(.circle)
//                    } placeholder: {
//                        ProgressView()
//                            .tint(.none)
//                    }
//                }
//            )
//        } else {
//            Image(systemName: "person.crop.circle")
//                .foregroundStyle(.gray)
//        }
//    }
//}
