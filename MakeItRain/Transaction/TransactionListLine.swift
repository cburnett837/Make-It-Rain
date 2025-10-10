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
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(trans.title)
                
                Spacer()
                
                Group {
                    if trans.payMethod?.accountType == .credit || trans.payMethod?.accountType == .loan {
                        Text((trans.amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    } else {
                        Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    }
                }
            }
                            
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundStyle(trans.category?.color ?? .primary)
                    
                    Text(trans.category?.title ?? "N/A")
                        .foregroundStyle(.gray)
                        .font(.caption)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundStyle(trans.payMethod?.color ?? .primary)
                    
                    Text(trans.payMethod?.title ?? "")
                        .foregroundStyle(.gray)
                        .font(.caption)
                }
            }
            
            if withDate {
                HStack(spacing: 4) {
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundStyle(.primary)
                                        
                    Text(trans.prettyDate ?? "N/A")
                        .foregroundStyle(.gray)
                        .font(.caption)
                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
    }
}
