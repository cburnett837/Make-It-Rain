//
//  CodablePlaceHolder.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/1/25.
//


import Foundation

class CodablePlaceHolder: Codable {
    let thing: String?
    var deviceName: String = UserDefaults.standard.string(forKey: "deviceName") ?? "device name undetermined"
    
    init() {
        self.thing = nil
    }
}
