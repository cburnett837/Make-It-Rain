////
////  BudgetBreakdownView.swift
////  MakeItRain
////
////  Created by Cody Burnett on 5/8/25.
////
//
//import SwiftUI
//
//struct BudgetBreakdownView: View {
//    
//    @Environment(CalendarModel.self) private var calModel
//    
//    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 5)
//    
//    var chartData: Array<ChartData>
//    var groupData: Array<GroupChartData>
//    var calculateDataFunction: () async -> Void
//    
//    @State private var rowWidth: CGFloat = 0
//    
//    var body: some View {
//        gridHeader
//        
//        ForEach(groupData) { group in
//            HStack {
//                HStack {
//                    GradientCircleDot(size: 12, colors: group.group.categories.map(\.color))
//                    Button(group.group.title) {
//                        group.isExpanded.toggle()
//                    }
//                    //.buttonStyle(.borderedProminent)
//                }
//                .frame(width: rowWidth / 3, alignment: .leading)
//                
//                Text(group.budget.currencyWithDecimals())
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    
//                Text(group.expenses.currencyWithDecimals())
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                                            
//                Text(group.income.currencyWithDecimals())
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                                            
//                Text(group.variance.currencyWithDecimals())
//                    .foregroundStyle(group.variance < 0 ? .red : .green)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//
//            if group.isExpanded {
//                ForEach(group.data) { data in
//                    line(for: data, inset: true)
//                }
//            }
//        }
//        
//        ForEach(chartData.filter { $0.categoryGroup == nil }, id: \.id) { catData in
//            Text("hey")
//            //line(for: catData, inset: false)
//        }
//    }
//    
//    
//    var gridHeader: some View {
//        HStack {
//            HStack {
//                ChartCircleDot(budget: 0, expenses: 0, color: .primary, size: 12)
//                Text("Category")
//            }
//            .frame(width: rowWidth / 3, alignment: .leading)
//            
//            Text("Budget")
//                .frame(maxWidth: .infinity, alignment: .leading)
//            Text("Expense")
//                .frame(maxWidth: .infinity, alignment: .leading)
//            Text("Income")
//                .frame(maxWidth: .infinity, alignment: .leading)
//            Text("Variance")
//                .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .font(.caption)
//        .lineLimit(1)
//        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { self.rowWidth = $0 }
//    }
//    
////    
////    var content: some View {
////        Grid(alignment: .leading) {
////            GridRow {
////                HStack {
////                    ChartCircleDot(budget: 0, expenses: 0, color: .primary, size: 12)
////                    Text("Category")
////                }
////                
////                Text("Budget")
////                Text("Expense")
////                Text("Income")
////                Text("Variance")
////            }
////            .font(.caption)
////            
////            Divider()
////                .gridCellUnsizedAxes(.horizontal)
////            
////            ForEach(groupData) { group in
////                GridRow {
////                    Group {
////                        HStack {
////                            GradientCircleDot(size: 12, colors: group.group.categories.map(\.color))
////                            
////                            Button(group.group.title) {
////                                group.isExpanded.toggle()
////                            }
////                            .buttonStyle(.borderedProminent)
////                        }
////                        
////                        Text(group.budget.currencyWithDecimals())
////                            
////                        Text(group.expenses.currencyWithDecimals())
////                                                    
////                        Text(group.income.currencyWithDecimals())
////                                                    
////                        Text(group.variance.currencyWithDecimals())
////                            .foregroundStyle(group.variance < 0 ? .red : .green)
////                    }
////                    .font(.caption)
////                }
////
////                if group.isExpanded {
////                    ForEach(group.data) { data in
////                        GridRow {
////                            line(for: data, inset: true)
////                        }
////                        
////                        Divider()
////                            .gridCellUnsizedAxes(.horizontal)
////                    }
////                    .font(.caption)
////                } else {
////                    Divider()
////                        .gridCellUnsizedAxes(.horizontal)
////                }
////            }
////            
////            
////            ForEach(theCategoryData, id: \.id) { catData in
////                GridRow {
////                    ForEach(catData.data) { data in
////                        line(for: data, inset: false)
////                    }
////                }
////                .font(.caption)
////                
////                Divider()
////                    .gridCellUnsizedAxes(.horizontal)
////            }
////        }
////    }
////    
////    
////    @ViewBuilder
////    var content2: some View {
////        HStack {
////            HStack {
////                ChartCircleDot(budget: 0, expenses: 0, color: .primary, size: 12)
////                Text("Category")
////            }
////            .frame(width: rowWidth / 3, alignment: .leading)
////            
////            Text("Budget")
////                .frame(maxWidth: .infinity, alignment: .leading)
////            Text("Expense")
////                .frame(maxWidth: .infinity, alignment: .leading)
////            Text("Income")
////                .frame(maxWidth: .infinity, alignment: .leading)
////            Text("Variance")
////                .frame(maxWidth: .infinity, alignment: .leading)
////        }
////        .font(.caption)
////        
////        
////        
////        ForEach(groupData) { group in
////            HStack {
////                HStack {
////                    GradientCircleDot(size: 12, colors: group.group.categories.map(\.color))
////                    Button(group.group.title) {
////                        group.isExpanded.toggle()
////                    }
////                    //.buttonStyle(.borderedProminent)
////                }
////                .frame(width: rowWidth / 3, alignment: .leading)
////                
////                Text(group.budget.currencyWithDecimals())
////                    .frame(maxWidth: .infinity, alignment: .leading)
////                    
////                Text(group.expenses.currencyWithDecimals())
////                    .frame(maxWidth: .infinity, alignment: .leading)
////                                            
////                Text(group.income.currencyWithDecimals())
////                    .frame(maxWidth: .infinity, alignment: .leading)
////                                            
////                Text(group.variance.currencyWithDecimals())
////                    .foregroundStyle(group.variance < 0 ? .red : .green)
////                    .frame(maxWidth: .infinity, alignment: .leading)
////            }
////            .font(.caption)
////
////            if group.isExpanded {
////                ForEach(group.data) { data in
////                    line(for: data, inset: true)
////                }
////                .font(.caption)
////            }
////        }
////        
////        
////        ForEach(theCategoryData, id: \.id) { catData in
////            ForEach(catData.data) { data in
////                line(for: data, inset: false)
////            }
////            .font(.caption)
////        }
////    }
////    
//    
//    @ViewBuilder
//    func line(for metric: ChartData, inset: Bool) -> some View {
//        HStack {
//            HStack {
//                ChartCircleDot(
//                    budget: metric.budgetForCategory,
//                    expenses: metric.expenses,
//                    color: metric.category.color,
//                    size: 12
//                )
//                //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                
//                Text(metric.category.title)
//                    //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//            }
//            //.frame(maxWidth: .infinity, alignment: .leading)
//            .frame(width: rowWidth / 3, alignment: .leading)
//            .padding(.leading, inset ? 10 : 0)
//            
//            Text(metric.budgetForCategory.currencyWithDecimals())
//                .padding(.leading, inset ? 10 : 0)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                
//            Text((metric.expenses == 0 ? 0 : metric.expenses * -1 - metric.income).currencyWithDecimals())
//                .padding(.leading, inset ? 10 : 0)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                                        
//            Text(metric.income.currencyWithDecimals())
//                .padding(.leading, inset ? 10 : 0)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                                        
//            let overUnder = (metric.budgetForCategory) + (metric.expenses + metric.income)
//            Text(abs(overUnder).currencyWithDecimals())
//                .foregroundStyle(overUnder < 0 ? .red : .green)
//                .padding(.leading, inset ? 10 : 0)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                //.frame(maxWidth: .infinity, alignment: .leading)
//        }
//        //.padding(.vertical, 4)
//        //.contentShape(Rectangle())
//    }
//}
