//
//  KeychainManager.swift
//  WittwerTV
//
//  Created by Cody Burnett on 5/24/23.
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
        
    
    func addToKeychain(key: String, value: String) throws {
        print("-- \(#function)")
        
        let valueData = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: valueData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecUseDataProtectionKeychain as String: true
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            print("Item already exists")
            try updateKeychain(key: key, value: value)
            //throw KeychainError.duplicateItem
            
        } else if status != errSecSuccess {
            print("unknown error")
            throw KeychainError.unknown(status)
            
        } else {
            print("User saved successfully in the keychain")
        }
        
//        
//        let attributes: [String: Any] = [
//            kSecClass as String: kSecClassGenericPassword,
//            kSecAttrAccount as String: email,
//            kSecValueData as String: password,
//        ]
//        // Add user
//        if SecItemAdd(attributes as CFDictionary, nil) == noErr {
//            print("User saved successfully in the keychain")
//        } else {
//            print("Something went wrong trying to save the user in the keychain")
//        }
        
        
    }
    
    
    func updateKeychain(key: String, value: String) throws {
        print("-- \(#function)")
        
        let valueData = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true
        ]
        
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: valueData
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        if status == errSecItemNotFound {
            print("item not found")
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
            kSecUseDataProtectionKeychain as String: true
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound {
            print("item not found")
            throw KeychainError.itemNotFound
            
        } else if status != errSecSuccess {
            print("unknown error")
            throw KeychainError.unknown(status)
            
        } else {
            print("successfully removed from keychain")
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
            kSecUseDataProtectionKeychain as String: true
        ]
        var item: CFTypeRef?
    
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            print("\(#function) -- item not found")
            throw KeychainError.itemNotFound
            
        } else if status != errSecSuccess {
            print("\(#function) -- unknown error")
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

    
    
    func getCredentialsFromKeychain() throws -> (String?, String?) {
        print("-- \(#function)")
        
        if let email = AppState.shared.user?.email {
            let query: [String: Any] = [
                kSecClass as String: kSecClassInternetPassword,
                kSecAttrAccount as String: email,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecReturnAttributes as String: true,
                kSecReturnData as String: true,
                kSecUseDataProtectionKeychain as String: true
            ]
            var item: CFTypeRef?
        
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            if status == errSecItemNotFound {
                print("item not found")
                throw KeychainError.itemNotFound
                
            } else if status != errSecSuccess {
                print("unknown error")
                throw KeychainError.unknown(status)
            }
           
            if let existingItem = item as? [String: Any],
               let email = existingItem[kSecAttrAccount as String] as? String,
               let passwordData = existingItem[kSecValueData as String] as? Data,
               let password = String(data: passwordData, encoding: .utf8)
            {
                print("Successfully got user credentials from Keychain")
                return (email, password)
            }
            
            return (nil, nil)
            
        } else {
            throw KeychainError.missingEmail
        }
    }
}
