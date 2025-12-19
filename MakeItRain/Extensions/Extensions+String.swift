//
//  Extensions+String.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation

extension String: @retroactive Identifiable {
    public var id: String {
        return self
    }
    
    //    func toColor() -> Color {
    //        var color: Color = .white
    //        switch self {
    //        case "red":
    //            color = .red
    //        case "orange":
    //            color = .orange
    //        case "yellow":
    //            color = .yellow
    //        case "green":
    //            color = .green
    //        case "blue":
    //            color = .blue
    //        case "purple":
    //            color = .purple
    //        case "pink":
    //            color = .pink
    //        case "brown":
    //            color = .brown
    //        case "black":
    //            color = .black
    //        case "white":
    //            color = .white
    //        default:
    //            color = .white
    //        }
    //
    //        return color
    //    }
    //
        
    //    func toColor() -> Color {
    //        let hex = self.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    //        var int: UInt64 = 0
    //        Scanner(string: hex).scanHexInt64(&int)
    //        let a, r, g, b: UInt64
    //        switch hex.count {
    //        case 3: // RGB (12-bit)
    //            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    //        case 6: // RGB (24-bit)
    //            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    //        case 8: // ARGB (32-bit)
    //            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    //        default:
    //            (a, r, g, b) = (1, 1, 1, 0)
    //        }
    //        return Color(
    //            .sRGB,
    //            red: Double(r) / 255,
    //            green: Double(g) / 255,
    //            blue:  Double(b) / 255,
    //            opacity: Double(a) / 255
    //        )
    //    }
        
    //    func toColorOG() -> Color {
    //        var cString = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    //
    //        if (cString.hasPrefix("#")) {
    //            cString.remove(at: cString.startIndex)
    //        }
    //
    //        if ((cString.count) != 6) {
    //            return Color.gray
    //        }
    //
    //        var rgbValue: UInt64 = 0
    //        Scanner(string: cString).scanHexInt64(&rgbValue)
    //
    //        return Color (
    //            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
    //            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
    //            blue: CGFloat(rgbValue & 0x0000FF) / 255.0
    //        )
    //    }
}


extension String?: @retroactive Comparable {
    public static func < (lhs: Optional, rhs: Optional) -> Bool {
        return lhs ?? "" < rhs ?? ""
    }
    
    public static func > (lhs: Optional, rhs: Optional) -> Bool {
        return lhs ?? "" > rhs ?? ""
    }
    
    public static func <= (lhs: Optional, rhs: Optional) -> Bool {
        return lhs ?? "" <= rhs ?? ""
    }
    
    public static func >= (lhs: Optional, rhs: Optional) -> Bool {
        return lhs ?? "" >= rhs ?? ""
    }
}
