//
//  MyLogger.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/10/24.
//

import Foundation
import os


struct LogManager {
    private static let logger = Logger(
        subsystem: "MakeItRainLogger",
        category: "LogManager"
        /// To Read: Plug iPhone into Mac, open console app, and start streaming.
        /// Set search type to "subsystem" and search for the key in the subsystem above (MakeItRainLogger)
    )
    
    
    static func log(_ text: String? = nil, _ file: String? = #fileID, _ line: Int? = #line, _ function: String? = #function, session: String? = nil) {
        return
        var sesh = ""
        if let session { sesh = "\(session)\n" } else { sesh = "" }
        
        print(
            """
            \(sesh)\(file?.replacing("MakeItRain/", with: "") ?? "NoFile") --- \(line ?? 0) --- \(function ?? "NoFunction")
            🟢\(text ?? "NoMessage")            
            """
        )
        
        if let text {
            Self.logger.log(
                level: .default,
                """
                \(sesh, privacy: .public)\(file?.replacing("MakeItRain/", with: "") ?? "NoFile", privacy: .public) --- \(line ?? 0, privacy: .public) --- \(function ?? "NoFunction", privacy: .public)
                🟢\(text, privacy: .public)
                """
            )
        } else {
            Self.logger.log(
                level: .default,
                """
                \(sesh, privacy: .public)\(file?.replacing("MakeItRain/", with: "") ?? "NoFile", privacy: .public) --- \(line ?? 0, privacy: .public) --- \(function ?? "NoFunction", privacy: .public)
                """
            )
        }
    }
    
    
    static func error(_ text: String? = nil, _ file: String? = #fileID, _ line: Int? = #line, _ function: String? = #function, session: String? = nil) {
        var sesh = ""
        if let session { sesh = "\(session)\n" } else { sesh = "" }
        
        print(
            """
            \(sesh)\(file?.replacing("MakeItRain/", with: "") ?? "NoFile") --- \(line ?? 0) --- \(function ?? "NoFunction")
            🔴\(text ?? "NoMessage")
            
            """
        )
        
        return
        
        if let text {
            Self.logger.log(
                level: .error,
                """
                \(sesh, privacy: .public)\(file?.replacing("MakeItRain/", with: "") ?? "NoFile", privacy: .public) --- \(line ?? 0, privacy: .public) --- \(function ?? "NoFunction", privacy: .public)
                🔴\(text, privacy: .public)                   
                """
            )
        } else {
            Self.logger.log(
                level: .error,
                """
                \(sesh, privacy: .public)\(file?.replacing("MakeItRain/", with: "") ?? "NoFile", privacy: .public) --- \(line ?? 0, privacy: .public) --- \(function ?? "NoFunction", privacy: .public)
                """
            )
        }
    }
    
    
    
    static func networkingSuccessful(_ file: String? = #fileID, _ line: Int? = #line, _ function: String? = #function, session: String? = nil) {
        return
        var sesh = ""
        if let session { sesh = "\(session)\n" } else { sesh = "" }
        
        print(
            """
            \(sesh)\(file?.replacing("MakeItRain/", with: "") ?? "NoFile") --- \(line ?? 0) --- \(function ?? "NoFunction")
            🟢networking successful
            
            """
        )
        
        Self.logger.log(
            level: .default,
            """
            \(sesh, privacy: .public)\(file?.replacing("MakeItRain/", with: "") ?? "NoFile", privacy: .public) --- \(line ?? 0, privacy: .public) --- \(function ?? "NoFunction", privacy: .public)
            🟢networking successful
            """
        )
    }
}
