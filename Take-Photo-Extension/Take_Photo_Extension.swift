//
//  Take_Photo_Extension.swift
//  Take-Photo-Extension
//
//  Created by Cody Burnett on 11/3/25.
//

import WidgetKit
import SwiftUI
import AppIntents


struct AppIntentProvider: AppIntentTimelineProvider {
    typealias Entry = SimpleEntry
    typealias Intent = TakePhotoIntent
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    func snapshot(for configuration: TakePhotoIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    func timeline(for configuration: TakePhotoIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        return timeline
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}



// MARK: - Widget
struct Take_Photo_ExtensionEntryView : View {
    var entry: AppIntentProvider.Entry

    var body: some View {
        VStack {
            Text("Capture Receipt")
                .multilineTextAlignment(.center)
            Image(systemName: "camera")
                .font(.largeTitle)
        }
        .widgetURL(URL(string: "applinks://details?action=take_photo"))
        .containerBackground(.background, for: .widget)
    }
}

struct Take_Photo_Extension: Widget {
    let kind: String = "Take_Photo_Extension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: TakePhotoIntent.self, provider: AppIntentProvider()) { entry in
            Take_Photo_ExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Capture Receipt")
        .description("Take a photo of a receipt to create an expense.")
        .supportedFamilies([.systemSmall])
    }
}



struct TakePhotoIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Capture Receipt"
    static var description = IntentDescription("Take a photo of a receipt to create an expense.")

    func perform() async throws -> some IntentResult {
        return .result()
    }
}





// MARK: - Control Center
struct Take_Photo_Control_Widget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "TakePhotoControl") {
            ControlWidgetButton(action: TakePhotoControlIntent()) {
                Label("Take Photo", systemImage: "document.viewfinder.fill")
                    .font(.largeTitle)
            }
        }
    }
}


struct TakePhotoControlIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Item"
    static var description = IntentDescription("Select an item to display in the widget.")

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        return .result(opensIntent: OpenURLIntent(URL(string: "https://codyburnett.com/plaid_redirect/plaid-redirect.html?action=take_photo")!))
    }
}


