//
//  TextFields.swift
//  JARVIS_MAC_MIC
//
//  Created by Cody Burnett on 8/20/21.
//

import SwiftUI


struct SearchTextField: View {
    var title: String
    @Binding var searchText: String
    var focusedField: FocusState<Int?>.Binding
    var focusState: FocusState<Int?>
    
    var body: some View {
        #if os(iOS)
        StandardUITextField("Search \(title)", text: $searchText, toolbar: {
            KeyboardToolbarView(focusedField: focusedField, removeNavButtons: true)
        })
        .cbFocused(focusState, equals: 0)
        .cbClearButtonMode(.whileEditing)
        .cbIsSearchField(true)
        .padding(.horizontal, 20)
        #else
        StandardTextField("Search \(title)", text: $searchText, isSearchField: true, focusedField: focusedField, focusValue: 0)
            .padding(.horizontal, 20)
        #endif
    }
}


struct StandardTextField: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    
    /// This is needed to enable animation of the cancel button.
    @State private var didFocus = false
    
    //@FocusState var focusState: Bool
    
    var placeholder: String
    @Binding var text: String
    //var keyboardType: TextFieldInputType = .text
    var isSearchField: Bool = false
    var alwaysShowCancelButton = false
    var alignment: TextAlignment = .leading
    var focusedField: FocusState<Int?>.Binding
    var focusValue: Int? = nil
    var onSubmit: (() -> ())?
    var onClear: (() -> ())?
    var onCancel: (() -> ())?
        
