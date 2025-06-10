//
//  CacheManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/10/25.
//

import Foundation

enum CacheFile: String {
    case keywords = "keywords.json"
    case payMethods = "payMethods.json"
    case categories = "categories.json"
}

struct CacheManager<T: Codable> {
    let file: CacheFile

    func loadOne(_ value: T) -> T? {
        do {
            let data = try Data(contentsOf: url)
            return try! JSONDecoder().decode(T.self, from: data)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func loadMany() -> Array<T>? {
        do {
            let data = try Data(contentsOf: url)
            return try! JSONDecoder().decode(Array<T>.self, from: data)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    func saveOne(_ value: T) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: [.atomic])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func saveMany(_ value: Array<T>) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: [.atomic])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func delete() {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print(error.localizedDescription)
        }
        
    }

    private var url: URL {
        //URL.documentsDirectory.appending(path: filename)
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(file.rawValue)
    }
}
