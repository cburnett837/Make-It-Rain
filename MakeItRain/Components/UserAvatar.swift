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
    #if os(iOS)
    @State private var avatar: UIImage?
    #else
    @State private var avatar: NSImage?
    #endif
    
    var body: some View {
        Group {
            
            if avatar != nil {
                image
                    .resizable()
                    .frame(width: 30, height: 30, alignment: .center)
                    .clipShape(.circle)
            } else {
                placeholder
            }
        }
        .onChange(of: AppState.shared.accountUsers.filter { $0.id == user?.id }.first?.avatar, initial: true) { old, new in
            Task {
                await prepareAvatar(data: new)
            }
        }
    }
    
    
    var image: Image {
        #if os(iOS)
        Image(uiImage: avatar!)
        #else
        Image(nsImage: avatar!)
        #endif
    }
    
    
    var placeholder: some View {
        Text(user?.initials ?? "N/A")
            .schemeBasedForegroundStyle()
            .font(.caption2)
            .frame(width: 30, height: 30)
            .background(Color(.secondarySystemFill))
            .clipShape(.circle)
    }
    
    
    func prepareAvatar(data: Data?) async {
        #if os(iOS)
        if let data = data, let image = UIImage(data: data) {
            self.avatar = image
        }
        #else
        if let data = data, let image = NSImage(data: data) {
            self.avatar = image
        }
        #endif
    }
}



struct ContactAvatar: View {
    var contact: CNContact?
    #if os(iOS)
    @State private var avatar: UIImage?
    #else
    @State private var avatar: NSImage?
    #endif
    
    var body: some View {
        Group {
            if avatar != nil {
                image
                    .resizable()
                    .frame(width: 30, height: 30, alignment: .center)
                    .clipShape(.circle)
            } else {
                placeholder
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
    
    
    var image: Image {
        #if os(iOS)
        Image(uiImage: avatar!)
        #else
        Image(nsImage: avatar!)
        #endif
    }
    
    
    var placeholder: some View {
        Text(contact?.initials ?? "N/A")
            .schemeBasedForegroundStyle()
            .font(.caption2)
            .frame(width: 30, height: 30)
            .background(Color(.secondarySystemFill))
            .clipShape(.circle)
    }
    
    
    func prepareAvatar(data: Data?) async {
        #if os(iOS)
        if let data = data, let image = UIImage(data: data) {
            self.avatar = image
        } else {
            self.avatar = nil
        }
        #else
        if let data = data, let image = NSImage(data: data) {
            self.avatar = image
        } else {
            self.avatar = nil
        }
        #endif
    }
}
