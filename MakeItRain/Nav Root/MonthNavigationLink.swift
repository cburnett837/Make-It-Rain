//
//  MonthNavigationLink.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/5/25.
//


import SwiftUI
import UIKit

struct MonthNavigationLink: View {
    @Environment(CalendarModel.self) var calModel
    
    //@Local(\.colorTheme) var colorTheme
    let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .top), count: 7)
    
    @State private var blinkView = false
    @State private var blinkTimer: Timer?
    
//    var enumID: NavDest
//    
//    var month: CBMonth {
//        calModel.months.filter { $0.enumID == enumID }.first!
//    }
    
    // Before
//    var enumID: NavDest
//
//    var month: CBMonth {
//        calModel.months.filter { $0.enumID == enumID }.first!
//    }

    // After
    let month: CBMonth

//    var enumID: NavDest {
//        month.enumID
//    }
    
    var monthTitle: String {
        if calModel.isPlayground {
            if month.enumID == .lastDecember {
                "Last \(month.abbreviatedName)"
            } else if month.enumID == .nextJanuary {
                "Next \(month.abbreviatedName)"
            } else {
                month.abbreviatedName
            }
        } else {
            if month.enumID == .lastDecember || month.enumID == .nextJanuary {
                "\(month.abbreviatedName) \(String(month.year))"
            } else {
                month.abbreviatedName
            }
        }
    }
            
    var body: some View {
        VStack(alignment: .leading) {
            monthName
            monthDayGrid
        }
        .contentShape(.rect)
        //.matchedTransitionSource(id: month.enumID, in: monthNavigationNamespace)
        
        .padding(.bottom, 10)
        .buttonStyle(.plain)
        .padding(4)
        /// Make sure all buttons are the same height, regardless of the amount of weekly rows in the month
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(blinkView
                      ? Color.theme
                      : NavigationManager.shared.selectedMonth == month.enumID
                      ? Color(.tertiarySystemFill)
                      : Color.clear
                )
        )
        
        .onTapGesture {
            //print("SourceID: \(month.enumID)")
            navigateToMonth()
        }
        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
            AppState.shared.dragMonthTarget = nil
            return true
        } isTargeted: {
            if $0 {
                monthIsDragTargeted()
            } else {
                AppState.shared.dragOnMonthTimer?.invalidate()
            }
        }
    }
    
    
    var monthName: some View {
        Text(monthTitle)
            .font(.title3)
            .bold()
            .foregroundStyle(
                AppState.shared.todayMonth == month.actualNum && AppState.shared.todayYear == month.year
                ? Color.theme
                : Color.primary
            )
    }
    
    
    
    
    @ViewBuilder
    var monthDayGrid: some View {
        /// NOTE:
        /// The native SwiftUI code causes a ~300ms hang when rendering. That can cause the calendar "scroll to today" animation to tweak.
        /// This UIKit bridge cuts that down to a ~150ms hang. Not perfect, but much better.
        let days = month.days.map { day in
            MonthDayGridUIView.Day(
                number: day.id,
                isPlaceholder: day.isPlaceholder,
                isToday:
                    month.actualNum == AppState.shared.todayMonth &&
                    month.year == AppState.shared.todayYear &&
                    day.id == AppState.shared.todayDay
            )
        }

        MonthDayGridUIKit(days: days, themeColor: UIColor(Color.theme))
        
        
//        LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
//            ForEach(month.days) { day in
//                let isToday =
//                    month.actualNum == AppState.shared.todayMonth &&
//                    month.year == AppState.shared.todayYear &&
//                    day.id == AppState.shared.todayDay
//
//                //Text("\(day.dateComponents?.day ?? 0)")
//                Text("\(day.id)")
//                    .lineLimit(1)
//                    .font(.caption2)
//                    .bold(isToday)
//                    .foregroundStyle(isToday ? Color.theme : .primary)
//                    .padding(.bottom, 4)
//                    .opacity(day.isPlaceholder ? 0 : 1)
//                    .fixedSize()
//            }
//        }
    }
