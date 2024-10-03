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
    var body: some Scene {
        DocumentGroup(newDocument: eWriter2Document()) { file in
            ContentView(document: file.$document)
                .onAppear {
                    print("Starting server...")
                    startServer()
                }
                .onDisappear {
                    stopServer()
                }
        }
                       
    }
    
    func startServer() {
            let htmlFilePath = Bundle.main.path(forResource: "index", ofType: "html") ?? ""
            
        DispatchQueue.global().async {
                    do {
                        try createServer(group: self.serverGroup, htmlFilePath: htmlFilePath) // Corrected scope
                    } catch {
                        print("Failed to start server: \(error)")
                    }
                }
        }
    
    func stopServer() {
            do {
                try serverGroup.syncShutdownGracefully()
            } catch {
                print("Error shutting down server: \(error)")
            }
        }
}
