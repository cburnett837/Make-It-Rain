//
//  MyLogger.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/10/24.
//

import Foundation
import os


enum LogManager {
    private static let logger = Logger(
        subsystem: "MakeItRainLogger",
        category: "LogManager"
        /// To Read: Plug iPhone into Mac, open console app, and start streaming.
        /// Set search type to "subsystem" and search for the key in the subsystem above (MakeItRainLogger)
    )
    
    static private func baseMessage(file: String, line: Int, function: String, session: String?) -> String {
        let sesh = session.map { "\($0)" } ?? ""
        let fileName = file.replacing("MakeItRain/", with: "").replacing(".swift", with: "")
        let funcName = function.replacingOccurrences(of: #"\(.*?\)"#, with: "", options: .regularExpression)
            
        //return "🪵\(sesh.isEmpty ? "" : " Sesh \(sesh) ---") File: \(fileName) --- Line: \(line) --- Function: \(funcName)"
        
        return "🪵\(sesh.isEmpty ? "" : " Sesh \(sesh) ---") \(fileName).\(funcName).\(line)"
    }
    
    
    static func log(
        _ text: String? = nil,
        _ file: String = #fileID,
        _ line: Int = #line,
        _ function: String = #function,
        session: String? = nil
    ) {
        let message = baseMessage(file: file, line: line, function: function, session: session)
        
        if let text {
            print(message, "🟢", text)
            Self.logger.log(level: .default, "\(message, privacy: .public)\n🟢\(text, privacy: .public)")
        } else {
            print(message)
            Self.logger.log(level: .default, "\(message, privacy: .public)")
        }
    }
    
    
    static func error(
        _ text: String? = nil,
        _ file: String = #fileID,
        _ line: Int = #line,
        _ function: String = #function,
        session: String? = nil
    ) {
        let message = baseMessage(file: file, line: line, function: function, session: session)
        
        if let text {
            print(message, "🔴", text)
            Self.logger.error("\(message, privacy: .public)\n🔴\(text, privacy: .public)")
        } else {
            print(message)
            Self.logger.error("\(message, privacy: .public)")
        }
    }
    
    
    static func networkingSuccessful(
        _ file: String = #fileID,
        _ line: Int = #line,
        _ function: String = #function,
        session: String? = nil
    ) {
        let message = baseMessage(file: file, line: line, function: function, session: session)
        Self.logger.log(level: .default, "\(message, privacy: .public)\n🟢\("networking successful", privacy: .public)")
    }
}
