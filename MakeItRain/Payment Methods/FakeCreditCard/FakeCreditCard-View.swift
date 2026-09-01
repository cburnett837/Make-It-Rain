//
//  FakeCreditCardView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//


import SwiftUI
import LocalAuthentication

struct FakeCreditCardView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel

    var meth: CBPaymentMethod
    @Bindable var model: PayMethodsTable.ViewModel
    var info: PayMethodsTable.ViewModel.Info
    @Binding var navPath: NavigationPath
    var sortedMethods: [CBPaymentMethod]
    
    @State private var blur: CGFloat = 0
    @State private var scale: CGFloat = 1
    //@State private var showOfflineCardDetailsSheet = false

    
    var month: CBMonth? {
        calModel.months.filter({ $0.actualNum == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }).first
    }
    
    /// Even though this is a property in the model, we need it to be local so we can use it in the visual effects capture list.
    var isCardSelected: Bool {
        return model.isCardSelected
    }
        
    var isCurrent: Bool {
        meth.id == model.selectedPaymentMethod?.id
    }
    
    var currentIndex: Int {
        sortedMethods.firstIndex(where: { $0.id == meth.id }) ?? 0
    }
    
    var selectedIndex: Int {
        sortedMethods.firstIndex(where: { $0.id == model.selectedPaymentMethod?.id }) ?? 0
    }
    
    var plaidBalance: CBPlaidBalance? {
        plaidModel.balances.filter({ $0.payMethodID == meth.id }).first
    }
    
    var plaidBalanceIsStale: Bool {
        if let balance = plaidBalance, let entered = balance.enteredDate {
            return Calendar.current.dateComponents([.day], from: entered, to: Date()).day! > 2
        } else {
            return false
        }
        
    }

    var body: some View {
        //let _ = Self._printChanges()
        card
            //.zIndex(Double(currentIndex))
            .padding(14)
            .frame(maxWidth: .infinity)
            .frame(height: CARD_HEIGHT)
            .background(fakeCardBackground)
            //.shadow(radius: 10)
            .scenePadding(.horizontal) /// Pad the card instead of the list since the transaction list is naturally padded.
            .blur(radius: blur)
            .scaleEffect(scale)
            .onTapGesture(perform: touchCard)
            .onChange(of: model.hideUnselectedCards) { old, new in
                guard meth.id != model.selectedPaymentMethod?.id else { return }
                if new {
                    blur = 0
                    scale = 0
                } else {
                    blur = 0
                    scale = 1
                }
            }
            .overlay(alignment: .top) {
                if isCardSelected && isCurrent {
                    FakeCreditCardAccessoryView(
                        meth: meth,
                        model: model,
                        blur: $blur,
                        scale: $scale,
                        navPath: $navPath
                    )
                }
            }
            .visualEffect { [info, isCardSelected, selectedIndex, currentIndex, isCurrent] content, proxy in
                let rect = proxy.frame(in: .scrollView)

                let pushOffset = selectedIndex < currentIndex
                ? info.containerSize.height + info.safeArea.bottom - rect.minY
                : -rect.minY

                let stackedScale = selectedIndex < currentIndex ? 1.0 : 0.95

                return content
                    /// use a tiny scale effect so we don't see the other cards bounce behind the selected card when animating.
                    .scaleEffect(isCardSelected ? (isCurrent ? 1 : stackedScale) : 1, anchor: .top)
                    .offset(y: isCardSelected ? pushOffset : 0)
            }
        #if os(iOS)
            .sheet(isPresented: $model.showOfflineCardDetailsSheet) {
                if let meth = model.selectedPaymentMethod {
                    FakeCreditCardOfflineDetailsSheet(payMethod: meth)
                }
            }
        #endif
    }
    
    @ViewBuilder
    var card: some View {
        VStack {
            HStack {
                HStack(spacing: 12) {
                    PayMethodLogoMashup(meth: meth, size: 40)
                        .blur(radius: blur)
                    
                    Text(meth.title)
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
                
                if meth.isUnified {
                    let ids = payModel.paymentMethods
                        .filter({ filterMeth in
                            if meth.isUnifiedDebit {
                                return filterMeth.isDebitOrCash && filterMeth.isPermittedAndNotHidden
                            } else if meth.isUnifiedCredit {
                                return filterMeth.isCreditOrLoan && filterMeth.isPermittedAndNotHidden
                            } else {
                                return false
                            }
                        })
                        .filter { $0.accountHolderFilter() }
                        .map({ $0.id })
                    
                    let balance = plaidModel.balances
                        .filter({ ids.contains($0.payMethodID) })
                        .map({ $0.amount })
                        .reduce(0, +)
                    
                    Text(balance.currencyWithDecimals())
                        .bold()
                
                    
                } else if let balance = plaidBalance {
                    HStack {
                        Text(balance.amount.currencyWithDecimals())
                            .bold()
                        
                        if plaidBalanceIsStale {
                            Image(systemName: "exclamationmark.triangle")
                        }
                    }
                }
            }
            
            HStack(alignment: .top) {
                Spacer()
                if let balance = plaidBalance {
                    Text("\(Date().timeSince(balance.enteredDate))")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                        .opacity(isCardSelected && meth.id == model.selectedPaymentMethod?.id ? 1 : 0)
                        .offset(y: -14)
                }
            }
                                  
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(meth.accountType.prettyValue)
                        if meth.isPrivate { Image(systemName: "person.slash") }
                        if meth.isHidden { Image(systemName: "eye.slash") }
                        if meth.notifyOnDueDate { Image(systemName: "alarm") }
                    }
                                        
                    Text(meth.holderDisplay)
                        .lineLimit(1)
                    
                    Text("**** \(meth.last4 ?? "****")")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                //Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    if let ccBrand = meth.ccBrand {
                        Image(ccBrand.rawValue)
                            .renderingMode(.original)
                            .interpolation(.high)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 40, alignment: .bottomTrailing)
                            .offset(x:
                                ccBrand.rawValue.contains("visa")
                                ? 18
                                : ccBrand.rawValue.contains("mastercard")
                                ? 14
                                : 0
                            )
                    }
                    
                    if let cunt = meth.country {
                        HStack {
                            FlagCircle(code: cunt.code)
                            Text("\(cunt.currencyCode)")
                        }
                    }
                }
                
            }
        }
    }
    
    
    
    @ViewBuilder
    var fakeCardBackground: some View {
        let colors: Array<Color> = meth.isUnified ? [
            .purple, .red, .orange,
            .blue, .red, .orange,
            .blue, .orange, .orange
        ] : [
            meth.color, meth.color, meth.color,
            meth.color.lighter(by: 30), meth.color, meth.color.lighter(by: 30),
            meth.color, meth.color.lighter(by: 30), meth.color
        ]
        
        RoundedRectangle(cornerRadius: 26)
            //.fill(AngularGradient(gradient: rainbowGradient, center: .center))
            .fill(
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        .init(0, 0), .init(0.5, 0), .init(1, 0),
                        .init(0, 0.5), .init(0.9, 0.6), .init(1, 0.5),
                        .init(0, 1), .init(0.5, 1), .init(1, 1),
                    ],
                    colors: colors
                )
            )
    }
    
    
    func touchCard() {
        withAnimation(model.animation) {
            if isCardSelected {
                model.selectedPaymentMethod = nil
                model.hideUnselectedCards = false
            } else {
                model.selectedPaymentMethod = meth
            }
        } completion: {
            if isCardSelected {
                model.hideUnselectedCards = true
            }
        }
    }
}