//
    init(
        _ placeholder: String,
        text: Binding<String>,
        //keyboardType: TextFieldInputType = .text,
        isSearchField: Bool = false,
        alwaysShowCancelButton: Bool = false,
        alignment: TextAlignment = .leading,
        focusedField: FocusState<Int?>.Binding,
        focusValue: Int? = nil,
        onSubmit: @escaping () -> Void = {},
        onClear: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSearchField = isSearchField
        self.alwaysShowCancelButton = alwaysShowCancelButton
        self.alignment = alignment
        self.focusedField = focusedField
        self.focusValue = focusValue
        self.onSubmit = onSubmit
        self.onClear = onClear
        self.onCancel = onCancel
        //self.keyboardType = keyboardType
                                                
        //UITextField.appearance().clearsOnBeginEditing = true
    }
    
    var body: some View {
        HStack {
            StandardRectangle {
                HStack {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .padding(.leading, isSearchField ? 24 : 0)
                        .padding(.trailing, didFocus && !text.isEmpty ? 24 : 0)
                        .focused(focusedField, equals: focusValue)
                    //.focused($focusState)
                    //.if(focusValue == .search) { $0.submitLabel(.search) }
                        .onSubmit {
                            if let onSubmit { onSubmit() }
                        }
                    /// This is needed to enable animation of the cancel button.
                        .onChange(of: focusedField.wrappedValue, { oldValue, newValue in
                            if focusedField.wrappedValue == focusValue {
                                withAnimation {
                                    didFocus = newValue != nil
                                }
                            } else {
                                didFocus = false
                            }
                        })
                    
                        .overlay(
                            HStack {
                                if isSearchField {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Spacer()
                                }
                                
                                if didFocus && !text.isEmpty {
                                    Button {
                                        text = ""
                                        if let onClear { onClear() }
                                    } label: {
                                        Image(systemName: "multiply.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .buttonStyle(.plain)
                                    .focusable(false)
                                }
                            }
                        )
                    //.standardTextField(alignment: alignment, submit: onSubmit ?? {})
                    
                    /// BEGIN This is the stuff from `.standardTextField()`
                        //.padding(.vertical, 6)
                    //.padding(.leading, 0)
                        //.background(Color(.tertiarySystemFill))
                        //.cornerRadius(8)
                        .multilineTextAlignment(alignment)
                        .frame(maxWidth: .infinity)
                    //            .onSubmit {
                    //                if let onSubmit = onSubmit {
                    //                    onSubmit()
                    //                }
                    //            }
                    /// END This is the stuff from `.standardTextField()`
                        .frame(maxHeight: .infinity)
                    
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            
            
            if (isSearchField && didFocus) || alwaysShowCancelButton {
                Button("Cancel") {
                    withAnimation {
                        //focusState = false
                        text = ""
                        didFocus = false
                        focusedField.wrappedValue = nil
                        if let onCancel {
                            onCancel()
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .tint(Color.fromName(appColorTheme))
                .focusable(false)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}



#if os(macOS)
struct ToolbarTextField: View {
    @FocusState var focusState: Bool
    @State private var didFocus = false
    
    var placeholder: String
    @Binding var text: String
    var isSearchField: Bool
    var alignment: TextAlignment
    var onFocus: ((_ didFocus: Bool) -> ())?
    var onHover: ((_ didHover: Bool) -> ())?
    var onSubmit: (() -> ())?
    var onClear: (() -> ())?
    
    var keyboardType: TextFieldInputType
    
    init(
        _ placeholder: String,
        text: Binding<String> = .constant(""),
        keyboardType: TextFieldInputType,
        isSearchField: Bool = false,
        alignment: TextAlignment = .leading,
        onFocus: @escaping (_: Bool) -> Void = {_ in },
        onHover: @escaping (_: Bool) -> Void = {_ in },
        onSubmit: @escaping () -> Void = {},
        onClear: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.alignment = alignment
        self.onFocus = onFocus
        self.onHover = onHover
        self.onSubmit = onSubmit
        self.onClear = onClear
        self.isSearchField = isSearchField
    }
    
    var body: some View {
        HStack {
            Group {
                switch keyboardType {
                case .text, .double:
                    TextField(placeholder, text: $text)
                    
                case .currency:
                    TextField(placeholder, text: $text)
                        .onChange(of: text) { oldValue, newValue in
                            if !newValue.starts(with: "$") && !newValue.isEmpty {
                                text = "$\(newValue)"
                            }
                        }
                }
            }
            .textFieldStyle(.plain)
            //.padding(.horizontal, 5.5)
            .padding(.leading, isSearchField ? 24 : 5.5)
            .padding(.trailing, didFocus && !text.isEmpty ? 24 : 0)
            
            .focused($focusState)
            
            .onSubmit {
                if let onSubmit {
                    onSubmit()
                }
            }
            
            .onHover { didHover in
                if let onHover {
                    onHover(didHover)
                }
            }
            
            .onChange(of: focusState, { oldValue, newValue in
                self.didFocus = newValue
                if let onFocus {
                    onFocus(newValue)
                }
            })
            
            .overlay(
                HStack {
                    if isSearchField {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 5.5)
                    } else {
                        Spacer()
                    }
                    
                    if didFocus && !text.isEmpty {
                        Button(action: {
                            switch keyboardType {
                            case .text: text = ""
                            case .double: text = "0.0"
                            case .currency: text = ""
                            }
                            if let onClear {
                                onClear()
                            }
                        }) {
                            Image(systemName: "multiply.circle.fill")
                                .foregroundColor(.gray)
                                //.scaleEffect(0.7)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                    }
                }
            )
            .toolbarKeyboard(alignment: alignment)
        }
    }
}
#endif






#if os(iOS)
//struct StandardUITextField<Toolbar: View>: View {
//    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
//
//    @State private var didFocus = false
//    
//    //@FocusState var focusState: Bool
//    
//    var placeholder: String
//    @Binding var text: String
//    var keyboardType: TextFieldInputType = .text
//    var isSearchField: Bool = false
//    var alignment: NSTextAlignment = .left
//    var focusedField: FocusState<Int?>.Binding
//    var focusValue: Int? = nil
//    var keyboardStyle: UIKeyboardType = .default
//    var submitLabel: UIReturnKeyType = .default
//    var autoCorrection: UITextAutocorrectionType = .default
//    var clearButtonMode: UITextField.ViewMode = .never
//    var onSubmit: (() -> Void)?
//    var onClear: (() -> Void)?
//    var onCancel: (() -> Void)?
//    @ViewBuilder var toolbar: Toolbar
//    
//    init(
//        placeholder: String,
//        text: Binding<String>,
//        keyboardType: TextFieldInputType = .text,
//        isSearchField: Bool = false,
//        alignment: NSTextAlignment = .left,
//        focusedField: FocusState<Int?>.Binding,
//        focusValue: Int? = nil,
//        keyboardStyle: UIKeyboardType = .default,
//        submitLabel: UIReturnKeyType = .default,
//        autoCorrection: UITextAutocorrectionType = .default,
//        clearButtonMode: UITextField.ViewMode = .never,
//        onSubmit: (() -> Void)? = nil,
//        onClear: (() -> Void)? = nil,
//        onCancel: (() -> Void)? = nil,
//        @ViewBuilder toolbar: () -> Toolbar
//    ) {
//        self.placeholder = placeholder
//        self._text = text
//        self.keyboardType = keyboardType
//        self.isSearchField = isSearchField
//        self.alignment = alignment
//        self.focusedField = focusedField
//        self.focusValue = focusValue
//        self.keyboardStyle = keyboardStyle
//        self.submitLabel = submitLabel
//        self.autoCorrection = autoCorrection
//        self.clearButtonMode = clearButtonMode
//        self.onSubmit = onSubmit
//        self.onClear = onClear
//        self.onCancel = onCancel
//        self.toolbar = toolbar()
//        
//        if isSearchField {
//            self.submitLabel = .search
//        }
//    }
//        
//    var body: some View {
//        HStack {
//            Group {
//                UITextFieldWrapper(
//                    placeholder: placeholder,
//                    text: $text,
//                    tag: focusValue!,
//                    textAlignment: alignment,
//                    keyboardType: keyboardStyle,
//                    returnKeyType: submitLabel,
//                    autoCorrection: autoCorrection,
//                    clearButtonMode: clearButtonMode,
//                    onSubmit: onSubmit,
//                    onClear: onClear
//                ) { toolbar }
//                    .if(keyboardType == .currency) {
//                        $0.onChange(of: text) { oldValue, newValue in
//                            if !newValue.starts(with: "$") && !newValue.isEmpty {
//                                text = "$\(newValue)"
//                            }
//                        }
//                    }
//            }
//            .padding(.leading, isSearchField ? 24 : 0)
//            .focused(focusedField, equals: focusValue)
//            .overlay(
//                HStack {
//                    if isSearchField {
//                        Image(systemName: "magnifyingglass")
//                            .foregroundColor(.gray)
//                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
//                    } else {
//                        Spacer()
//                    }
//                }
//            )
//            .padding(6)
//            .padding(.leading, 0)
//            .background(Color(.tertiarySystemFill))
//            .cornerRadius(8)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//
//            if isSearchField && focusedField.wrappedValue == focusValue {
//                Button("Cancel") {
//                    withAnimation {
//                        text = ""
//                        focusedField.wrappedValue = nil
//                        if let onCancel {
//                            onCancel()
//                        }
//                    }
//                }
//                .frame(maxHeight: .infinity)
//                .tint(Color.fromName(appColorTheme))
//                .focusable(false)
//            }
//        }
//        .fixedSize(horizontal: false, vertical: true)
//    }
//}
//
//
//struct UITextFieldWrapper<Toolbar: View>: UIViewRepresentable {
//    var placeholder: String
//    @Binding var text: String
//    var tag: Int?
//    var textAlignment: NSTextAlignment?
//    var keyboardType: UIKeyboardType
//    var returnKeyType: UIReturnKeyType
//    var autoCorrection: UITextAutocorrectionType
//    var clearButtonMode: UITextField.ViewMode?
//    var onSubmit: (() -> Void)?
//    var onClear: (() -> Void)?
////    var onCancel: (() -> Void)?
//    @ViewBuilder var toolbar: Toolbar
//    
//    func makeUIView(context: Context) -> UITextField {
//        print("-- \(#function) - \(text)")
//        let toolbarController = UIHostingController(rootView: toolbar)
//        toolbarController.view.frame = .init(origin: .zero, size: toolbarController.view.intrinsicContentSize)
//        
//        let textField = UITextField()
//        textField.placeholder = placeholder
//        textField.text = text
//        textField.delegate = context.coordinator
//        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
//        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        if let clearButtonMode {
//            textField.clearButtonMode = clearButtonMode
//        }
//        
//        textField.keyboardType = keyboardType
//        textField.returnKeyType = returnKeyType
//        textField.autocorrectionType = autoCorrection
//        if let tag {
//            textField.tag = tag
//        }
//        
//        //textField.clearsOnBeginEditing = true
//        if let textAlignment {
//            textField.textAlignment = textAlignment
//        }
//        
//        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
//        textField.inputAccessoryView = toolbarController.view
//        return textField
//    }
//        
//        
//    func updateUIView(_ textField: UITextField, context: Context) {
//        //print("-- \(#function) --- \(text)")
//        DispatchQueue.main.async {
//            textField.text = text
//        }
////        DispatchQueue.main.async {
////            let toolbarController = UIHostingController(rootView: toolbar)
////            toolbarController.view.frame = .init(origin: .zero, size: toolbarController.view.intrinsicContentSize)
////            textField.inputAccessoryView = toolbarController.view
////            //textField.reloadInputViews()
////        }
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        .init(text: $text, onSubmit: onSubmit, onClear: onClear /*, onCancel: onCancel*/)
//    }
//    
//    class Coordinator: NSObject, UITextFieldDelegate {
//        @Binding var text: String
//        var onSubmit: (() -> Void)?
//        var onClear: (() -> Void)?
//        //var onCancel: (() -> Void)?
//                
//        init(text: Binding<String>, onSubmit: (() -> Void)?, onClear: (() -> Void)? /*, onCancel: (() -> Void)?*/) {
//            self._text = text
//            self.onSubmit = onSubmit
//            self.onClear = onClear
//            //self.onCancel = onCancel
//        }
//        
//        func textFieldDidEndEditing(_ textField: UITextField) {
//            if let text = textField.text {
//                self.text = text
//            }
//        }
//
//        @objc func textFieldDidChange(_ textField: UITextField) {
//            print("-- \(#function)")
//            if let text = textField.text {
//                self.text = text
//            }
//        }
//        
//        
////
////        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//////            if let text = textField.text as NSString? {
//////                let finaltext = text.replacingCharacters(in: range, with: string)
//////                self.text = finaltext as String
//////            }
////            
////            
//////            if let text = textField.text {
//////                self.text = text
//////            }
////            
////            return true
////        }
//        
//        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//            if let onSubmit = onSubmit {
//                onSubmit()
//            }
//            return true
//        }
//                
//        func textFieldShouldClear(_ textField: UITextField) -> Bool {
//            print("-- \(#function)")
//            if let onClear = onClear {
//                onClear()
//            } else {
//                self.text = ""
//            }
//            return true
//        }
//        
////        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
////            if let onCancel = onCancel {
////                onCancel()
////            }
////            return true
////        }
//    }
//}



struct StandardUITextField<Toolbar: View>: View {
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    
    /// This is needed to enable animation of the cancel button.
    @State private var didFocus = false
    
    var placeholder: String
    @Binding var text: String
    @FocusState var focusedField: Int?
    var focusValue: Int? = nil
    
    var onSubmit: (() -> Void)?
    var onClear: (() -> Void)?
    var onCancel: (() -> Void)?
    var onBeginEditing: (() -> Void)?
    var toolbar: () -> Toolbar?
    
    private var alwaysShowCancelButton: Bool = false
    
    private var font: UIFont?
    private var foregroundColor: UIColor?
    private var tint: UIColor?
    private var multilineTextAlignment: NSTextAlignment?
    private var contentType: UITextContentType?
    private var disableAutocorrection: Bool?
    private var autocapitalizationType: UITextAutocapitalizationType = .sentences
    private var keyboardType: UIKeyboardType = .default
    private var submitLabel: UIReturnKeyType = .default
    private var isSecure: Bool = false
    private var clearsOnBeginEditing: Bool = false
    private var clearButtonMode: UITextField.ViewMode?
    private var disabled: Bool = true
    private var isSearchField: Bool = false
    private var textFieldInputType: TextFieldInputType = .text
    private var maxLength: Int?
    private var startCursorAtEnd: Bool = false
    //var focusedField: FocusState<Int?>.Binding = FocusState<Int?>().projectedValue
        
    
    init(
        _ placeholder: String,
        text: Binding<String>,
        onSubmit: (() -> Void)? = nil,
        onClear: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onBeginEditing: (() -> Void)? = nil,
        @ViewBuilder toolbar: @escaping () -> Toolbar? = { EmptyView() }
    ) {
        self.placeholder = placeholder
        self._text = text
        self.onSubmit = onSubmit
        self.onClear = onClear
        self.onCancel = onCancel
        self.onBeginEditing = onBeginEditing
        self.toolbar = toolbar
     }
        
    var body: some View {
        HStack {
            StandardRectangle(withTrailingPadding: false) {
                HStack {
                    Group {
                        UITextFieldWrapper(placeholder: placeholder, text: $text, onSubmit: {
                            if let onSubmit { onSubmit() }
                        }, onClear: {
                            if let onClear { onClear() }
                        }, onBeginEditing: {
                            if let onBeginEditing { onBeginEditing() }
                        }, toolbar: {
                            toolbar()
                        })
                        .uiFont(font)
                        .uiTextColor(foregroundColor)
                        .uiTint(tint)
                        .uiTextAlignment(multilineTextAlignment)
                        .uiTextContentType(contentType)
                        .uiAutoCorrectionDisabled(disableAutocorrection)
                        .uiAutoCapitalizationType(autocapitalizationType)
                        .uiKeyboardType(keyboardType)
                        .uiReturnKeyType(submitLabel)
                        .uiIsSecure(isSecure)
                        .uiClearsOnBeginEditing(clearsOnBeginEditing)
                        .uiClearButtonMode(clearButtonMode)
                        .uiDisabled(disabled)
                        .uiTag(focusValue)
                        .uiMaxLength(maxLength)
                        .uiStartCursorAtEnd(startCursorAtEnd)
                    }
                    .padding(.leading, isSearchField ? 24 : 0)
                    .focused($focusedField, equals: focusValue)
                    
                    /// This is needed to enable animation of the cancel button.
                    .onChange(of: focusedField, { oldValue, newValue in
                        if focusedField == focusValue {
                            withAnimation {
                                didFocus = newValue != nil
                            }
                        } else {
                            withAnimation {
                                didFocus = false
                            }
                        }
                    })
                    .overlay(
                        HStack {
                            if isSearchField {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            } else {
                                Spacer()
                            }
                        }
                    )
                    //.padding([.vertical, .leading], 6)
                    //            .padding(.leading, 0)
                    //            .background(Color(.tertiarySystemFill))
                    //            .cornerRadius(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            
            if (isSearchField && didFocus) || alwaysShowCancelButton {
                Button("Cancel") {
                    withAnimation {
                        text = ""
                        focusedField = nil
                        if let onCancel {
                            onCancel()
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .tint(Color.fromName(appColorTheme))
                .focusable(false)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    func formatDollarAmount(_ amount: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        guard let number = formatter.number(from: amount) else { return "" }
        return formatter.string(from: number)!
    }
}



extension StandardUITextField {
    func cbFont(_ font: UIFont?) -> StandardUITextField {
        var view = self
        view.font = font
        return view
    }

    func cbForgroundColor(_ color: UIColor?) -> StandardUITextField {
        var view = self
        view.foregroundColor = color
        return view
    }

    func cbTint(_ accentColor: UIColor?) -> StandardUITextField {
        var view = self
        view.tint = tint
        return view
    }

    func cbMultilineTextAlignment(_ alignment: NSTextAlignment) -> StandardUITextField {
        var view = self
        view.multilineTextAlignment = alignment
        return view
    }

    func cbTextContentType(_ textContentType: UITextContentType?) -> StandardUITextField {
        var view = self
        view.contentType = textContentType
        return view
    }

    func cbAutoCorrectionDisabled(_ disable: Bool?) -> StandardUITextField {
        var view = self
        view.disableAutocorrection = disable
        return view
    }

    func cbAutoCapitalization(_ style: UITextAutocapitalizationType) -> StandardUITextField {
        var view = self
        view.autocapitalizationType = style
        return view
    }

    func cbKeyboardType(_ type: UIKeyboardType) -> StandardUITextField {
        var view = self
        view.keyboardType = type
        return view
    }

    func cbSubmitLabel(_ type: UIReturnKeyType) -> StandardUITextField {
        var view = self
        view.submitLabel = type
        return view
    }

    func cbIsSecure(_ isSecure: Bool) -> StandardUITextField {
        var view = self
        view.isSecure = isSecure
        return view
    }

    func cbClearsOnBeginEditing(_ shouldClear: Bool) -> StandardUITextField {
        var view = self
        view.clearsOnBeginEditing = shouldClear
        return view
    }
    
    func cbClearButtonMode(_ mode: UITextField.ViewMode) -> StandardUITextField {
        var view = self
        view.clearButtonMode = mode
        return view
    }
    
    func cbDisabled(_ disabled: Bool) -> StandardUITextField {
        var view = self
        view.disabled = disabled
        return view
    }
    
    func cbFocused(_ focusField: FocusState<Int?>, equals value: Int) -> StandardUITextField {
        var view = self
        view._focusedField = focusField
        view.focusValue = value
        return view
    }
    
    func cbMaxLength(_ length: Int) -> StandardUITextField {
        var view = self
        view.maxLength = length
        return view
    }
    
    func cbStartCursorAtEnd(_ value: Bool) -> StandardUITextField {
        var view = self
        view.startCursorAtEnd = value
        return view
    }
    
    
    
    
    /// SwiftUI Only.
    func cbTextfieldInputType(_ value: TextFieldInputType) -> StandardUITextField {
        var view = self
        view.textFieldInputType = value
        return view
    }
    
    
    func cbIsSearchField(_ value: Bool) -> StandardUITextField {
        var view = self
        view.isSearchField = value
        return view
    }
    
    func cbAlwaysShowCancelButton(_ value: Bool) -> StandardUITextField {
        var view = self
        view.alwaysShowCancelButton = value
        return view
    }
}











struct UITextFieldWrapper<Toolbar: View>: UIViewRepresentable {
    var placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)?
    var onClear: (() -> Void)?
    var onBeginEditing: (() -> Void)?
    var toolbar: () -> Toolbar?
        
    private var font: UIFont?
    private var textColor: UIColor?
    private var tint: UIColor?
    private var textAlignment: NSTextAlignment?
    private var contentType: UITextContentType?
    private var autoCorrection: UITextAutocorrectionType = .default
    private var autocapitalizationType: UITextAutocapitalizationType = .sentences
    private var keyboardType: UIKeyboardType = .default
    private var returnKeyType: UIReturnKeyType = .default
    private var isSecure: Bool = false
    private var clearsOnBeginEditing: Bool = false
    private var clearButtonMode: UITextField.ViewMode?
    private var isUserInteractionEnabled: Bool = true
    private var tag: Int?
    private var maxLength: Int?
    private var startCursorAtEnd: Bool = false
    
    init(
        placeholder: String,
        text: Binding<String>,
        onSubmit: (() -> Void)? = nil,
        onClear: (() -> Void)? = nil,
        onBeginEditing: (() -> Void)? = nil,
        @ViewBuilder toolbar: @escaping () -> Toolbar? = { EmptyView() }
    ) {
        self.placeholder = placeholder
        self._text = text
        self.onSubmit = onSubmit
        self.onClear = onClear
        self.onBeginEditing = onBeginEditing
        self.toolbar = toolbar
     }
    
    
    func makeCoordinator() -> Coordinator {
        .init(text: $text, onSubmit: onSubmit, onClear: onClear, onBeginEditing: onBeginEditing, maxLength: maxLength, startCursorAtEnd: startCursorAtEnd)
    }
    
    func makeUIView(context: Context) -> UITextField {
        //print("-- \(#function) - \(text)")
        
        let textField = UITextField()
        textField.text = text
        
        if toolbar() is EmptyView { } else {
            let toolbarController = UIHostingController(rootView: toolbar())
            toolbarController.view.frame = .init(origin: .zero, size: toolbarController.view.intrinsicContentSize)
            textField.inputAccessoryView = toolbarController.view
        }
        
        textField.placeholder = placeholder
        textField.font = font
        textField.textColor = textColor
        textField.tintColor = tint
        if let textAlignment { textField.textAlignment = textAlignment }
        textField.textContentType = contentType
        textField.autocorrectionType = autoCorrection
        textField.autocapitalizationType = autocapitalizationType
        textField.keyboardType = keyboardType
        textField.returnKeyType = returnKeyType
        textField.isSecureTextEntry = isSecure
        textField.clearsOnBeginEditing = clearsOnBeginEditing
        if let clearButtonMode { textField.clearButtonMode = clearButtonMode }
        textField.isUserInteractionEnabled = isUserInteractionEnabled
        if let tag { textField.tag = tag }
        
        
        textField.delegate = context.coordinator
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }
        
        
    func updateUIView(_ textField: UITextField, context: Context) {
        //print("-- \(#function) --- \(text)")
        //DispatchQueue.main.async {
        textField.text = text
        
        textField.placeholder = placeholder
        textField.font = font
        textField.textColor = textColor
        textField.tintColor = tint
        if let textAlignment { textField.textAlignment = textAlignment }
        textField.textContentType = contentType
        textField.autocorrectionType = autoCorrection
        textField.autocapitalizationType = autocapitalizationType
        textField.keyboardType = keyboardType
        textField.returnKeyType = returnKeyType
        textField.isSecureTextEntry = isSecure
        textField.clearsOnBeginEditing = clearsOnBeginEditing
        if let clearButtonMode { textField.clearButtonMode = clearButtonMode }
        textField.isUserInteractionEnabled = isUserInteractionEnabled
        if let tag { textField.tag = tag }
        
        
        textField.delegate = context.coordinator
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        
        
        
        //}
    }
    
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var onSubmit: (() -> Void)?
        var onClear: (() -> Void)?
        var onBeginEditing: (() -> Void)?
        var maxLength: Int?
        var startCursorAtEnd: Bool
        //var onCancel: (() -> Void)?
                
        init(text: Binding<String>, onSubmit: (() -> Void)?, onClear: (() -> Void)?, onBeginEditing: (() -> Void)?, maxLength: Int?, startCursorAtEnd: Bool) {
            self._text = text
            self.onSubmit = onSubmit
            self.onClear = onClear
            self.onBeginEditing = onBeginEditing
            self.maxLength = maxLength
            self.startCursorAtEnd = startCursorAtEnd
            //self.onCancel = onCancel
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            print("-- \(#function)")
            if let onBeginEditing = onBeginEditing {
                onBeginEditing()
            }
            
            if startCursorAtEnd {
                DispatchQueue.main.async {
                    let newPosition = textField.endOfDocument
                    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                }
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            if let text = textField.text {
                self.text = text
            }
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            if let text = textField.text {
                self.text = text
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            print("-- \(#function)")
            if let onSubmit = onSubmit {
                onSubmit()
            }
            return true
        }
                
        func textFieldShouldClear(_ textField: UITextField) -> Bool {
            print("-- \(#function)")
            if let onClear = onClear {
                onClear()
            } else {
                self.text = ""
            }
            return true
        }
        
        
        
        // Use this if you have a UITextField
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // get the current text, or use an empty string if that failed
            let currentText = textField.text ?? ""

            // attempt to read the range they are trying to change, or exit if we can't
            guard let stringRange = Range(range, in: currentText) else { return false }

            // add their new text to the existing text
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

            // make sure the result is under 16 characters
            
            if let maxLength = maxLength {
                return updatedText.count <= maxLength
            } else {
                return true
            }
            
            
        }
        
        
    }
}



extension UITextFieldWrapper {
    func uiFont(_ font: UIFont?) -> UITextFieldWrapper {
        var view = self
        view.font = font
        return view
    }

    func uiTextColor(_ color: UIColor?) -> UITextFieldWrapper {
        var view = self
        view.textColor = color
        return view
    }

    func uiTint(_ accentColor: UIColor?) -> UITextFieldWrapper {
        var view = self
        view.tint = tint
        return view
    }

    func uiTextAlignment(_ alignment: NSTextAlignment?) -> UITextFieldWrapper {
        var view = self
        view.textAlignment = alignment
        return view
    }

    func uiTextContentType(_ textContentType: UITextContentType?) -> UITextFieldWrapper {
        var view = self
        view.contentType = textContentType
        return view
    }

    func uiAutoCorrectionDisabled(_ disable: Bool?) -> UITextFieldWrapper {
        var view = self
        if let disable = disable {
            view.autoCorrection = disable ? .no : .yes
        } else {
            view.autoCorrection = .default
        }
        return view
    }

    func uiAutoCapitalizationType(_ style: UITextAutocapitalizationType) -> UITextFieldWrapper {
        var view = self
        view.autocapitalizationType = style
        return view
    }

    func uiKeyboardType(_ type: UIKeyboardType) -> UITextFieldWrapper {
        var view = self
        view.keyboardType = type
        return view
    }

    func uiReturnKeyType(_ type: UIReturnKeyType) -> UITextFieldWrapper {
        var view = self
        view.returnKeyType = type
        return view
    }

    func uiIsSecure(_ isSecure: Bool) -> UITextFieldWrapper {
        var view = self
        view.isSecure = isSecure
        return view
    }

    func uiClearsOnBeginEditing(_ shouldClear: Bool) -> UITextFieldWrapper {
        var view = self
        view.clearsOnBeginEditing = shouldClear
        return view
    }
    
    func uiClearButtonMode(_ mode: UITextField.ViewMode?) -> UITextFieldWrapper {
        var view = self
        view.clearButtonMode = mode
        return view
    }
    
    func uiDisabled(_ disabled: Bool) -> UITextFieldWrapper {
        var view = self
        view.isUserInteractionEnabled = disabled
        return view
    }
    
    func uiTag(_ tag: Int?) -> UITextFieldWrapper {
        var view = self
        view.tag = tag
        return view
    }
    
    func uiMaxLength(_ length: Int?) -> UITextFieldWrapper {
        var view = self
        view.maxLength = length
        return view
    }
    
    func uiStartCursorAtEnd(_ value: Bool) -> UITextFieldWrapper {
        var view = self
        view.startCursorAtEnd = value
        return view
    }
}


#endif






