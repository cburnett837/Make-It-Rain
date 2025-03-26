//
//  LineItemViewPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI

#if os(iOS)
struct LineItemMiniView2: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    
    //@AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @AppStorage("incomeColor") var incomeColor: String = Color.blue.description
    //@AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    //@AppStorage("useWholeNumbers") var useWholeNumbers = false
    //@AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    //@AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    //@AppStorage("phoneLineItemTotalPosition") var phoneLineItemTotalPosition: PhoneLineItemTotalPosition = .below
    
    @Environment(CalendarModel.self) private var calModel
    

    @State private var labelWidth: CGFloat = 20.0
    @Binding var transEditID: String?
    @Bindable var trans: CBTransaction
    @Bindable var day: CBDay
    //@Binding var putBackToBottomPanelViewOnRotate: Bool
    //@Binding var transHeight: CGFloat
    @State private var showDeleteAlert = false
    
    var amountColor: Color {
        if trans.payMethod?.accountType == .credit {
            trans.amount < 0 ? Color.fromName(incomeColor) : preferDarkMode ? .gray : .totalDarkGray
        } else {
            trans.amount > 0 ? Color.fromName(incomeColor) : preferDarkMode ? .gray : .totalDarkGray
        }
    }
        
    var lineColor: Color {
        if calModel.hilightTrans == trans {
            Color(.secondarySystemFill)
        } else {
            if preferDarkMode {
                Color.clear
            } else {
                trans.category?.color.opacity(0.1) ?? Color.gray.opacity(0.1)
            }
        }
    }
    
    var titleColor: Color {
        trans.color == Color.white || trans.color == Color.black ? Color.primary : trans.color
    }
    
    var wasUpdatedByAnotherUser: Bool {
        trans.updatedBy.id != AppState.shared.user?.id
    }
    
    
    var body: some View {
        @Bindable var calModel = calModel
        
        HStack(spacing: 2) {
            accessoryIndicator
            VStack(alignment: .leading, spacing: 0) {
                Text(trans.title)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(trans.color == .white || trans.color == .black ? .primary : trans.color)
                Text(trans.amountString)
                    .font(.system(size: 10))
                    .foregroundStyle(amountColor)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .fixedSize(horizontal: false, vertical: true)
        
//        Group {
//            Group {
//                HStack(spacing: 2) {
//                    if phoneLineItemDisplayItem != .category {
//                        //accessoryIndicator
//                    }
//                    VStack(alignment: .leading, spacing: 0) {
//                        Text(trans.title)
//                            .font(.caption2)
//                            .minimumScaleFactor(0.8)
//                            .lineLimit(1)
//                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            .foregroundStyle(titleColor)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        //.frame(maxHeight: .infinity, alignment: .bottom)
//                            .overlay { ExcludeFromTotalsLine(trans: trans) }
//                        
//                        Text(trans.amountString)
//                            .minimumScaleFactor(0.8)
//                            .foregroundStyle(amountColor)
//                            .lineLimit(1)
//                            .font(.system(size: 10))
//                            .overlay { ExcludeFromTotalsLine(trans: trans) }
//                            .frame(maxHeight: .infinity, alignment: .bottom)
//                        
//                    }
////                    .italic(wasUpdatedByAnotherUser)
////                    .bold(wasUpdatedByAnotherUser)
////                    .frame(maxWidth: .infinity, alignment: .leading)
//                }
//            }
////            .transition(.opacity)
////            .frame(maxWidth: .infinity, alignment: .leading)
////            .padding(.horizontal, 2)
////            
////            .frame(height: transHeight > 0 ? transHeight : nil)
////            .background(RoundedRectangle(cornerRadius: 4).fill(lineColor))
////            .transMaxViewHeightObserver()
//        }
////        .padding(.horizontal, preferDarkMode ? 0 : 1)
////        .contentShape(Rectangle())
////        .draggable(trans) { dragPreview }
////        //.allowsHitTesting(phoneLineItemDisplayItem == .both)
////        .if(phoneLineItemDisplayItem == .both) {
////            $0.onTapGesture {
////                calModel.hilightTrans = trans
////                transEditID = trans.id
////            }
////        }
////        
////        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert) {
////            Button("Yes", role: .destructive) {
////                trans.action = .delete
////                calModel.saveTransaction(id: trans.id)
////            }
////            Button("No", role: .cancel) { showDeleteAlert = false }
////        } message: {
////            Text("Delete \"\(trans.title)\"?")
////        }
////        .fixedSize(horizontal: false, vertical: true)
        
    }
    
    var dragPreview: some View {
        Text(trans.title)
            .padding(6)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(trans.category?.color ?? .gray)
            }
    }
    
    var accessoryIndicator: some View {
//        Capsule()
//            .fill(
//                calModel.isUnifiedPayMethod && lineItemIndicator == .paymentMethod
//                ? (trans.payMethod?.color ?? .gray)
//                : (trans.category?.color ?? .gray)
//            )
//            .frame(width: 3)
//            //.frame(maxHeight: .infinity)
//            .padding(.vertical, 2)
//        
//        
//        
        Canvas { context, size in
            let capsuleRect = CGRect(origin: .zero, size: size)
            let capsulePath = Path(roundedRect: capsuleRect, cornerRadius: size.height / 2) // Full capsule effect
            
            context.fill(capsulePath, with: .color(
                calModel.isUnifiedPayMethod && lineItemIndicator == .paymentMethod ? (trans.payMethod?.color ?? .gray) : (trans.category?.color ?? .gray)
            ))
        }
        .frame(width: 3)
        //.frame(maxHeight: .infinity)
        .padding(.vertical, 2)
    }
}




