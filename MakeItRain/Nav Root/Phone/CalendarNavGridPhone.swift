//
//  CalendarNavGridPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/1/24.
//

import SwiftUI

#if os(iOS)
struct CalendarNavGridPhone: View {
    //@Local(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    
    @Binding var calendarNavPath: [NavDest]
    
    @State private var hasDoneInitialScrollToThisMonth = false
    
    var body: some View {
        let monthsByEnumID = Dictionary(uniqueKeysWithValues: calModel.months.map { ($0.enumID, $0) })

        VStack(spacing: 0) {
            CalendarNavGridHeader(calendarNavPath: $calendarNavPath)
                .scenePadding(.horizontal)
            
            ScrollViewReader { scrollProxy in
                ScrollView {
                    if AppState.shared.methsExist {
                        Grid {
                            GridRow(alignment: .top) {
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                if let month = monthsByEnumID[.lastDecember] { MonthNavigationLink(month: month) }
                            }
                            GridRow(alignment: .top) {
                                if let month = monthsByEnumID[.january] { MonthNavigationLink(month: month).id(1) }
                                if let month = monthsByEnumID[.february] { MonthNavigationLink(month: month).id(2) }
                                if let month = monthsByEnumID[.march] { MonthNavigationLink(month: month).id(3) }
                            }
                            GridRow(alignment: .top) {
                                if let month = monthsByEnumID[.april] { MonthNavigationLink(month: month).id(4) }
                                if let month = monthsByEnumID[.may] { MonthNavigationLink(month: month).id(5) }
                                if let month = monthsByEnumID[.june] { MonthNavigationLink(month: month).id(6) }
                            }
                            GridRow(alignment: .top) {
                                if let month = monthsByEnumID[.july] { MonthNavigationLink(month: month).id(7) }
                                if let month = monthsByEnumID[.august] { MonthNavigationLink(month: month).id(8) }
                                if let month = monthsByEnumID[.september] { MonthNavigationLink(month: month).id(9) }
                            }
                            GridRow(alignment: .top) {
                                if let month = monthsByEnumID[.october] { MonthNavigationLink(month: month).id(10) }
                                if let month = monthsByEnumID[.november] { MonthNavigationLink(month: month).id(11) }
                                if let month = monthsByEnumID[.december] { MonthNavigationLink(month: month).id(12) }
                            }
                            GridRow(alignment: .top) {
                                if let month = monthsByEnumID[.nextJanuary] { MonthNavigationLink(month: month) }
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                            }
                        }
                        
                        
//                        Grid {
//                            GridRow(alignment: .top) {
//                                if let month = monthsByEnumID[.lastDecember] { MonthNavigationLink(month: month).id(month.num) }
//                                if let month = monthsByEnumID[.january] { MonthNavigationLink(month: month).id(month.num) }
//                            }
//                            GridRow(alignment: .top) {
//                                if let month = monthsByEnumID[.february] { MonthNavigationLink(month: month).id(month.num) }
//                                if let month = monthsByEnumID[.march] { MonthNavigationLink(month: month).id(month.num) }
//                            }
//                            GridRow(alignment: .top) {
//                                if let month = monthsByEnumID[.april] { MonthNavigationLink(month: month).id(month.num) }
//                                if let month = monthsByEnumID[.may] { MonthNavigationLink(month: month).id(month.num) }
//                            }
//                            GridRow(alignment: .top) {
//                                if let month = monthsByEnumID[.june] { MonthNavigationLink(month: month).id(month.num) }
//                                if let month = monthsByEnumID[.july] { MonthNavigationLink(month: month).id(month.num) }
//                            }
//                            GridRow(alignment: .top) {
//                                if let month = monthsByEnumID[.august] { MonthNavigationLink(month: month).id(month.num) }
//                                if let month = monthsByEnumID[.september] { MonthNavigationLink(month: month).id(month.num) }
//                            }
//                            GridRow(alignment: .top) {
//                                if let month = monthsByEnumID[.october] { MonthNavigationLink(month: month).id(month.num) }
//                                if let month = monthsByEnumID[.november] { MonthNavigationLink(month: month).id(month.num) }
//                            }
//                            GridRow(alignment: .top) {
//                                if let month = monthsByEnumID[.december] { MonthNavigationLink(month: month).id(month.num) }
//                                if let month = monthsByEnumID[.nextJanuary] { MonthNavigationLink(month: month).id(month.num) }
//                            }                            
//                        }
                    }
                }
                .contentMargins(.horizontal, 15, for: .scrollContent)
                .onAppear { scrollToThisMonthOnAppearOfScrollView(scrollProxy) }
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    func scrollToThisMonthOnAppearOfScrollView(_ proxy: ScrollViewProxy) {
        if !hasDoneInitialScrollToThisMonth {
            hasDoneInitialScrollToThisMonth = true
            //DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                //withAnimation {
                    proxy.scrollTo(AppState.shared.todayMonth, anchor: .center)
                //}
            //}
        }
    }
}
#endif


//
////
////  CalendarNavGridPhone.swift
////  MakeItRain
////
//import SwiftUI
//import UIKit
//
//#if os(iOS)
//
//struct CalendarNavGridPhone: View {
//    @Environment(CalendarModel.self) var calModel
//    @Binding var calendarNavPath: NavigationPath
//
//    @State private var hasDoneInitialScrollToThisMonth = false
//    @State private var blinkMonth: NavDest?
//
//    private let tileHeight: CGFloat = 164
//    private let rowHeight: CGFloat = 20
//
//    var body: some View {
//        let monthsByEnumID = Dictionary(uniqueKeysWithValues: calModel.months.map { ($0.enumID, $0) })
//        let months = makeRenderMonths(monthsByEnumID: monthsByEnumID)
//
//        VStack(spacing: 0) {
//            CalendarNavGridHeader(calendarNavPath: $calendarNavPath)
//                .scenePadding(.horizontal)
//
//            ScrollViewReader { proxy in
//                ScrollView {
//                    if AppState.shared.methsExist {
//                        ZStack(alignment: .topLeading) {
//                            CalendarYearGridUIKit(
//                                months: months,
//                                selectedMonth: NavigationManager.shared.selectedMonth,
//                                blinkMonth: blinkMonth,
//                                themeColor: UIColor(Color.theme),
//                                tileHeight: tileHeight,
//                                rowHeight: rowHeight
//                            )
//                            .frame(height: tileHeight * 6)
//
//                            interactionGrid(monthsByEnumID: monthsByEnumID)
//                        }
//                        .frame(height: tileHeight * 6)
//                    }
//                }
//                .contentMargins(.horizontal, 15, for: .scrollContent)
//                .onAppear {
//                    scrollToThisMonthOnAppearOfScrollView(proxy)
//                }
//            }
//            .scrollEdgeEffectStyle(.soft, for: .top)
//        }
//        .frame(maxWidth: .infinity)
//        .navigationTitle("")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//
//    @ViewBuilder
//    private func interactionGrid(monthsByEnumID: [NavDest: CBMonth]) -> some View {
//        VStack(spacing: 0) {
//            hitTargetRow([nil, nil, monthsByEnumID[.lastDecember]])
//
//            hitTargetRow([
//                monthsByEnumID[.january],
//                monthsByEnumID[.february],
//                monthsByEnumID[.march]
//            ])
//
//            hitTargetRow([
//                monthsByEnumID[.april],
//                monthsByEnumID[.may],
//                monthsByEnumID[.june]
//            ])
//
//            hitTargetRow([
//                monthsByEnumID[.july],
//                monthsByEnumID[.august],
//                monthsByEnumID[.september]
//            ])
//
//            hitTargetRow([
//                monthsByEnumID[.october],
//                monthsByEnumID[.november],
//                monthsByEnumID[.december]
//            ])
//
//            hitTargetRow([
//                monthsByEnumID[.nextJanuary],
//                nil,
//                nil
//            ])
//        }
//    }
//
//    private func hitTargetRow(_ months: [CBMonth?]) -> some View {
//        HStack(spacing: 0) {
//            ForEach(0..<3, id: \.self) { index in
//                if let month = months[index] {
//                    monthHitTarget(month)
//                } else {
//                    Color.clear
//                        .frame(maxWidth: .infinity)
//                        .frame(height: tileHeight)
//                }
//            }
//        }
//        .frame(height: tileHeight)
//    }
//
//    private func monthHitTarget(_ month: CBMonth) -> some View {
//        Color.clear
//            .contentShape(Rectangle())
//            .frame(maxWidth: .infinity)
//            .frame(height: tileHeight)
//            .id(month.actualNum)
//            .onTapGesture {
//                navigateToMonth(month)
//            }
//            .dropDestination(for: CBTransaction.self) { _, _ in
//                AppState.shared.dragMonthTarget = nil
//                blinkMonth = nil
//                return true
//            } isTargeted: { targeted in
//                if targeted {
//                    monthIsDragTargeted(month)
//                } else {
//                    AppState.shared.dragOnMonthTimer?.invalidate()
//
//                    if blinkMonth == month.enumID {
//                        blinkMonth = nil
//                    }
//                }
//            }
//            .accessibilityElement()
//            .accessibilityLabel(month.abbreviatedName)
//            .accessibilityAddTraits(.isButton)
//    }
//
//    private func navigateToMonth(_ month: CBMonth) {
//        NavigationManager.shared.selectedMonth = month.enumID
//        NavigationManager.shared.selection = nil
//
//        if AppState.shared.isIphone {
//            calModel.showMonth = true
//        }
//    }
//
//    private func monthIsDragTargeted(_ month: CBMonth) {
//        AppState.shared.dragOnMonthTimer?.invalidate()
//
//        AppState.shared.dragOnMonthTimer = Timer(
//            fire: Date.now.addingTimeInterval(1),
//            interval: 0,
//            repeats: false
//        ) { _ in
//            Task { @MainActor in
//                withAnimation(.easeInOut(duration: 0.1).repeatCount(2)) {
//                    blinkMonth = month.enumID
//                } completion: {
//                    AppState.shared.dragMonthTarget = month.enumID
//                    NavigationManager.shared.selectedMonth = month.enumID
//                    blinkMonth = nil
//                }
//            }
//        }
//
//        if let timer = AppState.shared.dragOnMonthTimer {
//            RunLoop.main.add(timer, forMode: .common)
//        }
//    }
//
//    private func scrollToThisMonthOnAppearOfScrollView(_ proxy: ScrollViewProxy) {
//        guard !hasDoneInitialScrollToThisMonth else { return }
//
//        hasDoneInitialScrollToThisMonth = true
//        proxy.scrollTo(AppState.shared.todayMonth, anchor: .center)
//    }
//
//    private func makeRenderMonths(monthsByEnumID: [NavDest: CBMonth]) -> [CalendarYearGridUIView.Month] {
//        let positions: [(NavDest, Int, Int)] = [
//            (.lastDecember, 0, 2),
//            (.january, 1, 0),
//            (.february, 1, 1),
//            (.march, 1, 2),
//            (.april, 2, 0),
//            (.may, 2, 1),
//            (.june, 2, 2),
//            (.july, 3, 0),
//            (.august, 3, 1),
//            (.september, 3, 2),
//            (.october, 4, 0),
//            (.november, 4, 1),
//            (.december, 4, 2),
//            (.nextJanuary, 5, 0)
//        ]
//
//        return positions.compactMap { enumID, row, column in
//            guard let month = monthsByEnumID[enumID] else { return nil }
//
//            let title: String
//
//            if calModel.isPlayground {
//                if enumID == .lastDecember {
//                    title = "Last \(month.abbreviatedName)"
//                } else if enumID == .nextJanuary {
//                    title = "Next \(month.abbreviatedName)"
//                } else {
//                    title = month.abbreviatedName
//                }
//            } else {
//                if enumID == .lastDecember || enumID == .nextJanuary {
//                    title = "\(month.abbreviatedName) \(month.year)"
//                } else {
//                    title = month.abbreviatedName
//                }
//            }
//
//            let isCurrentMonth =
//                month.actualNum == AppState.shared.todayMonth &&
//                month.year == AppState.shared.todayYear
//
//            let days = month.days.map {
//                CalendarYearGridUIView.Day(
//                    number: $0.id,
//                    isPlaceholder: $0.isPlaceholder,
//                    isToday: isCurrentMonth && $0.id == AppState.shared.todayDay
//                )
//            }
//
//            return CalendarYearGridUIView.Month(
//                enumID: enumID,
//                title: title,
//                row: row,
//                column: column,
//                isCurrentMonth: isCurrentMonth,
//                days: days
//            )
//        }
//    }
//}
//
//final class CalendarYearGridUIView: UIView {
//    struct Day: Equatable {
//        let number: Int
//        let isPlaceholder: Bool
//        let isToday: Bool
//    }
//
//    struct Month: Equatable {
//        let enumID: NavDest
//        let title: String
//        let row: Int
//        let column: Int
//        let isCurrentMonth: Bool
//        let days: [Day]
//    }
//
//    private var months: [Month] = []
//    private var selectedMonth: NavDest?
//    private var blinkMonth: NavDest?
//
//    private var themeColor: UIColor = .systemBlue
//    private var tileHeight: CGFloat = 164
//    private var rowHeight: CGFloat = 20
//
//    private var titleFont = UIFont.preferredFont(forTextStyle: .title3)
//    private var dayFont = UIFont.preferredFont(forTextStyle: .caption2)
//    private var todayFont = UIFont.boldSystemFont(
//        ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize
//    )
//
//    private var dayStrings: [NSString] = []
//    private var daySizes: [CGSize] = []
//    private var todaySizes: [CGSize] = []
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//
//        backgroundColor = .clear
//        isOpaque = false
//        isUserInteractionEnabled = false
//
//        rebuildTextCache()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func update(
//        months: [Month],
//        selectedMonth: NavDest?,
//        blinkMonth: NavDest?,
//        themeColor: UIColor,
//        tileHeight: CGFloat,
//        rowHeight: CGFloat
//    ) {
//        var needsRedraw = false
//
//        if self.months != months {
//            self.months = months
//            needsRedraw = true
//        }
//
//        if self.selectedMonth != selectedMonth {
//            self.selectedMonth = selectedMonth
//            needsRedraw = true
//        }
//
//        if self.blinkMonth != blinkMonth {
//            self.blinkMonth = blinkMonth
//            needsRedraw = true
//        }
//
//        if !self.themeColor.isEqual(themeColor) {
//            self.themeColor = themeColor
//            needsRedraw = true
//        }
//
//        if self.tileHeight != tileHeight {
//            self.tileHeight = tileHeight
//            needsRedraw = true
//        }
//
//        if self.rowHeight != rowHeight {
//            self.rowHeight = rowHeight
//            needsRedraw = true
//        }
//
//        if needsRedraw {
//            setNeedsDisplay()
//        }
//    }
//
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//
//        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else {
//            return
//        }
//
//        rebuildTextCache()
//        setNeedsDisplay()
//    }
//
//    private func rebuildTextCache() {
//        titleFont = UIFont.boldSystemFont(
//            ofSize: UIFont.preferredFont(
//                forTextStyle: .title3,
//                compatibleWith: traitCollection
//            ).pointSize
//        )
//
//        dayFont = UIFont.preferredFont(
//            forTextStyle: .caption2,
//            compatibleWith: traitCollection
//        )
//
//        todayFont = UIFont.boldSystemFont(ofSize: dayFont.pointSize)
//
//        dayStrings = (0...31).map { NSString(string: String($0)) }
//
//        let normalAttributes: [NSAttributedString.Key: Any] = [
//            .font: dayFont
//        ]
//
//        let todayAttributes: [NSAttributedString.Key: Any] = [
//            .font: todayFont
//        ]
//
//        daySizes = dayStrings.map {
//            $0.size(withAttributes: normalAttributes)
//        }
//
//        todaySizes = dayStrings.map {
//            $0.size(withAttributes: todayAttributes)
//        }
//    }
//
//    override func draw(_ rect: CGRect) {
//        guard bounds.width > 0, !months.isEmpty else { return }
//
//        let tileWidth = bounds.width / 3
//        let normalColor = UIColor.label
//        let selectedColor = UIColor.tertiarySystemFill
//
//        let normalDayAttributes: [NSAttributedString.Key: Any] = [
//            .font: dayFont,
//            .foregroundColor: normalColor
//        ]
//
//        let todayDayAttributes: [NSAttributedString.Key: Any] = [
//            .font: todayFont,
//            .foregroundColor: themeColor
//        ]
//
//        let normalTitleAttributes: [NSAttributedString.Key: Any] = [
//            .font: titleFont,
//            .foregroundColor: normalColor
//        ]
//
//        let currentTitleAttributes: [NSAttributedString.Key: Any] = [
//            .font: titleFont,
//            .foregroundColor: themeColor
//        ]
//
//        for month in months {
//            let tileRect = CGRect(
//                x: CGFloat(month.column) * tileWidth,
//                y: CGFloat(month.row) * tileHeight,
//                width: tileWidth,
//                height: tileHeight
//            )
//
//            if blinkMonth == month.enumID {
//                let path = UIBezierPath(
//                    roundedRect: tileRect.insetBy(dx: 4, dy: 4),
//                    cornerRadius: 15
//                )
//
//                themeColor.setFill()
//                path.fill()
//            } else if selectedMonth == month.enumID {
//                let path = UIBezierPath(
//                    roundedRect: tileRect.insetBy(dx: 4, dy: 4),
//                    cornerRadius: 15
//                )
//
//                selectedColor.setFill()
//                path.fill()
//            }
//
//            let title = month.title as NSString
//
//            title.draw(
//                at: CGPoint(x: tileRect.minX + 4, y: tileRect.minY + 4),
//                withAttributes: month.isCurrentMonth
//                    ? currentTitleAttributes
//                    : normalTitleAttributes
//            )
//
//            let daysStartY = tileRect.minY + 4 + titleFont.lineHeight + 8
//            let usableWidth = tileWidth - 8
//            let columnWidth = usableWidth / 7
//            let daysX = tileRect.minX + 4
//
//            for index in 0..<min(month.days.count, 42) {
//                let day = month.days[index]
//
//                guard
//                    !day.isPlaceholder,
//                    day.number >= 0,
//                    day.number < dayStrings.count
//                else {
//                    continue
//                }
//
//                let row = index / 7
//                let column = index % 7
//
//                let string = dayStrings[day.number]
//                let textSize = day.isToday
//                    ? todaySizes[day.number]
//                    : daySizes[day.number]
//
//                let x =
//                    daysX +
//                    CGFloat(column) * columnWidth +
//                    (columnWidth - textSize.width) / 2
//
//                let y =
//                    daysStartY +
//                    CGFloat(row) * rowHeight +
//                    (rowHeight - 4 - textSize.height) / 2
//
//                string.draw(
//                    at: CGPoint(x: x, y: y),
//                    withAttributes: day.isToday
//                        ? todayDayAttributes
//                        : normalDayAttributes
//                )
//            }
//        }
//    }
//}
//
//struct CalendarYearGridUIKit: UIViewRepresentable {
//    let months: [CalendarYearGridUIView.Month]
//    let selectedMonth: NavDest?
//    let blinkMonth: NavDest?
//    let themeColor: UIColor
//    let tileHeight: CGFloat
//    let rowHeight: CGFloat
//
//    func makeUIView(context: Context) -> CalendarYearGridUIView {
//        let view = CalendarYearGridUIView(frame: .zero)
//
//        view.update(
//            months: months,
//            selectedMonth: selectedMonth,
//            blinkMonth: blinkMonth,
//            themeColor: themeColor,
//            tileHeight: tileHeight,
//            rowHeight: rowHeight
//        )
//
//        return view
//    }
//
//    func updateUIView(_ uiView: CalendarYearGridUIView, context: Context) {
//        uiView.update(
//            months: months,
//            selectedMonth: selectedMonth,
//            blinkMonth: blinkMonth,
//            themeColor: themeColor,
//            tileHeight: tileHeight,
//            rowHeight: rowHeight
//        )
//    }
//
//    func sizeThatFits(
//        _ proposal: ProposedViewSize,
//        uiView: CalendarYearGridUIView,
//        context: Context
//    ) -> CGSize? {
//        guard let width = proposal.width, width.isFinite, width > 0 else {
//            return nil
//        }
//
//        return CGSize(
//            width: width,
//            height: tileHeight * 6
//        )
//    }
//}
//
//#endif
