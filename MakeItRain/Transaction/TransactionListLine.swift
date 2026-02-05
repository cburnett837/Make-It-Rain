//
//  TransactionListLine.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/7/25.
//

import SwiftUI

struct TransactionListLine: View {
    @Environment(CalendarModel.self) var calModel

    
    @Bindable var trans: CBTransaction
    var withDate: Bool = false
    var withTags: Bool = false
    var withPhotos: Bool = false
    var onTap: () -> ()
    
    @State private var fileProps = FileViewProps()
    @State private var selectedFile: CBFile?

    
    @State private var transHeight: CGFloat = 20.0
    private struct TransLineHeightPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = .zero

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
    
    var body: some View {
        HStack(alignment: .circleAndTitle) {
            BusinessLogo(config: .init(
                parent: trans.payMethod,
                fallBackType: .color
            ))
            
            //BusinessLogo(parent: trans.payMethod, fallBackType: .color)
            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack(spacing: 2) {
                HStack {
                    VStack(spacing: 2) {
                        firstLine
                        secondLine
                    }
                    .contentShape(.rect)
                    .onTapGesture { onTap() }
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    .background { GeometryReader { Color.clear.preference(key: TransLineHeightPreferenceKey.self, value: $0.size.height) } }
                    .onPreferenceChange(TransLineHeightPreferenceKey.self) { transHeight = max(transHeight, $0) }
                    
                    if withPhotos {
                        photo
                    }
                    
                }
                
                if withTags && !trans.tags.isEmpty {
                    tags
                        .contentShape(.rect)
                        .onTapGesture { onTap() }
                }
            }
        }
        .environment(fileProps)
        #if os(iOS)
        .sheet(item: $selectedFile) { file in
            PhotoWebPreview(file: file)
        }
        #endif
    }
    
    
    var firstLine: some View {
        HStack {
            Text(trans.title)
                .lineLimit(1)
            Spacer()
            amount
        }
        .overlay { ExcludeFromTotalsLine(trans: trans) }
    }
    
    var secondLine: some View {
        HStack {
            category
            Spacer()
            if withDate {
                date
            }
        }
        .overlay { ExcludeFromTotalsLine(trans: trans) }
    }
    
    
    @ViewBuilder
    var amount: some View {
        if trans.payMethod?.accountType == .credit || trans.payMethod?.accountType == .loan {
            Text((trans.amount * -1).currencyWithDecimals())
        } else {
            Text(trans.amount.currencyWithDecimals())
        }
    }
    
    
    var category: some View {
        HStack(spacing: 4) {
            Circle()
                .frame(width: 6, height: 6)
                .foregroundStyle(trans.category?.color ?? .primary)
            
            Text(trans.category?.title ?? "N/A")
                .foregroundStyle(.gray)
                .font(.caption)
        }
    }
    
    
    var date: some View {
        Text(trans.prettyDate ?? "N/A")
            .foregroundStyle(.gray)
            .font(.caption)
    }
    
    
    var tags: some View {
        TagLayout(alignment: .leading, spacing: 5) {
            ForEach(trans.tags.sorted(by: { $0.tag < $1.tag })) { tag in
                Text("#\(tag.tag)")
                    .foregroundStyle(.gray)
                    .font(.caption)
                    .padding(4)
                    #if os(iOS)
                    .background(Color(.systemGray4))
                    #endif
                    .cornerRadius(6)
                    .overlay { ExcludeFromTotalsLine(trans: trans) }
            }
        }
    }
    
    
    @ViewBuilder
    var photo: some View {
        if let files = trans.files?.filter({ $0.active }), !files.isEmpty {
            ForEach(files.prefix(1)) { file in
                ConditionalFileView(
                    file: file,
                    selectedFile: $selectedFile,
                    displayStyle: .standard,
                    parentType: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction),
                    fileUploadCompletedDelegate: calModel,
                    placeholderView: {
                        LoadingPlaceholder(text: "Uploading…", displayStyle: .standard)
                    }, photoView: {
                        CustomAsyncImage(file: file) { image in
                            image
                                .resizable()
                                .frame(width: transHeight, height: transHeight)
                                .aspectRatio(contentMode: .fill)
                                .clipShape(.rect(cornerRadius: 6))
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.ultraThickMaterial)
                                .frame(width: transHeight, height: transHeight)
                                .overlay(ProgressView().tint(.none))
                        }
                    }, pdfView: {
                        #if os(iOS)
                        CustomAsyncPdf(file: file, displayStyle: .standard)
                        #endif
                    }, csvView: {
                        #if os(iOS)
                        CustomAsyncCsv(file: file, displayStyle: .standard)
                        #endif
                    }
                )
            }
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThickMaterial)
                .frame(width: transHeight, height: transHeight)
                .overlay(Image(systemName: "camera.macro.slash"))
        }
    }
}
