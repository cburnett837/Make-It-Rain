//
//  DashboardWidget.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

enum DashboardWidgetLayer {
    case one, two, three
}

struct Card<TitleContent: View, FooterContent: View, Content: View>: View {
    private let showFilterText: Bool
    private let title: String?
    private let footer: String?
    private let titleContent: TitleContent
    private let footerContent: FooterContent
    private let content: Content
    private let color: Color
    private let layer: DashboardWidgetLayer?
    
    private static var defaultColor: Color {
        #if os(iOS)
        Color(.secondarySystemGroupedBackground)
        #else
        Color(.tertiarySystemFill)
        #endif
    }
    
    
    private var defaultColor: Color {
        switch layer {
        case .one:
            #if os(iOS)
            Color(.secondarySystemGroupedBackground)
            #else
            Color(.tertiarySystemFill)
            #endif
        case .two:            
            #if os(iOS)
            Color(.tertiarySystemGroupedBackground)
            #else
            Color(.tertiarySystemFill)
            #endif
        case .three:
            Color(.quaternarySystemFill)
        case nil:
            color
        }
    }

    init(
        showFilterText: Bool = false,
        layer: DashboardWidgetLayer = .one,
        color: Color = Self.defaultColor,
        title: String,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) where TitleContent == EmptyView, FooterContent == EmptyView {
        self.showFilterText = showFilterText
        self.layer = layer
        self.color = color
        self.title = title
        self.footer = footer
        self.titleContent = EmptyView()
        self.footerContent = EmptyView()
        self.content = content()
    }

    init(
        showFilterText: Bool = false,
        layer: DashboardWidgetLayer = .one,
        color: Color = Self.defaultColor,
        @ViewBuilder title: () -> TitleContent,
        @ViewBuilder footer: () -> FooterContent,
        @ViewBuilder content: () -> Content
    ) {
        self.showFilterText = showFilterText
        self.layer = layer
        self.color = color
        self.title = nil
        self.footer = nil
        self.footerContent = footer()
        self.titleContent = title()
        self.content = content()
    }
    
    init(
        showFilterText: Bool = false,
        layer: DashboardWidgetLayer = .one,
        color: Color = Self.defaultColor,
        @ViewBuilder title: () -> TitleContent,
        @ViewBuilder content: () -> Content
    ) where FooterContent == EmptyView {
        self.showFilterText = showFilterText
        self.layer = layer
        self.color = color
        self.title = nil
        self.footer = nil
        self.footerContent = EmptyView()
        self.titleContent = title()
        self.content = content()
    }

    init(
        showFilterText: Bool = false,
        layer: DashboardWidgetLayer = .one,
        color: Color = Self.defaultColor,
        @ViewBuilder content: () -> Content
    ) where TitleContent == EmptyView, FooterContent == EmptyView {
        self.showFilterText = showFilterText
        self.layer = layer
        self.color = color
        self.title = nil
        self.footer = nil
        self.footerContent = EmptyView()
        self.titleContent = EmptyView()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let title {
                    Text(title)
                        .padding(.leading, 12)
                        .foregroundStyle(.secondary)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                } else if !(TitleContent.self == EmptyView.self) {
                    titleContent
                }
                
                if showFilterText {
                    Spacer()
                    Text("(filtered)")
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 12)
                        .font(.caption)
                        .bold()
                        .italic()
                }
            }
            

            content
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(defaultColor)
                }
            
            
            if let footer {
                Text(footer)
                    .padding(.horizontal, 12)
                    .foregroundStyle(.secondary)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

            } else if !(FooterContent.self == EmptyView.self) {
                footerContent
                    .padding(.horizontal, 12)
            }
        }
    }
}
