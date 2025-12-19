//
//  ColorModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//


import Foundation
import SwiftUI
import Charts

extension Color {
    func toHex() -> String? {
        #if os(macOS)
        let uic = NSColor(self)
        #else
        let uic = UIColor(self)
        #endif
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = Float(1.0)
        
        if components.count >= 4 {
            //a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
    
    //    init(hex: String) {
    //        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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
    //
    //        self.init(
    //            .sRGB,
    //            red: Double(r) / 255,
    //            green: Double(g) / 255,
    //            blue:  Double(b) / 255,
    //            opacity: Double(a) / 255
    //        )
    //    }
    
    //    static func fromHex(_ hex: String?) -> Color? {
    //        if let hex = hex {
    //            let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    //            var int: UInt64 = 0
    //            Scanner(string: hex).scanHexInt64(&int)
    //
    //            let r, g, b, a: UInt64
    //
    //            switch hex.count {
    //            case 3:  (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
    //            case 6:  (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
    //            case 8:  (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, int >> 24)
    //            default: (r, g, b, a) = (1, 1, 1, 1)
    //            }
    //
    //            return self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    //        } else {
    //            return nil
    //        }
    //    }
    
    static func fromHex(_ hex: String?) -> Color? {
        if let hex = hex {
            let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var rgbValue: UInt64 = 0
            
            Scanner(string: hex).scanHexInt64(&rgbValue)
            
            let a, r, g, b: UInt64
            
            switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (rgbValue >> 8) * 17, (rgbValue >> 4 & 0xF) * 17, (rgbValue & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, rgbValue >> 16, rgbValue >> 8 & 0xFF, rgbValue & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (rgbValue >> 24, rgbValue >> 16 & 0xFF, rgbValue >> 8 & 0xFF, rgbValue & 0xFF)
            default:
                (a, r, g, b) = (1, 1, 1, 0)
            }
            
            return self.init(
                .sRGB,
                red: Double(r) / 255,
                green: Double(g) / 255,
                blue:  Double(b) / 255,
                opacity: Double(a) / 255
            )
            
        } else {
            return nil
        }
    }
    
    static func fromName(_ name: String) -> Color {
        //print(name)
        if name == "primary" {
            return Color.primary
        } else {
            return AppState.shared.colorMenuOptions.first(where: { $0.description == name })!
        }
    }
    
    static var theme: Color {
        @Local(\.colorTheme) var colorTheme
        return AppState.shared.colorMenuOptions.first(where: { $0.description == colorTheme })!
    }
    
    
    
    
    
    
//    static func getVariantTitleColor(for scheme: ColorScheme, color: Color) -> Color {
//        struct ColorModel: Identifiable {
//            var id = UUID()
//            var color: Color
//            var colorHex: String {
//                self.color.toHex() ?? "FFFFFF"
//            }
//            var lightVariant: String?
//            var darkVariant: String?
//        }
//        
//        let colors: Array<ColorModel> = [
//            ColorModel(color: .pink, lightVariant: "880800", darkVariant: "ff6a88"),
//            ColorModel(color: .red, lightVariant: "880800", darkVariant: "ff8f88"),
//            ColorModel(color: .orange, lightVariant: "935a00", darkVariant: "ffa924"),
//            ColorModel(color: .yellow, lightVariant: "806a00", darkVariant: "ffd60a"),
//            ColorModel(color: .green, lightVariant: "19722f", darkVariant: "60dc7f"),
//            ColorModel(color: .mint, lightVariant: "127270", darkVariant: "85ebe8"),
//            ColorModel(color: .teal, lightVariant: "157182", darkVariant: "6cd5e7"),
//            ColorModel(color: .cyan, lightVariant: "00719f", darkVariant: "97e1ff"),
//            ColorModel(color: .blue, lightVariant: "004080", darkVariant: "80bfff"),
//            ColorModel(color: .indigo, lightVariant: "1d1bb1", darkVariant: "908fee"),
//            ColorModel(color: .purple, lightVariant: "7d0eb4", darkVariant: "dba1f8"),
//            ColorModel(color: .brown, lightVariant: "665238", darkVariant: "cfbda7"),
//            
//            ColorModel(color: .white, lightVariant: "FFFFFF", darkVariant: "FFFFFF"),
//            ColorModel(color: .black, lightVariant: "000000", darkVariant: "000000")
//        ]
//        
//        
//        if color == .primary {
//            return scheme == .dark ? .white : .black
//        } else {
//            let theColor = colors.filter { $0.color == color }.first!
//            if scheme == .dark {
//                return Color.fromHex(theColor.darkVariant)!
//            } else {
//                return Color.fromHex(theColor.lightVariant)!
//            }
//        }
//    }
//    
    
    func lighter(by percentage: CGFloat = 30.0) -> Color {
        return self.adjust(by: abs(percentage))
    }
    
    
    func darker(by percentage: CGFloat = 30.0) -> Color {
        return self.adjust(by: -1 * abs(percentage))
    }
    
    
    func adjust(by percentage: CGFloat = 30.0) -> Color {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 1.0
        #if os(iOS)
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        NSColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        return Color(red: min(red + percentage / 100, 1.0), green: min(green + percentage / 100, 1.0), blue: min(blue + percentage / 100, 1.0), opacity: alpha)
    }
    
//    static var lavendar: Color {
//        return Color(uiColor: UIColor(red: 0.60, green: 0.60, blue: 1.00, alpha: 1.00))
//    }
//    
//    static var lightLavendar: Color {
//        return Color(uiColor: UIColor(red: 0.80, green: 0.80, blue: 1.00, alpha: 1.00))
//    }    

//    var name: String {
//        switch self {
//        case .pink:   return "pink"
//        case .red:    return "red"
//        case .orange: return "orange"
//        case .yellow: return "yellow"
//        case .green: return "green"
//        case .mint: return "mint"
//        case .teal: return "teal"
//        case .cyan: return "cyan"
//        case .blue: return "blue"
//        case .lavendar: return "lavendar"
//        case .lightLavendar: return "lightLavendar"
//        case .purple: return "purple"
//        case .brown: return "brown"
//        default: return "white"
//        }
//    }
//    
    
    //    static func fromName(_ name: String) -> Color {
    //        let colors: Array<Color> = [.pink, .red, .orange, .yellow, .green, .mint, .cyan, .blue, .indigo, .purple, .brown, .teal]
    //        return colors.first(where: { $0.description == name })!
    //    }
    
    
    
    #if os(iOS)
    static func getGrayFromName(_ name: String) -> Color {
        //print(name)
        if name == "secondarySystemBackground" {
            return Color(.secondarySystemBackground)
            
        } else if name == "gray" {
            return Color.gray
            
        } else if name == "darkGray" {
            return Color.darkGray
        } else if name == "darkGray2" {
            return Color.darkGray2
        } else if name == "darkGray3" {
            return Color.darkGray3
            
        } else if name == "black" {
            return Color.black
            
        } else if name == "systemGray" {
            return Color(uiColor: .systemGray)
        } else if name == "systemGray2" {
            return Color(uiColor: .systemGray2)
        } else if name == "systemGray3" {
            return Color(uiColor: .systemGray3)
        } else if name == "systemGray4" {
            return Color(uiColor: .systemGray4)
        } else if name == "systemGray5" {
            return Color(uiColor: .systemGray5)
        } else if name == "systemGray6" {
            return Color(uiColor: .systemGray6)
            
        } else {
            return Color.black
        }
    }
    #else
    static func getGrayFromName(_ name: String) -> Color {
        //print(name)
        if name == "secondarySystemBackground" {
            return Color(.systemGray)
            
        } else if name == "gray" {
            return Color.gray
            
        } else if name == "darkGray" {
            return Color.darkGray
        } else if name == "darkGray2" {
            return Color.darkGray2
        } else if name == "darkGray3" {
            return Color.darkGray3
            
        } else if name == "black" {
            return Color.black
            
        } else if name == "systemGray" {
            return Color(nsColor: .systemGray)
        } else if name == "systemGray2" {
            return Color(nsColor: .systemGray)
        } else if name == "systemGray3" {
            return Color(nsColor: .systemGray)
        } else if name == "systemGray4" {
            return Color(nsColor: .systemGray)
        } else if name == "systemGray5" {
            return Color(nsColor: .systemGray)
        } else if name == "systemGray6" {
            return Color(nsColor: .systemGray)
            
        } else {
            return Color.black
        }
    }
    #endif
    
    
    
    #if os(macOS)
    static var totalDarkGray = Color(NSColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.00))
    static var darkGray = Color(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.00))
    static var darkGray2 = Color(NSColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.00))
    static var darkGray3 = Color(NSColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.00))
    static var brainPink = Color(NSColor(red: 0.85, green: 0.65, blue: 0.70, alpha: 1.00))
    #else
    static var totalDarkGray = Color(UIColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.00))
    static var darkGray = Color(UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.00))
    static var darkGray2 = Color(UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.00))
    static var darkGray3 = Color(UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.00))
    static var brainPink = Color(UIColor(red: 0.85, green: 0.65, blue: 0.70, alpha: 1.00))
    #endif
}
