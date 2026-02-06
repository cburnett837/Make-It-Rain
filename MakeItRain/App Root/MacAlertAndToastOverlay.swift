//
//  MacAlertAndToastOverlay.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/5/26.
//


import SwiftUI

struct MacAlertAndToastOverlay: View {
    static let id = "MacAlertAndToastOverlay"
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(FuncModel.self) var funcModel
    @Environment(DataChangeTriggers.self) var dataChangeTriggers
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    @Environment(PlaidModel.self) private var plaidModel
    
    @State private var isInitial = true

    var body: some View {
        Text("")
            .onAppear {
                /// If isInitial is true, we are opening the window only so that the next time we actually need to use it, we can configure it before opening.
                if isInitial {
                    isInitial = false
                    dismissWindow(id: MacAlertAndToastOverlay.id)
                    return
                }
            }
        AlertAndToastLayerView(showCamera: .constant(false))
            .environment(funcModel)
            .environment(calModel)
            .environment(payModel)
            .environment(catModel)
            .environment(keyModel)
            .environment(repModel)
            .environment(plaidModel)
            .environment(calProps)
            .environment(dataChangeTriggers)
            //.frame(width: NSScreen.main?.frame.size.width, height: NSScreen.main?.frame.size.height)
    }
}
