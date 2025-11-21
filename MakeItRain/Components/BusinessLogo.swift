//
//  BankLogo.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/27/25.
//

import SwiftUI

enum LogoFallBackType {
    case color
    case gradient
    case customImage(String?)
}

struct BusinessLogo<T: CanHandleLogo & Observation.Observable>: View {
    @Local(\.useBusinessLogos) var useBusinessLogos
    
    @Environment(PlaidModel.self) private var plaidModel
    var parent: T?
    var fallBackType: LogoFallBackType
    
    var logoSize: CGFloat { useBusinessLogos ? 30 : 22 }
        
    var userSelectedLogo: UIImage? {
        if let logoData = parent?.logo, let image = UIImage(data: logoData)  {
            return image
        }
        return nil
    }
   
    var body: some View {
        if useBusinessLogos {
            if let image = userSelectedLogo  {
                logoImage(image)
                
            } else if case let .customImage(image) = fallBackType, let image = image {
                Image(systemName: image)
                    .foregroundStyle(parent == nil ? .gray : parent!.color)
            
            } else if let parent = parent {
                methColorCircle(parent)
                
            } else {
                fallbackImage                
            }
        } else {
            if case let .customImage(image) = fallBackType, let image = image {
                Image(systemName: image)
                    .foregroundStyle(parent == nil ? .gray : parent!.color)
            } else if let parent = parent {
                methColorCircle(parent)
            } else {
                fallbackImage
            }
        }
    }
    
    var fallbackImage: some View {
        Image(systemName: "circle.fill")
            .foregroundStyle(parent == nil ? .gray : parent!.color)
    }
    
    
    @ViewBuilder func logoImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: logoSize, height: logoSize, alignment: .center)
            .clipShape(Circle())
    }
    
    
    @ViewBuilder func methColorCircle(_ meth: CanHandleLogo) -> some View {
        //let rainbowGradient = Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red])
                                       
        Image(systemName: "circle.fill")
            .font(Font.system(size: logoSize))
            .imageScale(.medium)
            .frame(width: logoSize, height: logoSize, alignment: .center)
            .foregroundStyle(backgroundColor(parent: parent))
        
//            .if(fallBackType == .gradient) {
//                $0.foregroundStyle(AngularGradient(gradient: rainbowGradient, center: .center))
//            }
//            .if(fallBackType == .color) {
//                $0.foregroundStyle(meth.color)
//            }
    }
    
    
    //@ViewBuilder
    func backgroundColor(parent: T?) -> some ShapeStyle {
        switch fallBackType {
        case .color:
            return AnyShapeStyle(parent?.color ?? .clear)
            
        case .gradient:
            let rainbowGradient = Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red])
            return AnyShapeStyle(AngularGradient(gradient: rainbowGradient, center: .center))
            
        case .customImage(let string):
            return AnyShapeStyle(Color.gray)
        }
    }
}



struct BigBusinessLogo<T: CanHandleLogo & Observation.Observable>: View {
    @Local(\.useBusinessLogos) var useBusinessLogos
    
    @Environment(PlaidModel.self) private var plaidModel
    var parent: T?
    var fallBackType: LogoFallBackType
    
    var logoSize: CGFloat = 60
        
    var userSelectedLogo: UIImage? {
        if let logoData = parent?.logo, let image = UIImage(data: logoData)  {
            return image
        }
        return nil
    }
   
    var body: some View {
        if useBusinessLogos {
            if let image = userSelectedLogo  {
                logoImage(image)
            } else if let parent = parent {
                methColorCircle(parent)
            } else {
                fallbackImage
            }
        } else {
            if let parent = parent {
                methColorCircle(parent)
            } else {
                fallbackImage
            }
        }
    }
    
    var fallbackImage: some View {
        Image(systemName: "circle.fill")
            .foregroundStyle(parent == nil ? .gray : parent!.color)
    }
    
    
    @ViewBuilder func logoImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: logoSize, height: logoSize, alignment: .center)
            .clipShape(Circle())
    }
    
    
    @ViewBuilder func methColorCircle(_ meth: CanHandleLogo) -> some View {
        let rainbowGradient = Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red])
                                       
        Image(systemName: "circle.fill")
            .font(Font.system(size: logoSize))
            .imageScale(.medium)
            .frame(width: logoSize, height: logoSize, alignment: .center)
            .foregroundStyle(backgroundColor(parent: parent))
//            .if(fallBackType == .gradient) {
//                $0.foregroundStyle(AngularGradient(gradient: rainbowGradient, center: .center))
//            }
//            .if(fallBackType == .color) {
//                $0.foregroundStyle(meth.color)
//            }
    }
    
    
    //@ViewBuilder
    func backgroundColor(parent: T?) -> some ShapeStyle {
        switch fallBackType {
        case .color:
            return AnyShapeStyle(parent?.color ?? .clear)
            
        case .gradient:
            let rainbowGradient = Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red])
            return AnyShapeStyle(AngularGradient(gradient: rainbowGradient, center: .center))
            
        case .customImage(let string):
            return AnyShapeStyle(Color.gray)
        }
    }
}
