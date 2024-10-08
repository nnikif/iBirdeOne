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
//            print("fixing text view: '\(textView.text)")
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
    let concurrentQueue = DispatchQueue(label: "com.example.concurrentQueue", attributes: .concurrent)

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
            if sharedState.cutCommandIssued {
                uiView.cut(nil)
                DispatchQueue.main.async {
                    sharedState.cutCommandIssued = false
                }
           }
            
            let currentCursor = uiView.selectedRange.location
            if sharedState.cursorMoved && currentCursor != sharedState.cursorPosition {
                let positionRange = NSRange(location: sharedState.cursorPosition, length: 0)
                uiView.selectedRange = positionRange // Move the cursor to the shared state cursor position
                DispatchQueue.main.async {
                    sharedState.cursorMoved = false
                }
            }
            
            if sharedState.selectionMoved {
                let startSelection = Optional(sharedState.startSelection), endSelection = Optional(sharedState.endSelection)
                guard let startSelection = startSelection, let endSelection = endSelection else {
                    DispatchQueue.main.async {
                        sharedState.selectionMoved = false
                    }
                        return
                    }
                let selectionRangeNumbers =  [startSelection, endSelection]
                if let minValue = selectionRangeNumbers.min(), let maxValue = selectionRangeNumbers.max(){
                    let selectionRange = NSRange(location: minValue, length: (maxValue - minValue))
                    uiView.selectedRange = selectionRange // Update the selection range
                    DispatchQueue.main.async {
                        sharedState.selectionMoved = false
                    }
                }
            }
            if sharedState.copyComandIssued {
                uiView.copy(nil)
                let newCursorPosition = uiView.selectedRange.location + uiView.selectedRange.length
                        uiView.selectedRange = NSRange(location: newCursorPosition, length: 0)
                        
                        // Update shared state
                        DispatchQueue.main.async {
                            self.sharedState.copyComandIssued = false
                            self.sharedState.cursorPosition = newCursorPosition
                            self.sharedState.startSelection = newCursorPosition
                            self.sharedState.endSelection = newCursorPosition
                            self.sharedState.cursorMoved = true
                        }
            }
            if sharedState.pasteCommandIssued {
                uiView.paste(nil)

//                pasteTextFromAppClipboard(into: uiView)
                DispatchQueue.main.async {
                    sharedState.pasteCommandIssued = false
                }
            }
                if sharedState.undoCommandIssued {
                if let undoManager = uiView.undoManager, undoManager.canUndo {
                    undoManager.undo()
                    
                }
                DispatchQueue.main.async {
                    self.sharedState.undoCommandIssued = false
                }
            }

            // Perform redo operation
        if sharedState.redoCommandIssued {
            if let undoManager = uiView.undoManager, undoManager.canRedo {
                undoManager.redo()
                
             }
            DispatchQueue.main.async {
                self.sharedState.redoCommandIssued = false
                
            }
        }
        if sharedState.toggleItalicCommandIssued {
            toggleMarkdownInTextView(uiView, type: .italic)
        }
        
        if sharedState.toggleBoldCommandIssued {
            toggleMarkdownInTextView(uiView, type: .bold)
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
    
    func toggleMarkdownInTextView(_ textView: UITextView, type: MarkdownType ) {
        
        let selectedRange = textView.selectedRange
        
        // Ensure there's selected text
        guard selectedRange.length > 0 else {
            return
        }
        
        // Get the full text
        guard let text = textView.text else {
            return
        }
        
        
        // Convert NSRange to Range<String.Index>
        guard let textRange = Range(selectedRange, in: text) else {
            // Handle invalid range
            return
        }
        
        // Get the selected text
        let selectedText = String(text[textRange])
        
        // Toggle italics formatting
        let toggledText = toggleMarkdownFormatting(for: selectedText, type: type)
        
        
        // Create a new text string with the toggled text
        let newText = text.replacingCharacters(in: textRange, with: toggledText)
        
        // Update the UITextView's text
        textView.text = newText
        
        // Adjust the selected range
        let newSelectedRange = NSRange(location: selectedRange.location, length: toggledText.count)
        textView.selectedRange = newSelectedRange
        
        // Update the @Binding text
        DispatchQueue.main.async {
            self.text = newText
        }
        
        // Prepare variables for closure capture
        let previousText = text
        let previousSelectedRangeLocation = selectedRange.location
        let previousSelectedRangeLength = selectedRange.length
        
        // Register undo operation
        if let undoManager = textView.undoManager {
            undoManager.registerUndo(withTarget: textView) { target in
                // Restore the original text
                target.text = previousText
                target.selectedRange = NSRange(location: previousSelectedRangeLocation, length: previousSelectedRangeLength)
                
                // Update the @Binding text in the undo operation
                DispatchQueue.main.async {
                    self.text = previousText
                }
            }
        }
        
        // Update the shared state
        DispatchQueue.main.async {
            SharedTextState.shared.cursorPosition = newSelectedRange.location
            SharedTextState.shared.startSelection = newSelectedRange.location
            SharedTextState.shared.endSelection = newSelectedRange.location + newSelectedRange.length
            switch type {
                case .bold:
                    SharedTextState.shared.toggleBoldCommandIssued = false
                case .italic:
                    SharedTextState.shared.toggleItalicCommandIssued = false
            }
        }
    }

}

class SharedTextState: ObservableObject {
    static let shared = SharedTextState()
    @Published var text: String = ""
    
    @Published var cursorPosition: Int = 0 // The shared cursor position
    @Published var startSelection: Int = 0
    @Published var endSelection: Int = 0
    @Published var cursorMoved: Bool = false
    @Published var selectionMoved: Bool = false
    @Published var copyComandIssued: Bool = false
    @Published var pasteCommandIssued: Bool = false
    @Published var cutCommandIssued: Bool = false
    @Published var redoCommandIssued: Bool = false
    @Published var undoCommandIssued: Bool = false
    @Published var toggleItalicCommandIssued: Bool = false
    @Published var toggleBoldCommandIssued: Bool = false
    
    private init() {} // Singleton pattern
}



func pasteTextFromAppClipboard(into uiView: UITextView) {
    // Get the text from the clipboard
    guard let clipboardText = UIPasteboard.general.string else { return }
    DispatchQueue.main.async {
        uiView.insertText(" "+clipboardText)
    }
}
