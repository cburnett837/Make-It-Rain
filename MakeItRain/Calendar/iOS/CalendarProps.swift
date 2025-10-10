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
    var transEditID: String?
    var editTrans: CBTransaction?
    
    var overviewDay: CBDay?
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
    var showBudgetSheet = false
    var showAnalysisSheet = false
    var showTransactionListSheet = false
        
    /// For iPad
    //var showBudgetInspector = false
    //var showAnalysisInspector = false
    //var showTransactionListInspector = false
    var showInspector = false
    var inspectorContent: CalendarInspectorContent?
    
    var bottomPanelContent: BottomPanelContent?
                
    var findTransactionWhere = WhereToLookForTransaction.normalList
    
    var editLock = false
    
    var timeSinceLastBalanceUpdate: String = ""
    //var lastBalanceUpdateTimer: Timer?
}
