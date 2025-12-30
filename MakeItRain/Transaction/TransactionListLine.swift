//
//  TransactionListLine.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/7/25.
//

import SwiftUI

struct TransactionListLine: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @Bindable var trans: CBTransaction
    var withDate: Bool = false
    var withTags: Bool = false
    
    var body: some View {
        HStack(alignment: .circleAndTitle) {
            BusinessLogo(config: .init(
                parent: trans.payMethod,
                fallBackType: .color
            ))
            
            //BusinessLogo(parent: trans.payMethod, fallBackType: .color)
            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack(spacing: 2) {
                VStack(spacing: 2) {
                    HStack {
                        Text(trans.title)
                            .lineLimit(1)
                        Spacer()
                        amount
                    }
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
                    
                    HStack {
                        category
                        Spacer()
                        if withDate {
                            date
                        }
                    }
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
                }
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                if withTags && !trans.tags.isEmpty {
                    tags
                }
            }
            .contentShape(Rectangle())
        }
    }
    
    @ViewBuilder
    var amount: some View {
        if trans.payMethod?.accountType == .credit || trans.payMethod?.accountType == .loan {
            Text((trans.amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
        } else {
            Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
        }
    }
    
    var category: some View {
        HStack(spacing: 4) {
            Circle()
                .frame(width: 6, height: 6)
                .foregroundStyle(trans.category?.color ?? .primary)
            
            Text(trans.category?.title ?? "N/A")
                .foregroundStyle(.gray)
                .font(.caption)
        }
    }
    
    
    var date: some View {
        Text(trans.prettyDate ?? "N/A")
            .foregroundStyle(.gray)
            .font(.caption)
    }
    
    var tags: some View {
        TagLayout(alignment: .leading, spacing: 5) {
            ForEach(trans.tags.sorted(by: { $0.tag < $1.tag })) { tag in
                Text("#\(tag.tag)")
                    .foregroundStyle(.gray)
                    .font(.caption)
                    .padding(4)
                    .background(Color(.systemGray4))
                    .cornerRadius(6)
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
            }
        }
    }
}
