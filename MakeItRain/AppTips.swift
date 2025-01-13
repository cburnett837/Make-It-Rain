//
//  AppTips.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/6/25.
//

import Foundation
import TipKit

/// Tips are configured in ``MakeItRainApp.setupTips()``

#if os(iOS)
struct SwipeToChangeMonthsTip: Tip {
    /// This tip is used in ``CalendarViewPhone``
    
    /// These get saved in persistent storage when triggered.
    static let didChangeMonthViaNavList = Event(id: "didChangeMonthViaNavList")
    @Parameter static var didChangeViaSwipe: Bool = false
    
    var title: Text { Text("Change Months") }
    var message: Text? { Text("Swipe sideways on the title area to change the month.") }
    var image: Image? { Image(systemName: "arrow.left.arrow.right") }
    
    var rules: [Rule] {
        /// Set in ``RootView.onChange(of: navManager.navPath)``
        /// Once the month has been changed 3 times via the sidebar, the tip will display
        #Rule(Self.didChangeMonthViaNavList) { $0.donations.count >= 3 }
        
        /// Set in ``CalendarViewPhone``
        /// Once the user has changed months via a swipe on the navHeader, the tip is invalidated.
        #Rule(Self.$didChangeViaSwipe) { $0 == false }
    }
}

struct TouchAndHoldMonthToFilterCategoriesTip: Tip {
    /// This tip is used in ``CalendarViewPhone``
    
    /// These get saved in persistent storage when triggered.
    static let didTouchMonthName = Event(id: "didTouchMonthName")
    @Parameter static var didSelectCategoryFilter: Bool = false
    
    var title: Text { Text("Filter by Category") }
    var message: Text? { Text("Touch and hold the month name to filter by category.") }
    var image: Image? { Image(systemName: "line.3.horizontal.decrease.circle") }
    
    var rules: [Rule] {
        /// Set in ``CalendarViewPhone.sheet(isPresented: $showPaymentMethodSheet, onDismiss: {})``
        /// One the payment method sheet has been opened 3 times, show the tip.
        #Rule(Self.didTouchMonthName) { $0.donations.count >= 3 }
        
        /// Set in the button that opens the category sheet in``CalendarViewPhone.fakeNavHeader``
        /// Once the user has opened the category sheet, invalidate the tip.
        #Rule(Self.$didSelectCategoryFilter) { $0 == false }
    }
    
    var options: [Option] {
        MaxDisplayCount(1)
    }
    
}

struct TouchAndHoldPlusButtonTip: Tip {
    /// This tip is used in ``CalendarViewPhone``
    
    /// These get saved in persistent storage when triggered.
    static let didTouchPlusButton = Event(id: "didTouchPlusButton")
    @Parameter static var didSelectSmartReceiptOrTransferOption: Bool = false
    
    var title: Text { Text("Create Transfer or Upload Receipt") }
    var message: Text? { Text("Touch and hold the plus button to show additional options.") }
    var image: Image? { Image(systemName: "doc") }
    
    var rules: [Rule] {
        /// Set in ``CalendarViewPhone.sheet(isPresented: $showPaymentMethodSheet, onDismiss: {})``
        /// One the payment method sheet has been opened 3 times, show the tip.
        #Rule(Self.didTouchPlusButton) { $0.donations.count >= 3 }
        
        /// Set in the button that opens the category sheet in``CalendarViewPhone.fakeNavHeader``
        /// Once the user has opened the category sheet, invalidate the tip.
        #Rule(Self.$didSelectSmartReceiptOrTransferOption) { $0 == false }
    }
    
    var options: [Option] {
        MaxDisplayCount(1)
    }
}

#endif




struct ChangeTransactionTitleColorTip: Tip {
    /// This tip is used in ``TransactionEditView``
    
    /// These get saved in persistent storage when triggered.
    static let didOpenTransaction = Event(id: "didOpenTransaction")
    @Parameter static var didTouchColorChangeButton: Bool = false
    
    var title: Text { Text("Change Transaction Color") }
    var message: Text? { Text("Touch the bag to change the color of the transaction.") }
    var image: Image? {
        Image(systemName: "lightspectrum.horizontal")
            .symbolRenderingMode(.multicolor)
    }
    
    var rules: [Rule] {
        /// Set in ``TransactionEditView.task()``
        /// One the transaction sheet has been opened 5 times, show the tip.
        #Rule(Self.didOpenTransaction) { $0.donations.count >= 5 }
        
        /// Set on the menu that opens the color menu.
        /// Once the user has touched the color menu button, invalidate the tip.
        #Rule(Self.$didTouchColorChangeButton) { $0 == false }
    }
    
    var options: [Option] {
        MaxDisplayCount(1)
    }
}