//    var monthDayGrid: some View {
//        LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
//            ForEach(month.days) { day in
//                let isToday =
//                    month.actualNum == AppState.shared.todayMonth &&
//                    month.year == AppState.shared.todayYear &&
//                    day.id == AppState.shared.todayDay
//                
//                //Text("\(day.dateComponents?.day ?? 0)")
//                Text("\(day.id)")
//                    .lineLimit(1)
//                    .font(.caption2)
//                    .bold(isToday)
//                    .foregroundStyle(isToday ? Color.theme : .primary)
//                    .padding(.bottom, 4)
//                    .opacity(day.isPlaceholder ? 0 : 1)
//                    .fixedSize()
//            }
//        }
//    }
//    
    
    func navigateToMonth() {
        NavigationManager.shared.selectedMonth = month.enumID
        NavigationManager.shared.selection = nil
        
//        Task {
//            calModel.setSelectedMonthFromNavigation(navID: month.enumID, calculateStartingAndEod: true, shouldLoadDashboard: true)
//        }
        
        #if os(iOS)
        /// This triggers the fullscreen cover in ``CalendarSheetLayerView`` to show.
        /// Since `NavigationManager.shared.selectedMonth` get's set above, the calendar sheet will show with the selected month.
        if AppState.shared.isIphone {
            calModel.showMonth = true
        }
        #endif
    }
    
    
    func monthIsDragTargeted() {
        AppState.shared.dragOnMonthTimer?.invalidate()
                        
        AppState.shared.dragOnMonthTimer = Timer(fire: Date.now.addingTimeInterval(1), interval: 0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.1).repeatCount(2)) {
                blinkView.toggle()
            } completion: {
                AppState.shared.dragMonthTarget = month.enumID
                NavigationManager.shared.selectedMonth = month.enumID
                blinkView = false
            }
        }
                                                
        if let dragOnMonthTimer = AppState.shared.dragOnMonthTimer {
            RunLoop.main.add(dragOnMonthTimer, forMode: .common)
        }
    }
}
//
//
//final class MonthDayGridUIView: UIView {
//    struct Day: Equatable {
//        let number: Int
//        let isPlaceholder: Bool
//        let isToday: Bool
//    }
//
//    var days: [Day] = [] {
//        didSet {
//            if oldValue != days {
//                setNeedsDisplay()
//            }
//        }
//    }
//
//    var themeColor: UIColor = .systemBlue {
//        didSet {
//            setNeedsDisplay()
//        }
//    }
//
//    var rowHeight: CGFloat = 20 {
//        didSet {
//            invalidateIntrinsicContentSize()
//            setNeedsDisplay()
//        }
//    }
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//
//        backgroundColor = .clear
//        isOpaque = false
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override var intrinsicContentSize: CGSize {
//        CGSize(width: UIView.noIntrinsicMetric, height: rowHeight * 6)
//    }
//
//    override func draw(_ rect: CGRect) {
//        guard !days.isEmpty else { return }
//
//        let columnWidth = bounds.width / 7
//
//        let normalFont = UIFont.preferredFont(forTextStyle: .caption2)
//        let boldFont = UIFont.boldSystemFont(ofSize: normalFont.pointSize)
//
//        for (index, day) in days.prefix(42).enumerated() {
//
//            guard !day.isPlaceholder else { continue }
//
//            let row = index / 7
//            let column = index % 7
//
//            let cellRect = CGRect(
//                x: CGFloat(column) * columnWidth,
//                y: CGFloat(row) * rowHeight,
//                width: columnWidth,
//                height: rowHeight - 4
//            )
//
//            let paragraph = NSMutableParagraphStyle()
//            paragraph.alignment = .center
//
//            let attributes: [NSAttributedString.Key: Any] = [
//                .font: day.isToday ? boldFont : normalFont,
//                .foregroundColor: day.isToday ? themeColor : UIColor.label,
//                .paragraphStyle: paragraph
//            ]
//
//            let text = String(day.number)
//
//            let textSize = text.size(withAttributes: attributes)
//
//            let textRect = CGRect(
//                x: cellRect.minX,
//                y: cellRect.midY - textSize.height / 2,
//                width: cellRect.width,
//                height: textSize.height
//            )
//
//            text.draw(in: textRect, withAttributes: attributes)
//        }
//    }
//}
//
//
//struct MonthDayGridUIKit: UIViewRepresentable {
//    let days: [MonthDayGridUIView.Day]
//    let themeColor: UIColor
//    var rowHeight: CGFloat = 20
//
//    func makeUIView(context: Context) -> MonthDayGridUIView {
//        let view = MonthDayGridUIView()
//        view.days = days
//        view.themeColor = themeColor
//        view.rowHeight = rowHeight
//        return view
//    }
//
//    func updateUIView(_ uiView: MonthDayGridUIView, context: Context) {
//        uiView.days = days
//        uiView.themeColor = themeColor
//        uiView.rowHeight = rowHeight
//    }
//
//    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MonthDayGridUIView, context: Context) -> CGSize? {
//        guard let width = proposal.width else {
//            return nil
//        }
//
//        return CGSize(width: width, height: uiView.rowHeight * 6)
//    }
//}
//
//
//




import SwiftUI
import UIKit

final class MonthDayGridUIView: UIView {

    struct Day: Equatable {
        let number: Int
        let isPlaceholder: Bool
        let isToday: Bool
    }

    // MARK: - Data

    private(set) var days: [Day] = []
    private(set) var themeColor: UIColor = .systemBlue
    private(set) var rowHeight: CGFloat = 20


    // MARK: - Cached Text Data

    private var normalFont: UIFont = .preferredFont(forTextStyle: .caption2)

    private var boldFont: UIFont = {
        let font = UIFont.preferredFont(forTextStyle: .caption2)
        return .boldSystemFont(ofSize: font.pointSize)
    }()

    /// Precomputed strings 0...31.
    ///
    /// NSString avoids repeatedly bridging String during drawing.
    private var dayStrings: [NSString] = []

    /// Width/height for normal font.
    private var normalSizes: [CGSize] = []

    /// Width/height for bold font.
    private var boldSizes: [CGSize] = []


    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false

        rebuildTextCache()
        
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: Self, _) in
            view.rebuildTextCache()
            view.invalidateIntrinsicContentSize()
            view.setNeedsDisplay()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Size

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: rowHeight * 6)
    }


    // MARK: - Updates

    func update(days newDays: [Day], themeColor newThemeColor: UIColor, rowHeight newRowHeight: CGFloat) {
        var needsRedraw = false

        if days != newDays {
            days = newDays
            needsRedraw = true
        }

        if !themeColor.isEqual(newThemeColor) {
            themeColor = newThemeColor
            needsRedraw = true
        }

        if rowHeight != newRowHeight {
            rowHeight = newRowHeight

            invalidateIntrinsicContentSize()

            needsRedraw = true
        }

        if needsRedraw {
            setNeedsDisplay()
        }
    }


    // MARK: - Dynamic Type

