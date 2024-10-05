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
    @State private var showOverlay = false
    @State private var ipAddress: String = "Fetching IP..."

//    let webSocketHandler: WebSocketHandler
        
    var body: some View {
        ZStack {
            VStack {
            // Use custom UITextView to track selected text and cursor
            TextViewWithSelectionObserver(
                text: $document.text,
                cursorPosition: $cursorPosition,
                startSelection: $startSelection,
                endSelection: $endSelection,
                onSelectionChange: { cursorPosition, startSelection, endSelection in
                    sendCursorSelectionUpdate(cursorPosition: cursorPosition, startSelection: startSelection, endSelection: endSelection)
                }
                
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .onChange(of: document.text) { oldValue, newValue in
                sendDocumentUpdate(oldText: oldValue, newText: newValue)
            }
            .onAppear {
                       ipAddress = getWiFiAddress() ?? "Unable to fetch IP"
                   }
                
            Button(action: {
                // Toggle the overlay when button is pressed
                showOverlay.toggle()
            }) {
                Text("Hide Screen")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
                Text("Open this address in a web browser:")
                                .font(.headline)
                                .padding()

                            Text(ipAddress+":8787")
                                .font(.title)
                                .padding()
            
//            Text("Cursor position: \(cursorPosition)")
//                .padding()
//            
//            // Optionally show selected text range (start and end character positions)
//            if let start = startSelection, let end = endSelection {
//                Text("Selected text: Start at \(start), End at \(end)")
//                    .padding()
//            }
        }
            if showOverlay {
                           Color.black // Fully opaque black overlay
                               .ignoresSafeArea()   // Ensure the overlay covers the entire screen
                               .onTapGesture {
                                   // Restore the interface when the screen is touched
                                   showOverlay = false
                               }
                       }
            
    }
        }
}

func sendCursorSelectionUpdate(cursorPosition: Int, startSelection: Int?, endSelection: Int?) {
        let cursorData: [String: Any?] = [
            "cursorPosition": cursorPosition,
            "startSelection": startSelection,
            "endSelection": endSelection
        ]
        let update: [String: Any] = [
            "content": cursorData,
            "mType": "cursorUpdate"
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: update, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.025){
                WebSocketBroadcaster.shared.broadcast(message: jsonString)
            }
        }
    }

func sendDocumentUpdate(oldText: String, newText: String) {
    WebSocketBroadcaster.shared.documentText = newText
    // Implement your diff logic here
    if let diffString = convertDiffToJSONString(oldText: oldText, newText: newText) {
        let update: [String: Any] = [
            "content": diffString,
            "mType": "diff"
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: update, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
//            print("jsonString DIFF: '\(jsonString)")
            WebSocketBroadcaster.shared.broadcast(message: jsonString)
        }
    }
}


#Preview {
    ContentView(document: .constant(eWriter2Document()))
}
