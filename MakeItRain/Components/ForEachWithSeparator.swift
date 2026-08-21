//
//  ForEachWithSeparator.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct ForEachWithSeparator<Data: RandomAccessCollection, Content: View, Separator: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content
    let separator: () -> Separator
    let includeLastSeparator: Bool
    
    init(
        _ data: Data,
        includeLastSeparator: Bool = false,
        @ViewBuilder content: @escaping (Data.Element) -> Content,
        @ViewBuilder separator: @escaping () -> Separator = { Divider() }
    ) {
        
        self.data = data
        self.content = content
        self.separator = separator
        self.includeLastSeparator = includeLastSeparator
    }
    
    var body: some View {
        let array = Array(data)
        
        ForEach(array.indices, id: \.self) { index in
            content(array[index])
            
            if (index != array.count - 1 || includeLastSeparator) {
                separator()
            }
        }
    }
}
