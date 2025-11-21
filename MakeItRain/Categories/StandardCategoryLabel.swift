//
//  StandardCategoryLabel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/18/25.
//

import SwiftUI

struct StandardCategoryLabel: View {
    var cat: CBCategory
    var labelWidth: CGFloat
    var showCheckmarkCondition: Bool

    var body: some View {
        HStack {
            StandardCategorySymbol(cat: cat, labelWidth: labelWidth)
            
//            Image(systemName: lineItemIndicator == .dot ? "circle.fill" : (cat.emoji ?? "circle.fill"))
//                .foregroundStyle(cat.color.gradient)
//                .frame(minWidth: labelWidth, alignment: .center)
//                .maxViewWidthObserver()
            Text(cat.title)
                //.foregroundStyle(cat.isHidden ? .gray : .primary)
            
            if cat.isHidden {
                Image(systemName: "eye.slash")
                    //.foregroundStyle(.gray)
            }
            
            Spacer()
            Image(systemName: "checkmark")
                .opacity(showCheckmarkCondition ? 1 : 0)
        }
        .schemeBasedForegroundStyle()
        .contentShape(Rectangle())
    }
}


struct StandardCategorySymbol: View {
    @Local(\.categoryIndicatorAsSymbol) var categoryIndicatorAsSymbol
    
    var cat: CBCategory?
    var labelWidth: CGFloat

    var body: some View {
        if let cat = cat {
            Image(systemName: categoryIndicatorAsSymbol ? (cat.emoji ?? "circle.fill") : "circle.fill")
                .foregroundStyle(cat.color.gradient)
                .frame(minWidth: labelWidth, alignment: .center)
                .maxViewWidthObserver()
        } else {
            Image(systemName: "circle.fill")
                .schemeBasedForegroundStyle()
                .frame(minWidth: labelWidth, alignment: .center)
                .maxViewWidthObserver()
        }
    }
}


