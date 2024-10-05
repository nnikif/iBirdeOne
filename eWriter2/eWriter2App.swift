//
//  eWriter2App.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 03.10.2024.
//

import SwiftUI
import NIO
import NIOHTTP1


@main
struct eWriter2App: App {
    private let serverGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    @StateObject var webSocketHandlerContainer = WebSocketHandlerContainer(handler: WebSocketHandler())
    var body: some Scene {
        DocumentGroup(newDocument: eWriter2Document()) { file in
            ContentView(document: file.$document)
                .onAppear {
//                    print("Starting server...")
//                    startServers(with: file.document)
//                    webSocketHandlerContainer.handler = WebSocketHandler()
                    startServers(with: file.document)
                }
                .onDisappear {
                    stopServers()
                }
//                .onChange(of: file.document.text) { oldValue, newValue in
////                                    print("Document text changed: \(newValue)")
//                                    // Explicitly notify the WebSocket handler of the change
//                    webSocketHandlerContainer.handler.updateDocument(documentText: newValue, oldText: oldValue)
//                    
//
//                                }
        }
                       
    }
    
    func startServers(with document: eWriter2Document) {
            let htmlFilePath = Bundle.main.path(forResource: "index", ofType: "html") ?? ""

            // Start the HTTP and WebSocket servers in parallel
            DispatchQueue.global().async {
                do {
                    try startHTTPServer(group: self.serverGroup, htmlFilePath: htmlFilePath)
                } catch {
                    print("Failed to start HTTP server: \(error)")
                }
            }

        DispatchQueue.global().async {
                    do {
                        try startWebSocketServer(group: serverGroup)
                    } catch {
                        print("Failed to start WebSocket server: \(error)")
                    }
                }
        }
        
        func stopServers() {
            do {
                try serverGroup.syncShutdownGracefully()
            } catch {
                print("Error shutting down servers: \(error)")
            }
        }
    
    
}
