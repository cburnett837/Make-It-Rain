//
//  SelectedDataContainer.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/3/25.
//


import SwiftUI
import Charts

struct ChartSelectedDataContainer<Headers: View, Rows: View, Summary: View>: View {
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false

    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    var columnCount: Int
    
    @ViewBuilder var headers: Headers
    @ViewBuilder var rows: Rows
    @ViewBuilder var summary: Summary
        
//    var gridColumnsCount: Int {
//        (payMethod.isCreditOrLoan || payMethod.isUnifiedCredit) ? 5 : 4
//    }
    
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 5, alignment: .topLeading), count: columnCount)
    }
                
    var body: some View {
        Grid(alignment: .leading) {
            GridRow(alignment: .top) {
                headers
            }
            .font(.caption)
            .bold()
            
            if (payMethod.isUnified && showOverviewDataPerMethodOnUnifiedChart) || !payMethod.isUnified {
                Divider()
                rows
            }
            
            if payMethod.isUnified {
                Divider()
                GridRow(alignment: .top) {
                    HStack(spacing: 5) {
                        CircleDotGradient(width: 5)
                        Text("All")
                            .foregroundStyle(.gray)
                    }
                    summary
                        .foregroundStyle(.gray)
                }
            }
        }
        .font(.caption2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}





struct ChartSelectedDataContainerOG<Headers: View, Rows: View, Summary: View>: View {
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    var selectedDate: Date
    var chartWidth: CGFloat
    var showOverviewDataPerMethodOnUnifiedChart: Bool
    
    @ViewBuilder var headers: Headers
    @ViewBuilder var rows: Rows
    @ViewBuilder var summary: Summary
            
    var body: some View {
        VStack(spacing: 0) {
            Text(vm.overViewTitle(for: selectedDate))
                .bold()
            
            Divider()
            
            Grid(alignment: .leading) {
                GridRow(alignment: .top) {
                    headers
                }
                .foregroundStyle(.secondary)
                .bold()
                
                Divider()
                
                if showOverviewDataPerMethodOnUnifiedChart {
                    rows
                    Divider()
                }
                
                GridRow(alignment: .top) {
                    if showOverviewDataPerMethodOnUnifiedChart {
                        HStack(spacing: 0) {
                            CircleDotGradient()
                            Text("All")
                        }
                    }
                    
                    summary
                }
            }
            .minimumScaleFactor(0.5)
            .foregroundStyle(.secondary)
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: chartWidth, maxHeight: .infinity)
        .foregroundStyle(.primary)
        .padding(6)
        #if os(iOS)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemBackground))
                //.shadow(radius: 5)
        )
        #else
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.windowBackgroundColor))
                //.shadow(radius: 5)
        )
        #endif
        
    }
}
