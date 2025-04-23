//
//  ResultCompleteModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/1/25.
//


import Foundation

class ResultCompleteModel: Codable {
    let result: String?
    
    enum CodingKeys: CodingKey { case result }
    
    init(){
        self.result = nil
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        result = try container.decode(String.self, forKey: .result)
    }
}
