//
//  DashboardActivityByCategoryAnnotation.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardActivityByCategoryAnnotation: View {
    var category: CBCategory
    
    @State private var annotationHeight: CGFloat = 0
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    
                    Text(category.title.capitalized)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    ChartCircleDot(
                        budget: category.budgetAmount,
                        expenses: abs(category.allAmounts?.totalSpend ?? 0.0),
                        color: .white,
                        size: 20
                    )
                    
                    Image(systemName: category.emoji ?? "circle")
                }
                .font(.headline)
                
                Divider()
                
                if category.isIncome {
                    let amount = category.isRegularIncome
                    ? (category.allAmounts?.regularIncome ?? 0.0)
                    : (category.allAmounts?.irregularIncome ?? 0.0)
                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Income").bold()
                            Text(amount.currencyWithDecimals())
                        }
                    }
                    .font(.subheadline)
                } else {
                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Budget").bold()
                            Text(category.budgetAmount.currencyWithDecimals())
                        }
                        
                        GridRow {
                            Text("Income").bold()
                            Text((category.allAmounts?.irregularIncome ?? 0.0).currencyWithDecimals())
                        }
                        
                        GridRow {
                            Text("Expenses").bold()
                            Text((category.allAmounts?.totalSpend ?? 0.0).currencyWithDecimals())
                        }
                        
                        Divider()
                        
                        GridRow {
                            Text("Actual Spend").bold()
                            Text((category.allAmounts?.actualSpend ?? 0.0).currencyWithDecimals())
                        }
                    }
                    .font(.subheadline)
                }
                
                
            }
            .if(category.isNil) {
                $0.schemeBasedReversedForegroundStyle()
            }
            .if(!category.isNil) {
                $0.schemeBasedForegroundStyle()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(category.color.gradient)
            )
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { annotationHeight = geo.size.height }
                    .onChange(of: geo.size.height) { annotationHeight = $1 }
            }
        }
        .offset(y: -annotationHeight - 8)
        .zIndex(10)
    }
}