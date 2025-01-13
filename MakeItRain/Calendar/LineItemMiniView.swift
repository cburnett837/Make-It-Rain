//
//  LineItemViewPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI

#if os(iOS)
struct LineItemMiniView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    @AppStorage("incomeColor") var incomeColor: String = Color.blue.description
    @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    //@AppStorage("showPaymentMethodIndicator") var showPaymentMethodIndicator = false
    
    @AppStorage("lineItemInteractionMode") var lineItemInteractionMode: LineItemInteractionMode = .open
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    
    @AppStorage("phoneLineItemTotalPosition") var phoneLineItemTotalPosition: PhoneLineItemTotalPosition = .below

    
    //@Environment(RootViewModelPhone.self) var vm
    @Environment(CalendarModel.self) private var calModel

    @State private var labelWidth: CGFloat = 20.0
    @Binding var transEditID: String?
    @Bindable var trans: CBTransaction
    @Bindable var day: CBDay
    let outerGeo: GeometryProxy
    @Binding var overlayX: CGFloat?
    @Binding var overlayY: CGFloat?
    @Binding var putBackToBottomPanelViewOnRotate: Bool
    //@Binding var transEditID: Int?
    //@Binding var transPreviewID: Int?
    @State private var showDeleteAlert = false
    
    @State private var localGeoProxy: GeometryProxy?
    
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
    
    
    var body: some View {
        //@Bindable var vm = vm
        @Bindable var calModel = calModel
        Group {
            detailsLineItem
                //.allowsHitTesting(false)
                .transition(.opacity)
                //.transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)
            
                .background {
//                    if phoneLineItemDisplayItem != PhoneLineItemDisplayItem.both {
//                        RoundedRectangle(cornerRadius: 4)
//                            .fill(
//                                calModel.hilightTrans == trans
//                                ? Color(.secondarySystemFill)
//                                : lineItemIndicator == .background ? (trans.category?.color.opacity(0.3) ?? (colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.3))) : .clear
//                            )
//                    } else {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(lineColor)
                                .contentShape(Rectangle())
//                                .onTapGesture {
//                                    let outerGlobal = outerGeo.frame(in: .global)
//                                    let childFrame = geo.frame(in: .named("Custom"))
//                                    let childFrameGlobal = geo.frame(in: .global)
//                                    
//                                    /// Prevent view from being clickable if not fully on screen
//                                    if childFrameGlobal.maxY > outerGlobal.maxY || childFrameGlobal.minY < outerGlobal.minY {
//                                        print("View is not fully visible")
//                                    } else {
//                                        //calModel.transPreviewID = nil
//                                        //calModel.hilightTrans = nil
//                                        //withAnimation {
//                                            //overlayX = childFrame.midX
//                                            //overlayY = childFrame.midY
//                                            setPreview(midX: childFrame.midX, midY: childFrame.midY)
//                                        //}
//                                        
//                                    }
//                                }
                                .onAppear {
                                    localGeoProxy = geo
                                }
                        }
                    //}
                }
        }
        .contentShape(Rectangle())
        .draggable(trans) { dragPreview }
        
        .onTapGesture {
            if let localGeoProxy = localGeoProxy {
                let outerGlobal = outerGeo.frame(in: .global)
                let childFrame = localGeoProxy.frame(in: .named("Custom"))
                let childFrameGlobal = localGeoProxy.frame(in: .global)
                
                /// Prevent view from being clickable if not fully on screen
                if childFrameGlobal.maxY > outerGlobal.maxY || childFrameGlobal.minY < outerGlobal.minY {
                    print("View is not fully visible")
                } else {
                    //calModel.transPreviewID = nil
                    //calModel.hilightTrans = nil
                    //withAnimation {
                        //overlayX = childFrame.midX
                        //overlayY = childFrame.midY
                        setPreview(midX: childFrame.midX, midY: childFrame.midY)
                    //}
                }
            }
        }
        
        
        
        
