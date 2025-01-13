//
//  NavLinkPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/7/24.
//

import SwiftUI

//#if os(iOS)
//struct NavLinkPhone: View {
//    @AppStorage("showIndividualLoadingSpinner") var showIndividualLoadingSpinner = false
//    
//    //@Environment(RootViewModelPhone.self) var vm
//    @Environment(CalendarModel.self) var calModel
//    @Binding var selectedDay: CBDay?
//    
//    let destination: NavDestination
//    let title: String
//    let image: String
//            
//    var iconColor: Color {
//        !AppState.shared.downloadedData.contains(destination) && showIndividualLoadingSpinner ? .gray : destination == NavigationManager.shared.selection ? .white : Color.accentColor
//    }
//    
//    
//    var body: some View {
//        
//        
////        NavigationLink(value: destination) {
////            Label(
////                title: {
////                    Text(title)
////                },
////                icon: {
////                    Image(systemName: image)
////                }
////            )
////        }
//        //.navRowBackgroundWithSelection(selection: destination)
//        
//        Button {
//            setNavSelection(destination)
//            if NavDestination.justMonths.contains(destination) {
//                calModel.setSelectedMonthFromNavigation(navID: destination, prepareStartAmount: true)
//            }
//        } label: {
//            Label(
//                title: {
//                    Text(title)
//                },
//                icon: {
//                    Image(systemName: image)
//                }
//            )
//        }
//        .navRowBackgroundWithSelection(selection: destination)
//    }
//    
//    func setNavSelection(_ selection: NavDestination) {
//        NavigationManager.shared.selection = selection
//        //vm.offset = 0
//        //vm.showMenu = false
//        selectedDay = nil
//    }
//}
//#endif




#if os(iOS)
struct NavLinkPhone2: View {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("useGrayBackground") var useGrayBackground = true
        
    let destination: NavDestination
    let title: String
    let image: String
    
    var backgroundColor: Color? {
        if destination == NavigationManager.shared.selection {
            if useGrayBackground && preferDarkMode {
                return Color(.tertiarySystemBackground)
            }
        } else {
            if preferDarkMode && useGrayBackground {
                return Color.darkGray
            }
        }
        return nil
    }
                
    var body: some View {
        NavigationLink(value: destination) {
            Label(
                title: { Text(title) },
                icon: { Image(systemName: image) }
            )
        }
        //.navRowBackgroundWithSelection(selection: destination)
        .rowBackgroundWithSelection(id: destination.rawValue, selectedID: NavigationManager.shared.selection?.rawValue)
        //.listRowBackground(backgroundColor)
    }
}
#endif
