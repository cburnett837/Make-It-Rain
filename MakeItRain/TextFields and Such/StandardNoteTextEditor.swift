//
//  StandardNoteTextEditor.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/2/25.
//

import SwiftUI

@Observable
final class TextViewCommands {
    var bold: (() -> Void)?
    var italic: (() -> Void)?
    //var applyColor: ((UIColor) -> Void)?
}

#if os(iOS)
struct StandardNoteTextEditor: View {
    @Environment(\.fontResolutionContext) var fontResolutionContext
    
    @Binding var notes: AttributedString
    var symbolWidth: CGFloat
    var focusedField: FocusState<Int?>
    var focusID: Int
    var showSymbol: Bool = true
    
    @State private var selection = AttributedTextSelection()
    
//    var plainString: String {
//        print(String(notes.characters))
//        return String(notes.characters)
//    }
    
    var body: some View {
        HStack(alignment: .top) {
            if showSymbol {
                Image(systemName: "note.text")
                    .foregroundColor(.gray)
                    .font(.title2)
                    //.frame(width: symbolWidth)
            }
            
            TextEditor(text: $notes, selection: $selection)
                .writingToolsBehavior(.complete)
                .foregroundStyle(.primary)
                //.foregroundStyle(plainString.isEmpty ? .gray : .primary)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .frame(minHeight: 100)
                .focused(focusedField.projectedValue, equals: focusID)
//                .toolbar {
//                    ToolbarItem(placement: .keyboard) {
//                        HStack(spacing: 20) {
//                            Button {
//                                notes.transformAttributes(in: &selection) { container in
//                                    let current = container.font ?? .default
//                                    let resolved = current.resolve(in: fontResolutionContext)
//                                    container.font = current.bold(!resolved.isBold)
//                                }
//                            } label: {
//                                Image(systemName: "bold")
//                            }
//                            .schemeBasedForegroundStyle()
//                            
//                            
//                            Button {
//                                notes.transformAttributes(in: &selection) { container in
//                                    let current = container.font ?? .default
//                                    let resolved = current.resolve(in: fontResolutionContext)
//                                    container.font = current.italic(!resolved.isItalic)
//                                }
//                            } label: {
//                                Image(systemName: "italic")
//                            }
//                            .schemeBasedForegroundStyle()
//                            
//                            
//                            Button {
//                                notes.transformAttributes(in: &selection) { container in
//                                    if container.underlineStyle == .single {
//                                        container.underlineStyle = .none
//                                    } else {
//                                        container.underlineStyle = .single
//                                    }
//                                }
//                            } label: {
//                                Image(systemName: "underline")
//                            }
//                            .schemeBasedForegroundStyle()
//                            
//                            Spacer()
//                            
//                            Button {
//                                focusedField.wrappedValue = nil
//                            } label: {
//                                Image(systemName: "checkmark")
//                            }
//                            .schemeBasedForegroundStyle()
//                        }
//                    }
//                }
                #if os(iOS)
                .offset(y: -8)
                #else
                .offset(y: 1)
                #endif
                .overlay {
                    Text("Notes…")
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .opacity(!String(notes.characters).isEmpty || focusedField.wrappedValue == focusID ? 0 : 1)
                        .allowsHitTesting(false)
                        #if os(iOS)
                        .padding(.top, 2)
                        #else
                        .offset(y: -1)
                        #endif
                        .padding(.leading, 0)
                }
        }
    }
}

struct StandardUITextEditor: View {
    @Environment(\.colorScheme) var colorScheme

    @State private var selection = AttributedTextSelection()
    @State private var textCommands = TextViewCommands()
    
    @Binding var text: AttributedString
    var focusedField: FocusState<Int?>
    var focusID: Int
    var scrollProxy: ScrollViewProxy
    
