//
//  FlagCircle.swift
//  MakeItRain
//
//  Created by Cody Burnett on 7/31/26.
//

import SwiftUI

struct FlagCircle: View {
    var code: String?
    var size: CGFloat = 22
    
    var body: some View {
        if let code {
            Image("flags/\(code.lowercased())")
                .resizable()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.theme)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "flag")
                        .font(.caption)
                        
                }            
        }
        
    }
}
