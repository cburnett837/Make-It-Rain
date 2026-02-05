//
//  ImageCache.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/18/25.
//

import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

class ImageCache {
    static let shared = ImageCache()
    #if os(iOS)
    private let cache = NSCache<NSString, UIImage>()
    #else
    private let cache = NSCache<NSString, NSImage>()
    #endif
    
    private init() {
        /// Maximum 100 images
        cache.countLimit = 100
        /// 50MB total limit
        cache.totalCostLimit = 50 * 1024 * 1024
    }
        
    func saveToCache(parentTypeId: Int?, parentId: String?, id: String?, data: Data) async {
        #if os(iOS)
        if let parentTypeId = parentTypeId,
        let parentId = parentId,
        let uiImage = UIImage(data: data) {
            let key = "\(parentTypeId)_\(parentId)_\(id ?? "")"
            //print("Saving image to cache for key: \(key)")
            ImageCache.shared.cache.setObject(uiImage, forKey: NSString(string: key))
        }
        #else
        if let parentTypeId = parentTypeId,
        let parentId = parentId,
        let nsImage = NSImage(data: data) {
            let key = "\(parentTypeId)_\(parentId)_\(id ?? "")"
            //print("Saving image to cache for key: \(key)")
            ImageCache.shared.cache.setObject(nsImage, forKey: NSString(string: key))
        }
        #endif
    }
    
    #if os(iOS)
    func loadFromCache(parentTypeId: Int?, parentId: String?, id: String?) -> UIImage? {
        if let parentTypeId = parentTypeId, let parentId = parentId {
            let key = "\(parentTypeId)_\(parentId)_\(id ?? "")"
            if let cachedImage = ImageCache.shared.cache.object(forKey: NSString(string: key)) {
                //print("Found image in cache for key: \(key)")
                return cachedImage
            }
        }
        return nil
    }
    #else
    func loadFromCache(parentTypeId: Int?, parentId: String?, id: String?) -> NSImage? {
        if let parentTypeId = parentTypeId, let parentId = parentId {
            let key = "\(parentTypeId)_\(parentId)_\(id ?? "")"
            if let cachedImage = ImageCache.shared.cache.object(forKey: NSString(string: key)) {
                //print("Found image in cache for key: \(key)")
                return cachedImage
            }
        }
        return nil
    }
    #endif
}
