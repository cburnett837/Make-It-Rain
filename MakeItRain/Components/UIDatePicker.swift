//
//  UIDatePicker.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/31/25.
//

import Foundation
import SwiftUI
#if os(iOS)
struct UIKitDatePicker: UIViewRepresentable {
    @Binding var date: Date?
    var alignment: UIControl.ContentHorizontalAlignment
    //var range: ClosedRange<Date>

    func makeUIView(context: Context) -> UIDatePicker {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.contentHorizontalAlignment = alignment
        datePicker.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        //datePicker.minimumDate = range.lowerBound
        //datePicker.maximumDate = range.upperBound
        return datePicker
    }

    func updateUIView(_ datePicker: UIDatePicker, context: Context) {
        datePicker.date = date ?? Date()
    }

    func makeCoordinator() -> UIKitDatePicker.Coordinator {
        Coordinator(date: $date)
    }

    class Coordinator: NSObject {
        private let date: Binding<Date?>

        init(date: Binding<Date?>) {
            self.date = date
        }

        @objc func changed(_ sender: UIDatePicker) {
            self.date.wrappedValue = sender.date
        }
    }
}
#endif
