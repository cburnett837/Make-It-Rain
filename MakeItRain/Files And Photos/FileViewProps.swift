//
//  FileViewProps.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/26/25.
//


import SwiftUI
import WebKit
import PDFKit

@Observable
class FileViewProps {
    var hoverFile: CBFile?
    var deleteFile: CBFile?
    var isDeletingFile = false
    var showDeleteFileAlert = false
}
