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
    case customImage(SymbolConfig?)
}

struct LogoConfig {
    var parent: (any CanHandleLogo & Observation.Observable)?
    var fallBackType: LogoFallBackType
    var size: CGFloat? = nil
}

struct BusinessLogo: View {
    @Local(\.useBusinessLogos) var useBusinessLogos
    
    @Environment(PlaidModel.self) private var plaidModel
    
    var config: LogoConfig
    
    //var parent: T?
    //var fallBackType: LogoFallBackType
    //var logoSize: CGFloat? = nil
    
    var theLogoSize: CGFloat {
        config.size ?? (useBusinessLogos ? 30 : 22)
    }
        
    #if os(iOS)
    @State private var logo: UIImage?
    #else
    @State private var logo: NSImage?
    #endif
    
//    var logo: UIImage? {
//        if let logoData = config.parent?.logo, let image = UIImage(data: logoData) {
//            return image
//        }
//        return nil
//    }
   
    var body: some View {
        if useBusinessLogos {
            Group {
                if let image = logo  {
                    logoImage(image)
                    
                } else if case
                    let .customImage(imageConfig) = config.fallBackType,
                    let imageConfig = imageConfig,
                    let imageName = imageConfig.name {
                    Image(systemName: imageName)
                        .foregroundStyle(config.parent == nil ? .gray : (imageConfig.color ?? config.parent!.color))
                
                } else if let parent = config.parent {
                    methColorCircle(parent)
                    
                } else {
                    fallbackImage
                }
            }
            .onChange(of: config.parent?.logo, initial: true) {
                prepareLogo(data: config.parent?.logo)
            }
        } else {
            if case
                let .customImage(imageConfig) = config.fallBackType,
                let imageConfig = imageConfig,
                let imageName = imageConfig.name {
                Image(systemName: imageName)
                    .foregroundStyle(config.parent == nil ? .gray : (imageConfig.color ?? config.parent!.color))
                
            } else if let parent = config.parent {
                methColorCircle(parent)
                
            } else {
                fallbackImage
            }
        }
    }
    
    
    var fallbackImage: some View {
        Image(systemName: "circle.fill")
            .foregroundStyle(config.parent == nil ? .gray : config.parent!.color)
    }
    
    
    #if os(iOS)
    @ViewBuilder
    func logoImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: theLogoSize, height: theLogoSize, alignment: .center)
            .clipShape(Circle())
    }
    #else
    @ViewBuilder
    func logoImage(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .frame(width: theLogoSize, height: theLogoSize, alignment: .center)
            .clipShape(Circle())
    }
    #endif
    
    
    @ViewBuilder
    func methColorCircle(_ meth: CanHandleLogo) -> some View {
        Image(systemName: "circle.fill")
            .font(Font.system(size: theLogoSize))
            .imageScale(.medium)
            .frame(width: theLogoSize, height: theLogoSize, alignment: .center)
            .foregroundStyle(backgroundColor(parent: config.parent))
    }
    
    #if os(iOS)
    
    func prepareLogo(data: Data?) {
        if let cachedImage = ImageCache.shared.loadFromCache(
            parentTypeId: config.parent?.logoParentType.id,
            parentId: config.parent?.id,
            id: config.parent?.id
        ) {
            //print("Found cached image for \(config.parent?.logoParentType.id ?? 0)_\(config.parent?.id ?? "unknown")")
            self.logo = cachedImage
            
        } else if let logoData = config.parent?.logo, let image = UIImage(data: logoData) {
            //print("need to cache image for \(config.parent?.logoParentType.id ?? 0)_\(config.parent?.id ?? "unknown")")
            self.logo = image
            Task.detached {
                await ImageCache.shared.saveToCache(
                    parentTypeId: config.parent?.logoParentType.id,
                    parentId: config.parent?.id,
                    id: config.parent?.id,
                    data: logoData
                )
            }
            
        } else {
            self.logo = nil
        }
    }
    #else
    func prepareLogo(data: Data?) {
        if let cachedImage = ImageCache.shared.loadFromCache(
            parentTypeId: config.parent?.logoParentType.id,
            parentId: config.parent?.id,
            id: config.parent?.id
        ) {
            //print("Found cached image for \(config.parent?.logoParentType.id ?? 0)_\(config.parent?.id ?? "unknown")")
            self.logo = cachedImage
            
        } else if let logoData = config.parent?.logo, let image = NSImage(data: logoData) {
            //print("need to cache image for \(config.parent?.logoParentType.id ?? 0)_\(config.parent?.id ?? "unknown")")
            self.logo = image
            Task.detached {
                await ImageCache.shared.saveToCache(
                    parentTypeId: config.parent?.logoParentType.id,
                    parentId: config.parent?.id,
                    id: config.parent?.id,
                    data: logoData
                )
            }
            
        } else {
            self.logo = nil
        }
    }
    #endif
    
    
    func backgroundColor(parent: (any CanHandleLogo & Observation.Observable)?) -> some ShapeStyle {
        switch config.fallBackType {
        case .color:
            return AnyShapeStyle(parent?.color ?? .clear)
            
        case .gradient:
            let rainbowGradient = Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red])
            return AnyShapeStyle(AngularGradient(gradient: rainbowGradient, center: .center))
            
        case .customImage:
            return AnyShapeStyle(Color.gray)
        }
    }
}