struct LineItemMiniView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    
    //@AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @AppStorage("incomeColor") var incomeColor: String = Color.blue.description
    //@AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    @AppStorage("phoneLineItemTotalPosition") var phoneLineItemTotalPosition: PhoneLineItemTotalPosition = .below
    
    @Environment(CalendarModel.self) private var calModel
    

    @State private var labelWidth: CGFloat = 20.0
    @Binding var transEditID: String?
    @Bindable var trans: CBTransaction
    @Bindable var day: CBDay
    //@Binding var putBackToBottomPanelViewOnRotate: Bool
    //@Binding var transHeight: CGFloat
    @State private var showDeleteAlert = false
    
    var amountColor: Color {
        if trans.payMethod?.accountType == .credit {
            trans.amount < 0 ? Color.fromName(incomeColor) : preferDarkMode ? .gray : .totalDarkGray
        } else {
            trans.amount > 0 ? Color.fromName(incomeColor) : preferDarkMode ? .gray : .totalDarkGray
        }
    }
        
    var lineColor: Color {
        if calModel.hilightTrans == trans {
            Color(.secondarySystemFill)
        } else {
            if preferDarkMode {
                Color.clear
            } else {
                trans.category?.color.opacity(0.1) ?? Color.gray.opacity(0.1)
            }
        }
    }
    
    var titleColor: Color {
        trans.color == Color.white || trans.color == Color.black ? Color.primary : trans.color
    }
    
    var wasUpdatedByAnotherUser: Bool {
        trans.updatedBy.id != AppState.shared.user?.id
    }
    
    
    var body: some View {
        @Bindable var calModel = calModel
        Group {
            detailsLineItem
                //.transition(.opacity)
                //.frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)
                /// Ignore the transHeight variable until it has been fully calculated, and the apply it.
                /// As Per ChatGPT:
                /// The issue you’re encountering is likely due to the timing of how SwiftUI resolves layout constraints. The subviews are being resized before the maximum size has been properly determined because the frame modifier is applied too early in the layout process.
                /// To fix this, you can ensure the maximum size is only applied after all views have been measured by delaying the application of the frame modifier until the maximum size is fully resolved.
                //.frame(height: transHeight > 0 ? transHeight : nil)
                .background(RoundedRectangle(cornerRadius: 4).fill(lineColor))
                //.transMaxViewHeightObserver()
            //let _ = print("transHeight: \(transHeight)")
        }
        .padding(.horizontal, preferDarkMode ? 0 : 1)
        .contentShape(Rectangle())
        
        //.allowsHitTesting(phoneLineItemDisplayItem == .both)
        .if(phoneLineItemDisplayItem == .both) {
            $0
            .draggable(trans) { dragPreview }
            .onTapGesture {
                calModel.hilightTrans = trans
                transEditID = trans.id
            }
        }
        
        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert) {
            Button("Yes", role: .destructive) {
                trans.action = .delete
                calModel.saveTransaction(id: trans.id)
            }
            Button("No", role: .cancel) { showDeleteAlert = false }
        } message: {
            Text("Delete \"\(trans.title)\"?")
        }
