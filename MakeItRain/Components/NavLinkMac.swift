//
//  NavLink.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI

struct NavLinkMac: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    @AppStorage("showIndividualLoadingSpinner") var showIndividualLoadingSpinner = false
    
    let destination: NavDestination
    let title: String
    let image: String
            
    var iconColor: Color {
        //!AppState.shared.downloadedData.contains(destination) && showIndividualLoadingSpinner ? .gray : destination == NavigationManager.shared.selection ? .white : .blue
        !AppState.shared.downloadedData.contains(destination) && showIndividualLoadingSpinner ? .gray : destination == NavigationManager.shared.selection ? .white : Color.fromName(appColorTheme)
    }
    
    var body: some View {
        NavigationLink(value: destination) {
            HStack {
                Label(
                    title: {
                        Text(title)
                    },
                    icon: {
                        Image(systemName: image)
                            .tint(destination == .search ? Color.fromName(appColorTheme) : iconColor)
                    }
                )
            }
        }
        //.disabled(!AppState.shared.downloadedData.contains(destination))
    }
}
