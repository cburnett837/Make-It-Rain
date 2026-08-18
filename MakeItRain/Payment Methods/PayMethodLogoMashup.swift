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
    var size: CGFloat?
    
    var theSize: CGFloat {
        return size ?? 34
    }
    
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
                    theLogo(meth: meth, size: theSize)
                    
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
                    
                } else {
                    let logoSize: CGFloat = size == nil ? 18 : (theSize / 2)
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
                    .if(size != nil) {
                        $0.frame(width: theSize, height: theSize)
                    }
                    
                    //.background(Rectangle().fill(Color.red))
                }
                
            } else {
                theLogo(meth: meth, size: theSize)
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
