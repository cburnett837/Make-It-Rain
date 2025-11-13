//
//  NavLink.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI

struct NavLinkMac: View {
    @Environment(CalendarModel.self) var calModel
    
    
    //@Local(\.colorTheme) var colorTheme
    @AppStorage("showIndividualLoadingSpinner") var showIndividualLoadingSpinner = false
    
    let destination: NavDestination
    let title: String
    let image: String
            
    var iconColor: Color {
        //!AppState.shared.downloadedData.contains(destination) && showIndividualLoadingSpinner ? .gray : destination == NavigationManager.shared.selection ? .white : .blue
        !AppState.shared.downloadedData.contains(destination) && showIndividualLoadingSpinner ? .gray : destination == NavigationManager.shared.selection ? .white : Color.theme
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
                            .tint([.search, .debug].contains(destination) ? Color.theme : iconColor)
                    }
                )
            }
        }
        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
            calModel.dragTarget = nil
            return true
        } isTargeted: { isTargeted in
            if isTargeted {
                withAnimation {
                    NavigationManager.shared.selection = destination
                }
            }
        }
        //.disabled(!AppState.shared.downloadedData.contains(destination))
    }
}
