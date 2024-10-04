//
//  ContentView.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 03.10.2024.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: eWriter2Document
//    let webSocketHandler: WebSocketHandler
    
    @State private var cursorPosition: Int = 0 // Track the cursor position
    @State private var startSelection: Int? = nil // Track start of the selection
    @State private var endSelection: Int? = nil
//    let webSocketHandler: WebSocketHandler
        
    var body: some View {
            VStack {
                // Use custom UITextView to track selected text and cursor
                TextViewWithSelectionObserver(
                    text: $document.text,
                    cursorPosition: $cursorPosition,
                    startSelection: $startSelection,
                    endSelection: $endSelection
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                
                
                Text("Cursor position: \(cursorPosition)")
                                .padding()

                            // Optionally show selected text range (start and end character positions)
                            if let start = startSelection, let end = endSelection {
                                Text("Selected text: Start at \(start), End at \(end)")
                                    .padding()
                            }
            }
        
        }
}

#Preview {
    ContentView(document: .constant(eWriter2Document()))
}
