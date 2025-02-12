//
//  Extensions+Date.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import Foundation
extension Date {
    func string(to format: DateFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = getDateFormat(format)
        dateFormatter.timeZone = .none
        let format = dateFormatter.string(from: self)
        return format
    }
    
    func convert(from: DateFormat, to: DateFormat) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = getDateFormat(from)
        dateFormatter.timeZone = .none
        let string = dateFormatter.string(from: self)
        let date = dateFormatter.date(from: string)
        
        dateFormatter.dateFormat = getDateFormat(to)
        dateFormatter.timeZone = .none
        let resultString = dateFormatter.string(from: date!)
        let date2 = dateFormatter.date(from: resultString)
        return date2!
    }
    
//    var startOfDay: Date {
//        return Calendar.current.startOfDay(for: self)
//    }
//    
//    var endOfDay: Date {
//        var components = DateComponents()
//        components.day = 1
//        components.second = -1
//        return Calendar.current.date(byAdding: components, to: startOfDay)!
//    }
//
//    public var startOfQuarter: Date {
//        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
//
//        var components = Calendar.current.dateComponents([.month, .day, .year], from: startOfMonth)
//
//        let newMonth: Int
//        switch components.month! {
//        case 1,2,3: newMonth = 1
//        case 4,5,6: newMonth = 4
//        case 7,8,9: newMonth = 7
//        case 10,11,12: newMonth = 10
//        default: newMonth = 1
//        }
//        components.month = newMonth
//        return Calendar.current.date(from: components)!
//    }
    
    public var month: Int {
        return Calendar.current.dateComponents([.month], from: self).month!
    }
    
    public var day: Int {
        return Calendar.current.dateComponents([.day], from: self).day!
    }
    
    public var year: Int {
        return Calendar.current.dateComponents([.year], from: self).year!
    }
    
//    func getAllDates() -> [Date] {
//        let calendar = Calendar.current
//        
//        // Get first day of month
//        let startDate = calendar.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
//        
//        // Create range for days(Ints) in month, starting with startDate
//        let range = calendar.range(of: .day, in: .month, for: startDate)!
//        
//        // Array of dates, starting with 1nd day of month (hence day - 1)
//        // Index based, so first of month == 0
//        let dates = range.compactMap({ day -> Date in
//            return calendar.date(byAdding: .day, value: day - 1, to: startDate)!
//        })
//        
//        return dates
//    }

    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
        
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}





extension String {
    func formatServerDateTime(_ format: DateFormat = .date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y-MM-dd H:mm:ss"
        dateFormatter.timeZone = .none
        
        if let date = dateFormatter.date(from: self) {
            dateFormatter.dateFormat = getDateFormat(format)
            return dateFormatter.string(from: date)
        }
        return "-"
    }
        
    func formatAsDate(to: DateFormat, from: DateFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = getDateFormat(from)
        dateFormatter.timeZone = .none
        
        if let date = dateFormatter.date(from: self) {
            dateFormatter.dateFormat = getDateFormat(to)
            return dateFormatter.string(from: date)
        }
        return "-"
    }
    
    func toDateObj(from format: DateFormat) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = getDateFormat(format)
        dateFormatter.timeZone = .none
        //dateFormatter.dateFormat = "y-MM-dd H:mm:ss.SSS"
        //print("inside toDateObj")
        //print("Date inside obj func \(self)")
        
        //let date = dateFormatter.date(from: self)!
        //let string = dateFormatter.string(from: date)
        //dateFormatter.dateFormat = getDateFormat(format)
        //return dateFormatter.date(from: string)
        
        
        if let date = dateFormatter.date(from: self) {
            let string = dateFormatter.string(from: date)
            dateFormatter.dateFormat = getDateFormat(format)
            return dateFormatter.date(from: string)
            
        }
        return nil
    }
   
    func isToday() -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y-MM-dd H:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = dateFormatter.date(from: self) {
            dateFormatter.timeZone = TimeZone.current
            return Calendar.current.isDateInToday(date)
        }
        return false
        
    }
}








enum DateFormat {
    case date,
    dateTime,
    dateTimeShort,
    dateTimeNoYear,
    monthDayHrMinAmPm,
    monthDayYearHrMinAmPm,
    dateTimeTodayOrNot,
    timeAmPm,
    serverDateTime,
    serverDate,
    monthDay,
    monthDayShortYear,
    swiftDefault,
    datePickerDateOnlyDefault
}

func getDateFormat(_ format: DateFormat) -> String {
    switch format {
    case .date:                 return "MM/dd/yyyy"
    case .dateTime:             return "MM/dd/YY h:mm:ss"
    case .dateTimeShort:        return "MM/dd h:mm"
    case .dateTimeNoYear:       return "MM/dd h:mm:ss"
    case .monthDayHrMinAmPm:    return "MM/dd h:mm a"
    case .monthDayYearHrMinAmPm:return "MM/dd/YY h:mm a"
    case .timeAmPm:             return "h:mm a"
    case .serverDate:           return "y-MM-dd"
    case .serverDateTime:       return "y-MM-dd H:mm:ss"
    case .dateTimeTodayOrNot:   return ""
    case .monthDay:             return "MM/dd"
    case .monthDayShortYear:    return "MM/dd/YY"
    case .swiftDefault:         return "y-MM-dd H:mm:ss z"
    case .datePickerDateOnlyDefault:    return "MMM dd, yyyy"
    }
}
