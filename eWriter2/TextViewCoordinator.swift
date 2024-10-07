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
    var textView: UITextView?
    
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
            self.parent.onSelectionChange?(cursorPosition, startPosition, endPosition)
        }
    }
    // Move the cursor programmatically
    func moveCursor(to position: Int) {
            DispatchQueue.main.async {
                if let textView = self.textView { // Now the textView reference is stored in the coordinator
                    let positionRange = NSRange(location: position, length: 0)
                    textView.selectedRange = positionRange
                    // Update cursor position in parent state
                    self.parent.cursorPosition = position
                }
            }
        }
}


// UITextView wrapper with cursor tracking
struct TextViewWithSelectionObserver: UIViewRepresentable {
    @Binding var text: String
    @Binding var cursorPosition: Int
    @Binding var startSelection: Int? // Track the start of the selected text
    @Binding var endSelection: Int?
    @State private var coordinatorInstance: TextViewCoordinator?
    
    var onSelectionChange: ((Int, Int?, Int?) -> Void)?
    
    @ObservedObject var sharedState = SharedTextState.shared


    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.text = text // Set initial text
        self.coordinatorInstance = context.coordinator

        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text // Update UITextView if text changes
        }
        let currentCursor = uiView.selectedRange.location
        if sharedState.cursorMoved && currentCursor != sharedState.cursorPosition {
            let positionRange = NSRange(location: sharedState.cursorPosition, length: 0)
            uiView.selectedRange = positionRange // Move the cursor to the shared state cursor position
            sharedState.cursorMoved = false;
        }

    }
    
    func makeCoordinator() -> TextViewCoordinator {
        return TextViewCoordinator(self)
    }
    
    func moveCursor(to position: Int) {
            SharedTextState.shared.cursorPosition = position // Update shared state
        }
}

class SharedTextState: ObservableObject {
    static let shared = SharedTextState()
    
    @Published var cursorPosition: Int = 0 // The shared cursor position
    @Published var cursorMoved: Bool = false
//    @Published var documentText: String = "" // Shared text document

    private init() {} // Singleton pattern
}
