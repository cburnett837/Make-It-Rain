//
//  EditorExample.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/7/25.
//


import SwiftUI

#if os(iOS)

struct UITextEditorWrapper<Toolbar: View>: UIViewRepresentable {
    var placeholder: String
    @Binding var text: String
    var toolbar: () -> Toolbar?
    
    init(
        placeholder: String,
        text: Binding<String>,
        @ViewBuilder toolbar: @escaping () -> Toolbar? = { EmptyView() }
    ) {
        self.placeholder = placeholder
        self._text = text
        self.toolbar = toolbar
     }
    
    
    func makeCoordinator() -> Coordinator {
        .init(placeholder: placeholder, text: $text)
    }
    
    
    func makeUIView(context: Context) -> UITextView {
        let textView: UITextView = {
            let textView = UITextView()
            //textView.font = UIFont(name: "Helvetica", size: 30.0)
            textView.delegate = context.coordinator
            textView.text = text
            textView.textColor = UIColor.lightGray
            
            if toolbar() is EmptyView { } else {
                let toolbarController = UIHostingController(rootView: toolbar())
                toolbarController.view.frame = .init(origin: .zero, size: toolbarController.view.intrinsicContentSize)
                textView.inputAccessoryView = toolbarController.view
            }
            
            return textView
        }()
        
        
        
        //textView.text = placeholder
        //textView.textColor = UIColor.lightGray
        return textView
    }
        
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var placeholder: String
        @Binding var text: String
        
        init(placeholder: String, text: Binding<String>) {
            self.placeholder = placeholder
            self._text = text
        }
                                
        func textViewDidChange(_ textView: UITextView) {
            if let text = textView.text {
                self.text = text
            }
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == UIColor.lightGray {
                textView.text = nil
                textView.textColor = UIColor.label
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = placeholder
                textView.textColor = UIColor.lightGray
            }
        }
        
        
        func textViewDidChangeSelection(_ textView: UITextView) {
           // selectedRange = textView.selectedRange
        }
        
        @objc func underline(_ textView: UITextView) {
            let range = textView.selectedRange
            if (range.length > 0) {
                textView.textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
              //  stringDidChange?(textView.textStorage)
            }
        }
    }
}




struct EditorExample: UIViewRepresentable {
    //@Binding var outerMutableString: NSMutableAttributedString
    @Binding var outerMutableString2: String
    
    // this is called first
    func makeCoordinator() -> Coordinator {
        // we can't pass in any values to the Coordinator because they will be out of date when update is called the second time.
        Coordinator()
    }
    
    // this is called second
    func makeUIView(context: Context) -> UITextView {
        context.coordinator.textView.text = "Placeholder"
        context.coordinator.textView.textColor = UIColor.lightGray
        return context.coordinator.textView
    }
    
    // this is called third and then repeatedly every time a let or `@Binding var` that is passed to this struct's init has changed from last time.
    func updateUIView(_ uiView: UITextView, context: Context) {
        //uiView.attributedText = outerMutableString
        uiView.text = outerMutableString2

        // we don't usually pass bindings in to the coordinator and instead use closures.
        // we have to set a new closure because the binding might be different.
        
         context.coordinator.stringDidChange2 = { string in
            outerMutableString2 = string
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        
        lazy var textView: UITextView = {
            let textView = UITextView()
            textView.font = UIFont(name: "Helvetica", size: 30.0)
            textView.delegate = self
            // make toolbar
            let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: textView.frame.size.width, height: 44))
            // make toolbar underline button
            let underlineButton = UIBarButtonItem(
                image: UIImage(systemName: "underline"),
                style: .plain,
                target: self,
                action: #selector(underline))
            toolBar.items = [underlineButton]
            textView.inputAccessoryView = toolBar
            return textView
        }()
        
        //var stringDidChange: ((NSMutableAttributedString) -> ())?
        var stringDidChange2: ((String) -> ())?
        
        func textViewDidChange(_ textView: UITextView) {
            //innerMutableString = textView.textStorage
            //stringDidChange?(textView.textStorage)
            stringDidChange2?(textView.text)
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == UIColor.lightGray {
                textView.text = nil
                textView.textColor = UIColor.black
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = "Placeholder"
                textView.textColor = UIColor.lightGray
            }
        }
        
        
        func textViewDidChangeSelection(_ textView: UITextView) {
           // selectedRange = textView.selectedRange
        }
        
        @objc func underline() {
            let range = textView.selectedRange
            if (range.length > 0) {
                textView.textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
              //  stringDidChange?(textView.textStorage)
            }
        }
    }
}
#endif
