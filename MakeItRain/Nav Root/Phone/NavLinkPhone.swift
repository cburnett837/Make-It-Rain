//
//  NavLinkPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/29/25.
//

import SwiftUI

struct NavLinkPhone: View {
    let destination: NavDestination
    
    var body: some View {
        NavigationLink(value: destination) {
            Label {
                Text(destination.displayName)
            } icon: {
                Image(systemName: destination.symbol)
            }
        }
    }
}