//        .contextMenu {
//            TransactionContextMenu(trans: trans, transEditID: $transEditID, showDeleteAlert: $showDeleteAlert)
//        }
        
        .fixedSize(horizontal: false, vertical: true)
        
    }
    
    
    var detailsLineItem: some View {
        Group {
            HStack(spacing: 2) {
                if phoneLineItemDisplayItem != .category {
                    accessoryIndicator
                }
                
                if phoneLineItemDisplayItem == .title {
                    Text(trans.title)
                        .font(.caption)
                        //.minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .foregroundStyle(trans.color == .white || trans.color == .black ? .primary : trans.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay { ExcludeFromTotalsLine(trans: trans) }
                        .italic(wasUpdatedByAnotherUser)
                        .bold(wasUpdatedByAnotherUser)
                                        
                } else if phoneLineItemDisplayItem == .total {
                    totalText
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay { ExcludeFromTotalsLine(trans: trans) }
                        .italic(wasUpdatedByAnotherUser)
                        .bold(wasUpdatedByAnotherUser)
                    
                } else if phoneLineItemDisplayItem == .category {
                    Capsule()
                        .fill(
                            calModel.isUnifiedPayMethod && lineItemIndicator == .paymentMethod
                            ? (trans.payMethod?.color ?? .gray)
                            : (trans.category?.color ?? .gray)
                        )
                        .frame(height: 8)
                        //.frame(maxWidth: .infinity)
                        .padding(.vertical, 1)
                        .overlay { ExcludeFromTotalsLine(trans: trans) }
                                    
                } else {
//                    if putBackToBottomPanelViewOnRotate {
//                        inlineTitleAndTotal
//                            .overlay { ExcludeFromTotalsLine(trans: trans) }
//                        
//                    } else {
                        if AppState.shared.isLandscape {
                            stackedTitleAndTotal
                            //inlineTitleAndTotal
                                //.overlay { ExcludeFromTotalsLine(trans: trans) }
                            
                        } else if phoneLineItemTotalPosition == .below {
                            stackedTitleAndTotal
                            
                        } else if phoneLineItemTotalPosition == .inline && [.portrait, .portraitUpsideDown, .faceUp, .faceDown].contains(AppState.shared.orientation) {
                            inlineTitleAndTotal
                                .overlay { ExcludeFromTotalsLine(trans: trans) }
                            
                        } else {
                            inlineTitleAndTotal
                                .overlay { ExcludeFromTotalsLine(trans: trans) }
                        }
                    //}
                }
                
                if trans.notifyOnDueDate {
                    Image(systemName: "bell")
                        .foregroundStyle(.primary)
                        //.font(.caption2)
                        .font(.system(size: 10))
                }
            }
        }
    }
    
    
    var accessoryIndicator: some View {
        Capsule()
            .fill(
                calModel.isUnifiedPayMethod && lineItemIndicator == .paymentMethod
                ? (trans.payMethod?.color ?? .gray)//.gradient
                : (trans.category?.color ?? .gray)//.gradient
            )
            .frame(width: 3)
            //.frame(maxHeight: .infinity)
            .padding(.vertical, 2)
                
        
//        Canvas { context, size in
//            var color: Color {
//                calModel.isUnifiedPayMethod && lineItemIndicator == .paymentMethod
//                ? (trans.payMethod?.color ?? .gray)
//                : (trans.category?.color ?? .gray)
//            }
//            
//            let capsuleRect = CGRect(origin: .zero, size: size)
//            let capsulePath = Path(roundedRect: capsuleRect, cornerRadius: size.height / 2) // Full capsule effect
//            
//            context.fill(capsulePath, with: .color(color.gradient))
//        }
//        .frame(width: 3)
//        //.frame(maxHeight: .infinity)
//        .padding(.vertical, 2)
    }
    
    
    var stackedTitleAndTotal: some View {
        Group {
            VStack(alignment: .leading, spacing: 0) {
                Text(trans.title)
                    .font(.caption2)
                    //.minimumScaleFactor(0.8)
                    .lineLimit(1)
                    //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    .foregroundStyle(titleColor)
                    //.frame(maxWidth: .infinity, alignment: .leading)
                    //.frame(maxHeight: .infinity, alignment: .bottom)
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
                
                totalText
                    .font(.system(size: 10))
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
                    //.frame(maxHeight: .infinity, alignment: .bottom)
            }
            .italic(wasUpdatedByAnotherUser)
            .bold(wasUpdatedByAnotherUser)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    var inlineTitleAndTotal: some View {
        Group {
            HStack(spacing: 0) {
                Text(trans.title)
                    .font(.caption2)
                    //.minimumScaleFactor(0.8)
                    .lineLimit(1)
                    //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    .foregroundStyle(titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading) /// To push the total over
                
                totalText
                    .font(.system(size: 10))
            }
            .italic(wasUpdatedByAnotherUser)
            .bold(wasUpdatedByAnotherUser)
            //.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    var totalText: some View {
        Group {
            if useWholeNumbers && tightenUpEodTotals {
                Text("\(String(format: "%.00f", trans.amount).replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))")
                
            } else if useWholeNumbers {
                Text(trans.amount.currencyWithDecimals(0))
                
            } else if !useWholeNumbers && tightenUpEodTotals {
                Text(trans.amount.currencyWithDecimals(2).replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
                
            } else {
                Text(trans.amount.currencyWithDecimals(2))
            }
        }
        //.minimumScaleFactor(0.8)
        .foregroundStyle(amountColor)
        .lineLimit(1)
    }
      
    
    var dragPreview: some View {
        Text(trans.title)
            .padding(6)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(trans.category?.color ?? .gray)
            }
    }
}
#endif
