//
//  NavLinkPad.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/7/24.
//

import SwiftUI

#if os(iOS)
struct NavLinkPad: View {
    @AppStorage("useGrayBackground") var useGrayBackground = true
    //@Local(\.colorTheme) var colorTheme
        
    let destination: NavDestination
//    let title: String
//    let image: String
    var linkWidth: CGFloat
    var linkHeight: CGFloat
    
    var body: some View {
        Group {            
            Button {
                NavigationManager.shared.selectedMonth = nil
                NavigationManager.shared.selection = destination
            } label: {
                HStack {
                    Image(systemName: destination.symbol)
                        .foregroundStyle(Color.theme)
                        .frame(minWidth: linkWidth, alignment: .center)
                        .background { GeometryReader { Color.clear.preference(key: MaxNavWidthPreferenceKey.self, value: $0.size.width) } }
                        .font(.title3)
                    
                    Text(destination.displayName)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
//                    Image(systemName: "chevron.right")
//                        .foregroundStyle(Color.gray)
                       // .padding(.trailing, 10)
                }
                .contentShape(Rectangle())
                //.frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .frame(height: linkHeight)
            .background { GeometryReader { Color.clear.preference(key: MaxNavHeightPreferenceKey.self, value: $0.size.height) } }
            .padding(15)
            //.padding(.vertical, 15)
            //.padding(.leading, 15)
            .background(
                Capsule()
                //RoundedRectangle(cornerRadius: 6)
                    .fill(NavigationManager.shared.selection == destination ? Color(.tertiarySystemFill) : Color.clear)
                    .padding(.horizontal, 5)
            )
            //.offset(x: -15)
            
            
//            if AppState.shared.isIpad {
//                Button {
//                    NavigationManager.shared.selectedMonth = nil
//                    NavigationManager.shared.selection = destination
//                } label: {
//                    HStack {
//                        Image(systemName: destination.symbol)
//                            .foregroundStyle(Color.theme)
//                            .frame(minWidth: linkWidth, alignment: .center)
//                            .background { GeometryReader { Color.clear.preference(key: MaxNavWidthPreferenceKey.self, value: $0.size.width) } }
//                            .font(.title3)
//                        
//                        Text(destination.displayName)
//                            .foregroundStyle(.primary)
//                        
//                        Spacer()
//                        
//                        Image(systemName: "chevron.right")
//                            .foregroundStyle(Color.gray)
//                           // .padding(.trailing, 10)
//                    }
//                    .contentShape(Rectangle())
//                    //.frame(maxWidth: .infinity, alignment: .leading)
//                }
//                .buttonStyle(.plain)
//                .frame(height: linkHeight)
//                .background { GeometryReader { Color.clear.preference(key: MaxNavHeightPreferenceKey.self, value: $0.size.height) } }
//                .padding(.vertical, 10)
//                .padding(.trailing, 10)
//                .background(
//                    RoundedRectangle(cornerRadius: 6)
//                        .fill(NavigationManager.shared.selection == destination ? Color(.tertiarySystemFill) : Color.clear)
//                )
//                
//
//            } else {
//                NavigationLink(value: destination) {
//                    HStack {
//                        Image(systemName: image)
//                            .foregroundStyle(Color.theme)
//                            .frame(minWidth: linkWidth, alignment: .center)
//                            .background { GeometryReader { Color.clear.preference(key: MaxNavWidthPreferenceKey.self, value: $0.size.width) } }
//                            .font(.title3)
//                        
//                        Text(title)
//                            .foregroundStyle(.primary)
//                        
//                        Spacer()
//                        
//                        Image(systemName: "chevron.right")
//                            .foregroundStyle(Color.gray)
//                            //.padding(.trailing, 10)
//                    }
//                    .contentShape(Rectangle())
//                    //.frame(maxWidth: .infinity, alignment: .leading)
//                }
//                .buttonStyle(.plain)
//                .frame(height: linkHeight)
//                .background { GeometryReader { Color.clear.preference(key: MaxNavHeightPreferenceKey.self, value: $0.size.height) } }
//                .padding(.vertical, 10)
//                .padding(.trailing, 10)
//            }
        }
    }
}


#endif
