//
//  TransactionTrackingNumberView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/17/25.
//

import SwiftUI
import WebKit
import UniformTypeIdentifiers


struct TevTrackingNumberView: View {
    @Binding var trackingNumber: String
    
    @FocusState private var focusedField: Int?
    @State private var page = WebPage()
    @State private var trackingURL: URL?
    @State private var shouldEdit = false
    
    @Environment(\.openURL) private var openURL
    
    var carrier: ShippingCarrier? {
        detectCarrier(from: trackingNumber)
    }
    
    var body: some View {
        VStack {
            if let carrier, let _ = carrier.trackingURL(for: trackingNumber) {
                VStack {
                    Text("Tracking Number")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 12)
                        .bold()
                    
                    GroupBox {
                        trackingTextField
                    }
                    .cornerRadius(26)
                                                
                    WebView(page)
                        .cornerRadius(26)
                        .opacity(page.isLoading ? 0.5 : 1)
                        .overlay {
                            ZStack {
                                Rectangle()
                                    .fill(.ultraThickMaterial)
                                    .cornerRadius(26)
                                ProgressView().schemeBasedTint()
                            }
                            .opacity(page.isLoading ? 1 : 0)
                        }
                }
                .padding(.horizontal, 24)
            } else {
                List {
                    Section {
                        if shouldEdit {
                            trackingTextField
                        } else {
                            if trackingNumber.isEmpty {
                                Text("(No Tracking)")
                                    .foregroundStyle(.gray)
                            } else {
                                TrackingTextView(text: trackingNumber, detectedURL: $trackingURL)
                            }
                            
                        }
                        
                        if !trackingNumber.isEmpty {
                            copyButton
                        }
                        
                        Button(shouldEdit ? "Done" : "Edit") {
                            shouldEdit.toggle()
                            if shouldEdit {
                                focusedField = 0
                            }
                        }
                    } header: {
//                        Label {
//                            Text("Tracking Number")
//                        } icon: {
//                            Image(systemName: "exclamationmark.triangle.fill")
//                                .foregroundStyle(Color.theme == .orange ? .red : .orange)
//                        }
                        
                        if trackingNumber.isEmpty || shouldEdit {
                            Text("Tracking Number")
                        } else {
                            Label {
                                Text("Tracking Number")
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.theme == .orange ? .red : .orange)
                            }
                        }
                        
                    } footer: {
                        if !trackingNumber.isEmpty && !shouldEdit {
                            Text("The carrier could not be determined. Trying holding or double tapping the tracking number above to check the carriers website. Additionally, you can edit the tracking number if you think it is incorrect.")
                        }
                    }
                }
            }
        }
        .navigationTitle("Tracking Info")
        .task {
            
            if trackingNumber.isEmpty {
                shouldEdit = true
                focusedField = 0
                
            } else if let carrier = detectCarrier(from: trackingNumber),
                      let url = carrier.trackingURL(for: trackingNumber) {
                page.load(url)
            }
            
                                    
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.setValue(trackingNumber, forPasteboardType: UTType.plainText.identifier)
                    AppState.shared.showToast(
                        title: "Tracking number copied",
                        subtitle: trackingNumber,
                        symbol: "document.on.document"
                    )
                } label: {
                    Image(systemName: "document.on.document")
                        .schemeBasedForegroundStyle()
                }
            }
            
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    page.reload()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .schemeBasedForegroundStyle()
                }
            }
        }
        
        .onChange(of: focusedField) {
            if $1 == nil {
                shouldEdit = false
                if let carrier = detectCarrier(from: trackingNumber),
                   let url = carrier.trackingURL(for: trackingNumber) {
                    page.load(url)
                }
            }
        }
    }
    
    
    var copyButton: some View {
        Button {
            UIPasteboard.general.setValue(trackingNumber, forPasteboardType: UTType.plainText.identifier)
            AppState.shared.showToast(
                title: "Tracking number copied",
                subtitle: trackingNumber,
                symbol: "document.on.document"
            )
        } label: {
            Text("Copy Tracking Number")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    var trackingTextField: some View {
        Group {
            #if os(iOS)
            UITextFieldWrapper(placeholder: "ABC123", text: $trackingNumber, onSubmit: {
                shouldEdit = false
            }, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField, disableUp: true, disableDown: true)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiReturnKeyType(.next)
            .uiAutoCorrectionDisabled(true)
            #else
            StandardTextField("Tracking Number", text: $trans.trackingNumber, focusedField: $focusedField, focusValue: 2)
                .autocorrectionDisabled(true)
                //.onSubmit { focusedField = 3 }
            #endif
        }
        .focused($focusedField, equals: 0)
    }
}



fileprivate struct TrackingTextView: UIViewRepresentable {
    let text: String
    @Binding var detectedURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        textView.dataDetectorTypes = [.shipmentTrackingNumber]
        textView.delegate = context.coordinator

        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear

        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor.label
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        //textView.setContentCompressionResistancePriority(.required, for: .horizontal)
        //textView.setContentHuggingPriority(.required, for: .horizontal)

        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: TrackingTextView

        init(_ parent: TrackingTextView) {
            self.parent = parent
        }
        
        @available(iOS 17.0, *)
        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {

            if case let .link(url) = textItem.content {
                print(url)
                DispatchQueue.main.async {
                    self.parent.detectedURL = url
                }
                return nil // suppress Safari
            }

            return defaultAction
        }
    }
}




enum ShippingCarrier: String, CaseIterable, Identifiable {
    case ups
    case usps
    case fedex
    case dhl

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ups: return "UPS"
        case .usps: return "USPS"
        case .fedex: return "FedEx"
        case .dhl: return "DHL"
        }
    }

    /// Regex patterns commonly used in the wild
    var regex: String {
        switch self {
        case .ups:
            return #"^1Z[0-9A-Z]{16}$"#
        case .usps:
            //return #"^(94|93|92|95)[0-9]{20}$|^[A-Z]{2}[0-9]{9}US$"#
            return #"^(9[2345])[0-9]{20,24}$"#
        case .fedex:
            return #"^[0-9]{12,15}$"#
        case .dhl:
            return #"^[0-9]{10,11}$"#
        }
    }

    func trackingURL(for number: String) -> URL? {
        switch self {
        case .ups:
            return URL(string: "https://www.ups.com/track?tracknum=\(number)")
        case .usps:
            return URL(string: "https://tools.usps.com/go/TrackConfirmAction?tLabels=\(number)")
        case .fedex:
            return URL(string: "https://www.fedex.com/fedextrack/?trknbr=\(number)")
        case .dhl:
            return URL(string: "https://www.dhl.com/en/express/tracking.html?AWB=\(number)")
        }
    }
}


func detectCarrier(from trackingNumber: String) -> ShippingCarrier? {
    let trimmed = trackingNumber
        .uppercased()
        .replacingOccurrences(of: " ", with: "")

    return ShippingCarrier.allCases.first {
        trimmed.range(
            of: $0.regex,
            options: .regularExpression
        ) != nil
    }
}
