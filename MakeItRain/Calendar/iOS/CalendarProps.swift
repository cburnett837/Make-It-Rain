//
//  CalendarProps.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/3/25.
//


import SwiftUI

@Observable
class CalendarProps {
    var selectedDay: CBDay?
    var overviewDay: CBDay?
    
    var transEditID: String?
    var editTrans: CBTransaction?
    
    
    var selectedDayID: CBDay.ID?
    var overviewDayID: CBDay.ID?
    var defaultDay: CBDay?
    
    //var scrollHeight: CGFloat = 0
    //var bottomPanelHeight: CGFloat = 300
    //var scrollContentMargins: CGFloat = 300
    //@State private var scrollPosition = ScrollPosition(idType: CBDay.ID.self)
    
    var showTransferSheet = false
    var showPayMethodSheet = false
    var showCategorySheet = false
    var showCalendarOptionsSheet = false
    var showPhotosPicker = false
    var showCamera = false
    var showSideBar = false
    
    /// For iPhone
    var showDashboardSheet = false
    var showBudgetSheet = false
    var showAnalysisSheet = false
    var showTransactionListSheet = false
    ///
        
    /// For iPad
    var showInspector = false
    var inspectorContent: CalendarInspectorContent?
    ///
    
    var navPath = NavigationPath()
    
    var bottomPanelContent: BottomPanelContent?
                
    var findTransactionWhere = WhereToLookForTransaction.normalList
    
    var timeSinceLastBalanceUpdate: String = ""
    //var lastBalanceUpdateTimer: Timer?
}