//        .if(phoneLineItemDisplayItem != PhoneLineItemDisplayItem.both) {
//            $0.onTapGesture {
//                if viewMode == .details || viewMode == .scrollable {
//                    calModel.hilightTrans = trans
//
//                    if lineItemInteractionMode == .open {
//                        calModel.transEditID = trans.id
//                    } else {
//                        if calModel.transPreviewID == trans.id {
//                            calModel.transEditID = trans.id
//                        } else {
//                            calModel.transPreviewID = trans.id
//                        }
//                    }
//                } else {
//                    calModel.transEditID = trans.id
//                }
//            }
//        }
        
        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert) {
            Button("Yes", role: .destructive) {
                //Task { await calModel.delete(trans) }
                trans.action = .delete
                calModel.saveTransaction(id: trans.id)
            }
            Button("No", role: .cancel) { showDeleteAlert = false }
        } message: {
            Text("Delete \"\(trans.title)\"?")
        }
        .contextMenu {
            TransactionContextMenu(trans: trans, transEditID: $transEditID, showDeleteAlert: $showDeleteAlert)
        }
    }
    
    func setPreview(midX: CGFloat, midY: CGFloat) {
        overlayX = midX
        overlayY = midY
        if viewMode == .details || viewMode == .scrollable {
            calModel.hilightTrans = trans
            
            if lineItemInteractionMode == .open {
                transEditID = trans.id
            } else {
                if calModel.transPreviewID == trans.id {
                    transEditID = trans.id
                } else {
                    calModel.transPreviewID = trans.id
                }
            }
        } else {
            transEditID = trans.id
        }
    }
    
    
    var detailsLineItem: some View {
        Group {
            let wasUpdatedByAnotherUser = trans.updatedBy.id != AppState.shared.user?.id
            HStack(spacing: 2) {
                Capsule()
                    .fill(
                        calModel.isUnifiedPayMethod && lineItemIndicator == .paymentMethod
                        ? (trans.payMethod?.color ?? .gray)
                        : (trans.category?.color ?? .gray)
                    )
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 2)
                
                if phoneLineItemDisplayItem == .title {
                    Text(trans.title)
                        .font(.caption)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .foregroundStyle(trans.color == .white || trans.color == .black ? .primary : trans.color)
                        .if(wasUpdatedByAnotherUser) {
                            $0.italic(true).bold(true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay { ExcludeFromTotalsLine(trans: trans) }
                                        
                } else if phoneLineItemDisplayItem == .total {
                    totalText
                        .font(.caption)
                        .if(wasUpdatedByAnotherUser) {
                            $0.italic(true).bold(true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay { ExcludeFromTotalsLine(trans: trans) }
                    
                } else {
                    if putBackToBottomPanelViewOnRotate {
                        inlineTitleAndTotal
                            .overlay { ExcludeFromTotalsLine(trans: trans) }
                    } else {
                        if AppState.shared.isLandscape {
                            inlineTitleAndTotal
                                .overlay { ExcludeFromTotalsLine(trans: trans) }
                            
                        } else if phoneLineItemTotalPosition == .below {
                            stackedTitleAndTotal
                            
                        } else if phoneLineItemTotalPosition == .inline && [.portrait, .portraitUpsideDown, .faceUp, .faceDown].contains(AppState.shared.orientation) {
                            inlineTitleAndTotal
                                .overlay { ExcludeFromTotalsLine(trans: trans) }
                            
                        } else {
                            inlineTitleAndTotal
                                .overlay { ExcludeFromTotalsLine(trans: trans) }
                        }
                    }
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
    
    
    var stackedTitleAndTotal: some View {
        Group {
            let wasUpdatedByAnotherUser = trans.updatedBy.id != AppState.shared.user?.id
            VStack(alignment: .leading, spacing: 0) {
                Text(trans.title)
                    .font(.caption2)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    //.foregroundStyle(trans.color == .white || trans.color == .black ? .primary : trans.color)
                    .foregroundStyle(titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
                
                totalText
                    .font(.system(size: 10))
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
            }
            .if(wasUpdatedByAnotherUser) {
                $0.italic(true).bold(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        

    }
    
    
    var inlineTitleAndTotal: some View {
        Group {
            let wasUpdatedByAnotherUser = trans.updatedBy.id != AppState.shared.user?.id
            HStack(spacing: 0) {
                Text(trans.title)
                    .font(.caption2)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                //.foregroundStyle(trans.color == .white || trans.color == .black ? .primary : trans.color)
                    .foregroundStyle(titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                totalText
                    .font(.system(size: 10))
            }
            .if(wasUpdatedByAnotherUser) {
                $0.italic(true).bold(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        .minimumScaleFactor(0.8)
        .foregroundStyle(amountColor)
        .lineLimit(1)
    }
    
    
    
//    var detailsLineItemOG: some View {
//        Group {
//            let wasUpdatedByAnotherUser = trans.updatedBy.id != AppState.shared.user?.id
//            
//            //HStack(alignment: .circleAndTitle, spacing: 2) {
//            HStack(spacing: 2) {
//                
//                if calModel.isUnifiedPayMethod {
//                    if showPaymentMethodIndicator && (lineItemIndicator == .dot || lineItemIndicator == .emoji) {
//                        Capsule()
//                            .fill(LinearGradient(stops: [
//                                .init(color: trans.payMethod?.color ?? .gray, location: 0.5),
//                                    .init(color: trans.category?.color ?? .gray, location: 0.5)
//                            ], startPoint: .leading, endPoint: .trailing))
//                            .frame(width: 10, height: 6)
//                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                        
//                    } else if showPaymentMethodIndicator {
//                        Circle()
//                            .fill(trans.payMethod?.color ?? .gray)
//                            .frame(width: 6, height: 6)
//                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                        
//                    } else if (lineItemIndicator == .dot || lineItemIndicator == .emoji) {
//                        //Circle()
//                        Capsule()
//                            .fill(trans.category?.color ?? .gray)
//                            //.frame(width: 6, height: 6)
//                            //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            .frame(width: 2)
//                            .frame(maxHeight: .infinity)
//                            .padding(.vertical, 2)
//                    }
//                } else {
//                    if (lineItemIndicator == .dot || lineItemIndicator == .emoji) {
//                        Circle()
//                            .fill(trans.category?.color ?? .gray)
//                            .frame(width: 6, height: 6)
//                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                    }
//                }
//                
//                
//                
//                if phoneLineItemDisplayItem == .title {
//                    Text(trans.title)
//                        .font(.caption)
//                        //.minimumScaleFactor(0.8)
//                        .lineLimit(1)
//                        .foregroundStyle(trans.color == .white || trans.color == .black ? .primary : trans.color)
//                    
//                        //.foregroundStyle(trans.category?.color ?? .white)
//                        
//                        .if(wasUpdatedByAnotherUser) {
//                            $0.italic(true).bold(true)
//                        }
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                    
//    //                if !trans.tags.isEmpty {
//    //                    Image(systemName: "number")
//    //                        .foregroundStyle(.primary)
//    //                        .font(.caption2)
//    //                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//    //                } else {
//    //                    if trans.notifyOnDueDate {
//    //                        Image(systemName: "bell")
//    //                            .foregroundStyle(.primary)
//    //                            .font(.caption2)
//    //                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//    //                    }
//    //                }
//                    
//                } else if phoneLineItemDisplayItem == .total {
//                    Text(trans.amountString)
//                        .foregroundStyle(amountColor)
//                        .font(.caption)
//                        //.minimumScaleFactor(0.8)
//                        .lineLimit(1)
//                        .if(wasUpdatedByAnotherUser) {
//                            $0.italic(true).bold(true)
//                        }
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                    
//                } else {
//                    VStack(alignment: .leading, spacing: 0) {
//                        Text(trans.title)
//                            .font(.caption2)
//                            //.minimumScaleFactor(0.8)
//                            .lineLimit(1)
//                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            //.foregroundStyle(trans.color == .white || trans.color == .black ? .primary : trans.color)
//                            .foregroundStyle(titleColor)
//                        
////                        Text(trans.id)
////                            .font(.caption2)
//                        
//                        
//                        Group {
//                            if useWholeNumbers && tightenUpEodTotals {
//                                Text("\(String(format: "%.00f", trans.amount).replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))")
//                                
//                            } else if useWholeNumbers {
//                                Text(trans.amount.currencyWithDecimals(0))
//                                
//                            } else if !useWholeNumbers && tightenUpEodTotals {
//                                Text(trans.amount.currencyWithDecimals(2).replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
//                                
//                            } else {
//                                Text(trans.amount.currencyWithDecimals(2))
//                            }
//                        }
////                        .foregroundStyle(
////                            lineItemIndicator == .background
////                            ? (trans.category?.color ?? (trans.color == .white || trans.color == .black ? .primary : trans.color))
////                            : amountColor
////                        )
//                        .foregroundStyle(amountColor)
//                        .font(.system(size: 10))
//                        //.font(.caption2)
//                        //.minimumScaleFactor(0.8)
//                        .lineLimit(1)
//                    }
//                    .if(wasUpdatedByAnotherUser) {
//                        $0.italic(true).bold(true)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                }
//                
//                
//                
//                if trans.notifyOnDueDate {
//                    Image(systemName: "bell")
//                        .foregroundStyle(.primary)
//                        //.font(.caption2)
//                        .font(.system(size: 10))
//                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                }
//                
//            }
//        }
//    }
//    
//    
//    
    
            
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
