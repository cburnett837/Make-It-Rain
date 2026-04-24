//
//  Extensions+Sequence.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/17/26.
//

extension Sequence {
    func asyncMap<T>(_ transform: (Element) async -> T) async -> [T] {
        var results: [T] = []
        results.reserveCapacity(underestimatedCount)
        for element in self {
            results.append(await transform(element))
        }
        return results
    }
    
    func asyncFlatMap<T>(_ transform: (Element) async -> [T]) async -> [T] {
        var results: [T] = []
        for element in self {
            let inner = await transform(element)
            results.append(contentsOf: inner)
        }
        return results
    }
    
    func asyncForEach(_ transform: (Element) async throws -> Void) async rethrows {
        for element in self {
            try await transform(element)
        }
    }
}
