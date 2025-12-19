//
//  TevHashtags.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/18/25.
//

import SwiftUI

struct TevHashtags: View {
    var trans: CBTransaction
    @State private var showTagSheet = false
        
    var body: some View {
        Section {
            HStack {
                NavigationLink(value: TransNavDestination.tags) {
                    if trans.tags.isEmpty {
                        Label {
                            Text("Tags")
                                .schemeBasedForegroundStyle()
                        } icon: {
                            Image(systemName: "number")
                                .foregroundStyle(.gray)
                        }
                    } else {
                        TagLayout(alignment: .leading, spacing: 5) {
                            ForEach(trans.tags.sorted(by: { $0.tag < $1.tag })) { tag in
                                Text("#\(tag.tag)")
                                    .foregroundStyle(Color.theme)
                                    .bold()
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
//                Button {
//                    showTagSheet = true
//                } label: {
//                    if trans.tags.isEmpty {
//                        Label {
//                            Text("Tags")
//                                .schemeBasedForegroundStyle()
//                        } icon: {
//                            Image(systemName: "number")
//                                .foregroundStyle(.gray)
//                        }
//                    } else {
//                        TagLayout(alignment: .leading, spacing: 5) {
//                            ForEach(trans.tags.sorted(by: { $0.tag < $1.tag })) { tag in
//                                Text("#\(tag.tag)")
//                                    .foregroundStyle(Color.theme)
//                                    .bold()
//                            }
//                        }
//                        .contentShape(Rectangle())
//                    }
//                }
            }
        }
//        .sheet(isPresented: $showTagSheet) {
//            TagView(trans: trans)
//            #if os(macOS)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//            #endif
//        }
    }
}
