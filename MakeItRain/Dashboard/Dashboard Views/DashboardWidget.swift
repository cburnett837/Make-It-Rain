//
//  DashboardWidget.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardWidget<TitleContent: View, FooterContent: View, Content: View>: View {
    private let showFilterText: Bool
    private let title: String?
    private let footer: String?
    private let titleContent: TitleContent
    private let footerContent: FooterContent
    private let content: Content

    init(
        showFilterText: Bool = false,
        title: String,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) where TitleContent == EmptyView, FooterContent == EmptyView {
        self.showFilterText = showFilterText
        self.title = title
        self.footer = footer
        self.titleContent = EmptyView()
        self.footerContent = EmptyView()
        self.content = content()
    }

    init(
        showFilterText: Bool = false,
        @ViewBuilder title: () -> TitleContent,
        @ViewBuilder footer: () -> FooterContent,
        @ViewBuilder content: () -> Content
    ) {
        self.showFilterText = showFilterText
        self.title = nil
        self.footer = nil
        self.footerContent = footer()
        self.titleContent = title()
        self.content = content()
    }
    
    init(
        showFilterText: Bool = false,
        @ViewBuilder title: () -> TitleContent,
        @ViewBuilder content: () -> Content
    ) where FooterContent == EmptyView {
        self.showFilterText = showFilterText
        self.title = nil
        self.footer = nil
        self.footerContent = EmptyView()
        self.titleContent = title()
        self.content = content()
    }

    init(
        showFilterText: Bool = false,
        @ViewBuilder content: () -> Content
    ) where TitleContent == EmptyView, FooterContent == EmptyView {
        self.showFilterText = showFilterText
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
                        #if os(iOS)
                        .fill(Color(.secondarySystemGroupedBackground))
                        #endif
                }
            
            
            if let footer {
                Text(footer)
                    .padding(.horizontal, 12)
                    .foregroundStyle(.secondary)
                    .font(.headline)

            } else if !(FooterContent.self == EmptyView.self) {
                footerContent
                    .padding(.horizontal, 12)
            }
        }
    }
}
