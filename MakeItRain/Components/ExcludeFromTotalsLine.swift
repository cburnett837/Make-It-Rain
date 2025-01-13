//
//  ExcludeFromTotalsLine.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/28/24.
//

import SwiftUI

struct ExcludeFromTotalsLine: View {
    @Bindable var trans: CBTransaction
    var body: some View {
        Rectangle()
            .fill(.red)
            .frame(height: 2)
            .edgesIgnoringSafeArea(.horizontal)
            .opacity(trans.factorInCalculations ? 0 : 1)
    }
}
