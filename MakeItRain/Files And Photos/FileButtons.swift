//
//  FileButtons.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/19/26.
//


import SwiftUI
import WebKit

#if os(macOS)
struct FileButtons: View {
    @Environment(FileViewProps.self) var props
    var file: CBFile

    var body: some View {
        @Bindable var props = props

        VStack {
            HStack {
//                    Link(destination: URL(string: "http://\(Keys.baseURL):8677/budget_app.photo.\(file.uuid).jpg")!) {
//                        Image(systemName: "arrow.down.left.and.arrow.up.right")
//                            .frame(width: 30, height: 30)
//                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
//                    }

                ShareLink(item: URL(string: "https://\(Keys.prodBaseFileURL)/files/budget_app.photo.\(file.uuid).jpg")! /*, subject: Text(trans.title), message: Text(trans.amountString)*/) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Color.accentColor)
                        .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
                }
                .buttonStyle(.plain)

                Button {
                    props.deleteFile = file
                    props.showDeleteFileAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .frame(width: 30, height: 30)
                        .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
                }
                .buttonStyle(.plain)

                //Spacer()
            }
            .padding(.leading, 4)
            Spacer()
        }
        .padding(.top, 4)

        .opacity(props.isDeletingFile && file.id == props.deleteFile?.id ? 0 : 1)
        .disabled(props.isDeletingFile && file.id != props.deleteFile?.id)
    }
}
#endif
