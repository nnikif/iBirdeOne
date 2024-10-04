//
//  TextViewCoordinator.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 04.10.2024.
//


import SwiftUI
import UIKit

// Coordinator for handling cursor position changes
class TextViewCoordinator: NSObject, UITextViewDelegate {
    var parent: TextViewWithSelectionObserver
        
        init(_ parent: TextViewWithSelectionObserver) {
            self.parent = parent
        }
    
    // Track text changes and propagate back to SwiftUI
    func textViewDidChange(_ textView: UITextView) {
        DispatchQueue.main.async {
            self.parent.text = textView.text // Sync text changes with SwiftUI
        }
    }
    
    // Track cursor position changes and update state
    func textViewDidChangeSelection(_ textView: UITextView) {
        let cursorPosition = textView.selectedRange.location
        DispatchQueue.main.async {
                    self.parent.cursorPosition = cursorPosition // Track cursor position

                    // Get the selected range
                    let startPosition = textView.selectedRange.location
                    let endPosition = startPosition + textView.selectedRange.length

                    // Update start and end character positions
                    self.parent.startSelection = startPosition
                    self.parent.endSelection = endPosition
                    
                    print("Selected text range: Start \(startPosition), End \(endPosition)")
                    self.parent.onSelectionChange?(cursorPosition, startPosition, endPosition)
                }


    }
}

// UITextView wrapper with cursor tracking
struct TextViewWithSelectionObserver: UIViewRepresentable {
    @Binding var text: String
    @Binding var cursorPosition: Int
    @Binding var startSelection: Int? // Track the start of the selected text
    @Binding var endSelection: Int?
    
    var onSelectionChange: ((Int, Int?, Int?) -> Void)?


    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.text = text // Set initial text
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text // Update UITextView if text changes
        }
    }
    
    func makeCoordinator() -> TextViewCoordinator {
        return TextViewCoordinator(self)
    }
}