    var body: some View {
        Section("Notes") {
            UITextViewWrapper(text: $text, commands: textCommands) {
                KeyboardToolbarView(
                    focusedField: focusedField.projectedValue,
                    removeNavButtons: true,
                    accessoryImage1: "bold",
                    accessoryFunc1: { textCommands.bold?() },
                    accessoryImage2: "italic",
                    accessoryFunc2: { textCommands.italic?() }
                )
            }
            .uiTag(2)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiFont(.preferredFont(forTextStyle: .body))
            .uiTextColor(colorScheme == .dark ? .white : .black)
            .frame(minHeight: 100)
            .focused(focusedField.projectedValue, equals: 2)
            .overlay(fakePlaceholder)
        }
        
        scrollFocusTargetSection
            .onChange(of: focusedField.wrappedValue) {
                if $1 == 2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollProxy.scrollTo(focusID, anchor: .bottom)
                        }
                    }
                }
            }
    }
    
    
    var fakePlaceholder: some View {
        Text("Add some deets…")
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .opacity(!String(text.characters).isEmpty || focusedField.wrappedValue == focusID ? 0 : 1)
            .allowsHitTesting(false)
            #if os(iOS)
            .padding(.top, 10)
            #else
            .offset(y: -1)
            #endif
            .padding(.leading, 0)
    }
    
    
    var scrollFocusTargetSection: some View {
        Section {
            Text("")
                .frame(maxWidth: .infinity, minHeight: 0)
                .padding(.vertical, 1)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
        }
        .listSectionSpacing(0)
        .id(focusID)
    }
    
}


struct UITextViewWrapper<Toolbar: View>: UIViewRepresentable {
    @Binding var text: AttributedString
    @Bindable var commands: TextViewCommands
    var toolbar: () -> Toolbar?
    
    private var font: UIFont?
    private var textColor: UIColor?
    private var tint: UIColor?
    private var textAlignment: NSTextAlignment?
    private var contentType: UITextContentType?
    private var autoCorrection: UITextAutocorrectionType = .default
    private var autocapitalizationType: UITextAutocapitalizationType = .sentences
    //private var keyboardType: UIKeyboardType = .default
    private var keyboardType: CBKeyboardType = .system(.default)
    private var returnKeyType: UIReturnKeyType = .default
    private var isSecure: Bool = false
    private var isUserInteractionEnabled: Bool = true
    private var tag: Int?
    private var maxLength: Int?
    private var startCursorAtEnd: Bool = false
    
    init(
        text: Binding<AttributedString>,
        commands: TextViewCommands,
        @ViewBuilder toolbar: @escaping () -> Toolbar? = { EmptyView() }
    ) {
        self._text = text
        self.commands = commands
        self.toolbar = toolbar
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isScrollEnabled = false
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.backgroundColor = .clear
        textView.writingToolsBehavior = .complete
        textView.allowsEditingTextAttributes = true
//        textView.textContainerInset = .zero
//        textView.textContainer.lineFragmentPadding = 0
//        textView.contentInset = .zero
                
        textView.font = font
        textView.textColor = textColor
        textView.tintColor = tint
        if let textAlignment { textView.textAlignment = textAlignment }
        textView.textContentType = contentType
        textView.autocorrectionType = autoCorrection
        textView.autocapitalizationType = autocapitalizationType
        if case .system(let systemType) = keyboardType {
            textView.keyboardType = systemType
        }
                
        textView.returnKeyType = returnKeyType
        textView.isSecureTextEntry = isSecure
        textView.isUserInteractionEnabled = isUserInteractionEnabled
        if let tag { textView.tag = tag }
        
        textView.delegate = context.coordinator
        //textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                                
        if toolbar() is EmptyView { } else {
            let toolbarController = UIHostingController(rootView: toolbar())
            toolbarController.view.frame = .init(origin: .zero, size: toolbarController.view.intrinsicContentSize)
            toolbarController.view.backgroundColor = .clear
            textView.inputAccessoryView = toolbarController.view
        }
        
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let ns = Helpers.makeUITextViewString(from: text)
        uiView.attributedText = ns
        //uiView.attributedText = NSAttributedString(text)
        context.coordinator.textView = uiView
        
        
    }

    func makeCoordinator() -> Coordinator {
        let c = Coordinator(self)
        
        commands.bold = { [weak c] in c?.toggleBold() }
        commands.italic = { [weak c] in c?.toggleItalic() }
        //commands.applyColor = { [weak c] color in c?.setColor(color) }
        
        return c
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: UITextViewWrapper
        weak var textView: UITextView?

        
        init(_ parent: UITextViewWrapper) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = AttributedString(textView.attributedText)
        }
        
        func toggleBold() {
            guard let tv = textView else { return }
            textView?.toggleBold()
            parent.text = AttributedString(tv.attributedText)
        }

        func toggleItalic() {
            guard let tv = textView else { return }
            textView?.toggleItalic()
            parent.text = AttributedString(tv.attributedText)
        }
        
//        func setColor(_ color: UIColor) {
//            guard let tv = textView else { return }
//            textView?.applyColor(color)
//            parent.text = AttributedString(tv.attributedText)
//            //syncBack()
//        }
    }
}


