//
//  TevHashtags.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/18/25.
//

import SwiftUI

struct TevHashtags: View {
    //var trans: CBTransaction
    var tags: [CBTag]
    var header: String?
    var footer: String?
        
    var body: some View {
        Section {
            content
        } header: {
            if let header {
                Text(header)
            }
        } footer: {
            if let footer {
                Text(footer)
            }
        }
    }
    
    
    var content: some View {
        NavigationLink(value: TransNavDest.tags) {
            if tags.isEmpty {
                Label {
                    Text("Tags")
                        .schemeBasedForegroundStyle()
                } icon: {
                    Image(systemName: "number")
                        .foregroundStyle(.gray)
                }
            } else {
                TagLayout(alignment: .leading, spacing: 5) {
                    ForEach(tags.sorted(by: { $0.title < $1.title })) { tag in
                        Text("#\(tag.title)")
                            .foregroundStyle(Color.theme)
                            .bold()
                    }
                }
                .contentShape(Rectangle())
            }
        }
    }
}
