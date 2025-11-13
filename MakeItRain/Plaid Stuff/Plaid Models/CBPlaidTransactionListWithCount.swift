//
//  CBPlaidTransactionListWithCount.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/25.
//

import SwiftUI

class CBPlaidTransactionListWithCount: Decodable {
    var count: Int
    var trans: Array<CBPlaidTransaction>?
}

