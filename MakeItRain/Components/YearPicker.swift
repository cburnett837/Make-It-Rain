//
//  YearPicker.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI

struct YearPicker: View {
    @Environment(CalendarModel.self) private var calModel
    
    var years: [Int] { Array(2019...2099).map { $0 } }
    
    var body: some View {
        @Bindable var calModel = calModel
        Picker("", selection: $calModel.sYear) {
            ForEach(years, id: \.self) {
                Text(String($0))
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
    }
}


