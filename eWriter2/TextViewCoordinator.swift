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
    
    // Track cursor position and selection range changes and update state
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
    
    // Move the cursor or update the selection programmatically
    func updateSelection(start: Int, end: Int) {
        DispatchQueue.main.async {
            if let textView = self.textView {
                let length = max(0, end - start)
                let selectionRange = NSRange(location: start, length: length)
                textView.selectedRange = selectionRange
                
                // Update cursor and selection positions in parent state
                self.parent.cursorPosition = start
                self.parent.startSelection = start
                self.parent.endSelection = end
            }
        }
    }
}

// UITextView wrapper with cursor and selection tracking
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
            sharedState.cursorMoved = false
        }
        
        if sharedState.selectionMoved {
            let startSelection = Optional(sharedState.startSelection), endSelection = Optional(sharedState.endSelection)
            guard let startSelection = startSelection, let endSelection = endSelection else {
                    return
                }
            let selectionRangeNumbers =  [startSelection, endSelection]
            if let minValue = selectionRangeNumbers.min(), let maxValue = selectionRangeNumbers.max(){
//                print("minValue: \(minValue), maxValue: \(maxValue)")
                let selectionRange = NSRange(location: minValue, length: (maxValue - minValue))
                uiView.selectedRange = selectionRange // Update the selection range
                sharedState.selectionMoved = false
            
            }
                
        }
    }
    
    func makeCoordinator() -> TextViewCoordinator {
        return TextViewCoordinator(self)
    }
    
    func updateSelection(start: Int, end: Int) {
        SharedTextState.shared.startSelection = start
        SharedTextState.shared.endSelection = end
        SharedTextState.shared.selectionMoved = true
    }
}

class SharedTextState: ObservableObject {
    static let shared = SharedTextState()
    
    @Published var cursorPosition: Int = 0 // The shared cursor position
    @Published var startSelection: Int = 0
    @Published var endSelection: Int = 0
    @Published var cursorMoved: Bool = false
    @Published var selectionMoved: Bool = false
    
    private init() {} // Singleton pattern
}
