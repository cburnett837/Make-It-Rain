//
//  Extensions+Url.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation

extension URL: @retroactive Identifiable {
    public var id: String {
        return UUID().uuidString
    }
}

