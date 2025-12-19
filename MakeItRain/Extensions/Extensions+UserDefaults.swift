//
//  Extensions+UserDefaults.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//


import Foundation
import SwiftUI

extension UserDefaults {
    static func updateStringValue(valueToUpdate: String, keyToUpdate: String) {
        UserDefaults.standard.setValue(valueToUpdate, forKey: keyToUpdate)
    }
    
    static func fetchOneString(requestedKey: String) -> String? {
        return UserDefaults.standard.string(forKey: requestedKey) ?? nil
    }
    
    static func fetchManyString(requestedKey: String) -> [String] {
        return UserDefaults.standard.stringArray(forKey: requestedKey) ?? []
    }
    
    static func fetchOneBool(requestedKey: String) -> Bool {
        return UserDefaults.standard.bool(forKey: requestedKey)
    }
    
    static func fetchManyDicts(requestedKey: String) -> Dictionary<String, Any> {
        return UserDefaults.standard.dictionary(forKey: requestedKey) ?? ["" : ""]
    }
}