//
//
//struct BigBusinessLogo<T: CanHandleLogo & Observation.Observable>: View {
//    @Local(\.useBusinessLogos) var useBusinessLogos
//    
//    @Environment(PlaidModel.self) private var plaidModel
//    var parent: T?
//    var fallBackType: LogoFallBackType
//    
//    var logoSize: CGFloat = 60
//        
//    var userSelectedLogo: UIImage? {
//        if let logoData = parent?.logo, let image = UIImage(data: logoData)  {
//            return image
//        }
//        return nil
//    }
//   
//    var body: some View {
//        if useBusinessLogos {
//            if let image = userSelectedLogo  {
//                logoImage(image)
//            } else if let parent = parent {
//                methColorCircle(parent)
//            } else {
//                fallbackImage
//            }
//        } else {
//            if let parent = parent {
//                methColorCircle(parent)
//            } else {
//                fallbackImage
//            }
//        }
//    }
//    
//    var fallbackImage: some View {
//        Image(systemName: "circle.fill")
//            .foregroundStyle(parent == nil ? .gray : parent!.color)
//    }
//    
//    
//    @ViewBuilder func logoImage(_ image: UIImage) -> some View {
//        Image(uiImage: image)
//            .resizable()
//            .frame(width: logoSize, height: logoSize, alignment: .center)
//            .clipShape(Circle())
//    }
//    
//    
//    @ViewBuilder func methColorCircle(_ meth: CanHandleLogo) -> some View {
//        let rainbowGradient = Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red])
//                                       
//        Image(systemName: "circle.fill")
//            .font(Font.system(size: logoSize))
//            .imageScale(.medium)
//            .frame(width: logoSize, height: logoSize, alignment: .center)
//            .foregroundStyle(backgroundColor(parent: parent))
////            .if(fallBackType == .gradient) {
////                $0.foregroundStyle(AngularGradient(gradient: rainbowGradient, center: .center))
////            }
////            .if(fallBackType == .color) {
////                $0.foregroundStyle(meth.color)
////            }
//    }
//    
//    
//    //@ViewBuilder
//    func backgroundColor(parent: T?) -> some ShapeStyle {
//        switch fallBackType {
//        case .color:
//            return AnyShapeStyle(parent?.color ?? .clear)
//            
//        case .gradient:
//            let rainbowGradient = Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red])
//            return AnyShapeStyle(AngularGradient(gradient: rainbowGradient, center: .center))
//            
//        case .customImage(let string):
//            return AnyShapeStyle(Color.gray)
//        }
//    }
//}
