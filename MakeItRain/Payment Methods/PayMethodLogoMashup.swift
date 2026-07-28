//
//  PayMethodLogoMashup.swift
//  MakeItRain
//
//  Created by Cody Burnett on 7/27/26.
//

import SwiftUI

struct PayMethodLogoMashup: View {
    @Environment(PayMethodModel.self) private var payModel
    
    var meth: CBPaymentMethod?
    
    var meths: [CBPaymentMethod] {
        guard let meth else { return [] }
        return payModel.getMethodsForUnified(type: meth.isUnifiedCredit ? .credit : .debit)
    }
    
    var body: some View {
        if let meth = meth {
            if meth.isUnified {
                if meths.count == 0 {
                    Image(systemName: "creditcard")
                        .schemeBasedForegroundStyle()
                    
                } else if meths.count == 1 {
                    theLogo(meth: meth, size: 34)
                    
                } else if meths.count == 2 {
                    let logoSize: CGFloat = 21
                    let overlap: CGFloat = 5

                    let offsets: [CGSize] = [
                        CGSize(width: -overlap, height: 0),
                        CGSize(width: overlap, height: 0)
                    ]

                    ZStack {
                        ForEach(0..<2, id: \.self) { i in
                            theLogo(meth: meths[i], size: logoSize)
                                .offset(offsets[i])
                        }
                    }
//                    VStack(spacing: 0) {
//                        HStack(spacing: 0) {
//                            theLogo(meth: meths[0], size: 21)
//                            Spacer()
//                        }
//                        
//                        HStack(spacing: 0) {
//                            Spacer()
//                            theLogo(meth: meths[1], size: 21)
//                        }
//                    }
                } else {
                    let logoSize: CGFloat = 18
                    let overlap: CGFloat = 7

                    let offsets: [CGSize] = [
                        CGSize(width: -overlap, height: -overlap), // left ear
                        CGSize(width: overlap, height: -overlap),  // right ear
                        CGSize(width: 0, height: overlap)          // face
                    ]
                    
                    ZStack {
                        ForEach(0..<3, id: \.self) { i in
                            theLogo(meth: meths[i], size: logoSize)
                                .offset(offsets[i])
                        }
                    }
//                    VStack(spacing: 0) {
//                        HStack(spacing: 0) {
//                            theLogo(meth: meths[0], size: 16)
//                            theLogo(meth: meths[1], size: 16)
//                        }
//                        theLogo(meth: meths[2], size: 16)
//                    }
                }
                
            } else {
                theLogo(meth: meth, size: 34)
            }
            
            
        } else {
            Image(systemName: "creditcard")
                .schemeBasedForegroundStyle()
        }
    }
    
    @ViewBuilder
    func theLogo(meth: CBPaymentMethod, size: CGFloat) -> some View {
        BusinessLogo(config: .init(
            parent: meth,
            fallBackType: meth.isUnified ? .gradient : .color,
            size: size
        ))
    }
}

#Preview {
    PayMethodLogoMashup()
}
