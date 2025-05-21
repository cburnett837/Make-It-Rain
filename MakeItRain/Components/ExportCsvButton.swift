//
//  GenerateCsvButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/9/25.
//

import SwiftUI

struct ExportCsvButton: View {
    var fileName: String
    var headers: [String]
    var rows: [[String]]
    var body: some View {
        ShareLink(item: generateCsv()) {
            Label("Export CSV", systemImage: "tablecells")
        }
        .font(.subheadline)
    }
    
    func generateCsv() -> URL {
        return Helpers.generateCsv(fileName: fileName, headers: headers, rows: rows)
    }
}