//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//
//        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else {
//            return
//        }
//
//        rebuildTextCache()
//
//        invalidateIntrinsicContentSize()
//        setNeedsDisplay()
//    }


    // MARK: - Cache

    private func rebuildTextCache() {
        normalFont = UIFont.preferredFont(forTextStyle: .caption2, compatibleWith: traitCollection)
        boldFont = UIFont.boldSystemFont(ofSize: normalFont.pointSize)
        dayStrings = (0...31).map { NSString(string: String($0)) }

        let normalAttributes: [NSAttributedString.Key: Any] = [.font: normalFont]
        let boldAttributes: [NSAttributedString.Key: Any] = [.font: boldFont]

        normalSizes = dayStrings.map { $0.size(withAttributes: normalAttributes) }
        boldSizes = dayStrings.map { $0.size(withAttributes: boldAttributes) }
    }


    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard !days.isEmpty, bounds.width > 0 else {
            return
        }

        let columnWidth = bounds.width / 7
        let normalAttributes: [NSAttributedString.Key: Any] = [.font: normalFont, .foregroundColor: UIColor.label]
        let todayAttributes: [NSAttributedString.Key: Any] = [.font: boldFont, .foregroundColor: themeColor]
        let count = min(days.count, 42)

        for index in 0..<count {
            let day = days[index]

            guard
                !day.isPlaceholder,
                day.number >= 0,
                day.number < dayStrings.count
            else {
                continue
            }

            let row = index / 7
            let column = index % 7
            let text = dayStrings[day.number]
            let textSize = day.isToday ? boldSizes[day.number] : normalSizes[day.number]
            let availableHeight = rowHeight - 4

            let x = CGFloat(column) * columnWidth + (columnWidth - textSize.width) * 0.5
            let y = CGFloat(row) * rowHeight + (availableHeight - textSize.height) * 0.5

            text.draw(at: CGPoint(x: x, y: y), withAttributes: day.isToday ? todayAttributes : normalAttributes)
        }
    }
}


struct MonthDayGridUIKit: UIViewRepresentable {
    let days: [MonthDayGridUIView.Day]
    let themeColor: UIColor
    var rowHeight: CGFloat = 20

    func makeUIView(context: Context) -> MonthDayGridUIView {
        let view = MonthDayGridUIView(frame: .zero)
        view.update(days: days, themeColor: themeColor, rowHeight: rowHeight)
        return view
    }

    func updateUIView(_ uiView: MonthDayGridUIView, context: Context) {
        uiView.update(days: days, themeColor: themeColor, rowHeight: rowHeight)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MonthDayGridUIView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite else {
            return nil
        }

        return CGSize(width: width, height: rowHeight * 6)
    }
}
