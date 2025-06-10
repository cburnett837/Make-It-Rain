//
//  WidgetLabel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/9/25.
//

import SwiftUI

struct WidgetLabel: View {
    var title: String
    var body: some View {
        HStack {
            Text(title)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                //.background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground)))
                #if os(iOS)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
                #else
                .background(Capsule().fill(Color(.secondarySystemFill)))
                #endif
            
            Spacer()
        }
    }
}

struct WidgetLabelButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        HStack {
            Button {
                action()
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                    Text(title)
                        .foregroundColor(.primary)
                }
                
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            #if os(iOS)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
            #else
            .buttonStyle(.plain)
            .background(Capsule().fill(Color(.secondarySystemFill)))
            #endif
            //.background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
            //.padding(.bottom, 3)
            
            Spacer()
        }
    }
}

struct WidgetLabelMenu: View {
    var title: String
    let sections: [WidgetLabelOptionSection]
    
    var body: some View {
        HStack {
            Menu {
                ForEach(sections) { section in
                    Section(section.title ?? "") {
                        ForEach(section.options) { option in
                            option.content
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                    Text(title)
                        .foregroundColor(.primary)
                }
                
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            #if os(iOS)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
            #else
            .buttonStyle(.plain)
            .background(Capsule().fill(Color(.secondarySystemFill)))
            #endif
            //.background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
            //.padding(.bottom, 3)
            
            Spacer()
        }
    }
}

struct WidgetLabelOptionSection: Identifiable {
    let id = UUID().uuidString
    let title: String?
    let options: [WidgetLabelOption]
}

struct WidgetLabelOption: Identifiable {
    let id = UUID().uuidString
    var content: AnyView
}