extension UITextViewWrapper {
    func uiFont(_ font: UIFont?) -> UITextViewWrapper {
        var view = self
        view.font = font
        return view
    }

    func uiTextColor(_ color: UIColor?) -> UITextViewWrapper {
        var view = self
        view.textColor = color
        return view
    }

    func uiTint(_ accentColor: UIColor?) -> UITextViewWrapper {
        var view = self
        view.tint = tint
        return view
    }

    func uiTextAlignment(_ alignment: NSTextAlignment?) -> UITextViewWrapper {
        var view = self
        view.textAlignment = alignment
        return view
    }

    func uiTextContentType(_ textContentType: UITextContentType?) -> UITextViewWrapper {
        var view = self
        view.contentType = textContentType
        return view
    }

    func uiAutoCorrectionDisabled(_ disable: Bool?) -> UITextViewWrapper {
        var view = self
        if let disable = disable {
            view.autoCorrection = disable ? .no : .yes
        } else {
            view.autoCorrection = .default
        }
        return view
    }

    func uiAutoCapitalizationType(_ style: UITextAutocapitalizationType) -> UITextViewWrapper {
        var view = self
        view.autocapitalizationType = style
        return view
    }

    func uiKeyboardType(_ type: CBKeyboardType) -> UITextViewWrapper {
        var view = self
        view.keyboardType = type
        return view
    }
    
    func uiReturnKeyType(_ type: UIReturnKeyType) -> UITextViewWrapper {
        var view = self
        view.returnKeyType = type
        return view
    }

    func uiIsSecure(_ isSecure: Bool) -> UITextViewWrapper {
        var view = self
        view.isSecure = isSecure
        return view
    }
    
    func uiDisabled(_ disabled: Bool) -> UITextViewWrapper {
        var view = self
        view.isUserInteractionEnabled = disabled
        return view
    }
    
    func uiTag(_ tag: Int?) -> UITextViewWrapper {
        var view = self
        view.tag = tag
        return view
    }
    
    func uiMaxLength(_ length: Int?) -> UITextViewWrapper {
        var view = self
        view.maxLength = length
        return view
    }
    
    func uiStartCursorAtEnd(_ value: Bool) -> UITextViewWrapper {
        var view = self
        view.startCursorAtEnd = value
        return view
    }
}


extension UITextView {
    func applyAttributeMutation(_ mutate: (NSMutableAttributedString) -> Void) {
        let oldSelectedRange = selectedRange

        let mutable = NSMutableAttributedString(attributedString: attributedText)
        mutate(mutable)

        self.attributedText = mutable
        self.selectedRange = oldSelectedRange   // 🔥 restore selection
    }
    
    func toggleBold() {
        applyAttributeMutation { mutable in
            mutable.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
                let font = value as? UIFont ?? UIFont.systemFont(ofSize: 16)

                let isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
                var traits = font.fontDescriptor.symbolicTraits

                if isBold {
                    traits.remove(.traitBold)
                } else {
                    traits.insert(.traitBold)
                }

                guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else { return }
                let newFont = UIFont(descriptor: descriptor, size: font.pointSize)

                mutable.addAttribute(.font, value: newFont, range: range)
            }
        }
    }

    func toggleItalic() {
        applyAttributeMutation { mutable in
            mutable.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
                let font = value as? UIFont ?? UIFont.systemFont(ofSize: 16)

                let isItalic = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
                var traits = font.fontDescriptor.symbolicTraits

                if isItalic {
                    traits.remove(.traitItalic)
                } else {
                    traits.insert(.traitItalic)
                }

                guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else { return }
                let newFont = UIFont(descriptor: descriptor, size: font.pointSize)

                mutable.addAttribute(.font, value: newFont, range: range)
            }
        }
    }

//    func applyColor(_ color: UIColor) {
//        applyAttributeMutation { mutable in
//            mutable.enumerateAttribute(.foregroundColor, in: selectedRange) { _, range, _ in
//                mutable.addAttribute(.foregroundColor, value: color, range: range)
//            }
//        }
//    }
//    
//    func removeColor() {
//        applyAttributeMutation { mutable in
//            mutable.removeAttribute(.foregroundColor, range: selectedRange)
//        }
//    }
}

#endif
