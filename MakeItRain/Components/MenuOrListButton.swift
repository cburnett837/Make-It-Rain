//
//  MenuOrListButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/21/24.
//

import SwiftUI

struct MenuOrListButton: View {
    var title: String?
    var alternateTitle: String
    
    var action: () -> Void
    
    var body: some View {
        HStack {
            Text(title ?? alternateTitle)
                .foregroundStyle(title == nil ? .gray : .primary)
            Spacer()
        }
        .contentShape(Rectangle())
        //.padding(.leading, 2)
        .focusable(false)
        .chevronMenuOverlay()
        .onTapGesture {
            action()
        }
    }
}
