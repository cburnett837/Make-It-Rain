//
//  NavLinkPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/7/24.
//

import SwiftUI

#if os(iOS)
struct NavLinkPhone: View {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("useGrayBackground") var useGrayBackground = true
        
    let destination: NavDestination
    let title: String
    let image: String
    
//    var backgroundColor: Color? {
//        if destination == NavigationManager.shared.selection {
//            if useGrayBackground && preferDarkMode {
//                return Color(.tertiarySystemBackground)
//            }
//        } else {
//            if preferDarkMode && useGrayBackground {
//                return Color.darkGray
//            }
//        }
//        return nil
//    }
                
    var body: some View {
        Group {
            if AppState.shared.isIpad {
                Button {
                    NavigationManager.shared.navPath = [destination]
                } label: {
                    Label(
                        title: { Text(title) },
                        icon: { Image(systemName: image) }
                    )
                }

            } else {
                NavigationLink(value: destination) {
                    Label(
                        title: { Text(title) },
                        icon: { Image(systemName: image) }
                    )
                }
            }
        }
        
        
        //.navRowBackgroundWithSelection(selection: destination)
        .rowBackgroundWithSelection(id: destination.rawValue, selectedID: NavigationManager.shared.selection?.rawValue)
        //.listRowBackground(backgroundColor)
    }
}
#endif
