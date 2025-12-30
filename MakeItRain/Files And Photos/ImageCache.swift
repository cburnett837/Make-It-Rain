//
//  ImageCache.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/18/25.
//

import Foundation
import UIKit

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        /// Maximum 100 images
        cache.countLimit = 100
        /// 50MB total limit
        cache.totalCostLimit = 50 * 1024 * 1024
    }
        
    func saveToCache(parentTypeId: Int?, parentId: String?, id: String?, data: Data) async {
        if let parentTypeId = parentTypeId,
        let parentId = parentId,
        let uiImage = UIImage(data: data) {
            let key = "\(parentTypeId)_\(parentId)_\(id ?? "")"
            //print("Saving image to cache for key: \(key)")
            ImageCache.shared.cache.setObject(uiImage, forKey: NSString(string: key))
        }
    }
    
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
}
