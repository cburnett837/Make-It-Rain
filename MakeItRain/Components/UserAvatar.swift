//
//  UserAvatar.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/27/25.
//


import SwiftUI
import Contacts

struct UserAvatar: View {
    var user: CBUser?
    @State private var avatar: UIImage?
    
    var body: some View {
        Group {
            if let image = avatar {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 30, height: 30, alignment: .center)
                    .clipShape(.circle)
                
            } else {
                Text(user?.initials ?? "N/A")
                    .schemeBasedForegroundStyle()
                    .font(.caption2)
                    .frame(width: 30, height: 30)
                    .background(.gray)
                    .clipShape(.circle)
            }
        }
        .onChange(of: AppState.shared.accountUsers.filter { $0.id == user?.id }.first?.avatar, initial: true) { old, new in
            Task {
                await prepareAvatar(data: new)
            }
        }
    }
    
    func prepareAvatar(data: Data?) async {
        if let data = data, let image = UIImage(data: data) {
            self.avatar = image
        }
    }
}



struct ContactAvatar: View {
    var contact: CNContact?
    @State private var avatar: UIImage?
    
    var body: some View {
        Group {
            if let image = avatar {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 30, height: 30, alignment: .center)
                    .clipShape(.circle)
                
            } else {
                Text(contact?.initials ?? "N/A")
                    .schemeBasedForegroundStyle()
                    .font(.caption2)
                    .frame(width: 30, height: 30)
                    .background(.gray)
                    .clipShape(.circle)
            }
        }
        .task {
            await prepareAvatar(data: contact?.thumbnailImageData)
        }
        .onChange(of: contact) { old, new in
            Task {
                await prepareAvatar(data: new?.thumbnailImageData)
            }
        }
    }
    
    func prepareAvatar(data: Data?) async {
        if let data = data, let image = UIImage(data: data) {
            self.avatar = image
        } else {
            self.avatar = nil
        }
    }
}
