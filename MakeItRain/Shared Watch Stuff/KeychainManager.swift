//
//  KeychainManager.swift
//  Make It Rain Watch Watch App
//
//  Created by Cody Burnett on 6/28/26.
//

import Foundation

import Security

struct KeychainManager {
    enum KeychainError: Error {
        case duplicateItem
        case unexpectedDataFormat
        case itemNotFound
        case missingEmail
        case unknown(OSStatus)
    }
    
    // Must match the shared Keychain group in both targets.
    private let accessGroup = "N83B9B3ZN6.com.codyburnett.MakeItRain"
        
    
    func addToKeychain(key: String, value: String) throws {
        //print("-- \(#function)")
        
        let valueData = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: valueData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessGroup as String: accessGroup
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            //print("Item already exists")
            try updateKeychain(key: key, value: value)
            //throw KeychainError.duplicateItem
            
        } else if status != errSecSuccess {
            print("unknown error")
            throw KeychainError.unknown(status)
            
        } else {
            //print("User saved successfully in the keychain")
        }
    }
    
    
    func updateKeychain(key: String, value: String) throws {
        let valueData = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessGroup as String: accessGroup
        ]
        
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: valueData
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        if status == errSecItemNotFound {
            //print("item not found")
            throw KeychainError.itemNotFound
            
        } else if status != errSecSuccess {
            print("unknown error")
            throw KeychainError.unknown(status)
        }
    }
    
    
    
    
    func removeFromKeychain(key: String) throws {
        print("-- \(#function)")
            
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessGroup as String: accessGroup
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound {
            //print("item not found")
            throw KeychainError.itemNotFound
            
        } else if status != errSecSuccess {
            print("unknown error")
            throw KeychainError.unknown(status)
            
        } else {
            //print("successfully removed from keychain")
        }
    }
    
    func getFromKeychain(key: String) throws -> String? {
        //print("-- \(#function)")
                
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessGroup as String: accessGroup
        ]
        var item: CFTypeRef?
    
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            //print("\(#function) -- item not found \(status)")
            throw KeychainError.itemNotFound
            
            //https://www.oreilly.com/api/v2/epubs/9780133086898/files/graphics/18tab03.jpg

        } else if status != errSecSuccess {
            print("\(#function) -- unknown error \(status)")
            throw KeychainError.unknown(status)
        }
       
        if let existingItem = item as? [String: Any],
           let valueData = existingItem[kSecValueData as String] as? Data,
           let value = String(data: valueData, encoding: .utf8)
        {
            //print("Successfully got user credentials from Keychain")
            return value
        }
        
        return nil
    }
}
