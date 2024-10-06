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
    
// The `@Environment` property to track app lifecycle changes
    @Environment(\.scenePhase) private var scenePhase

    
    var body: some Scene {
        DocumentGroup(newDocument: eWriter2Document()) { file in
            ContentView(document: file.$document)
        
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
                    switch newPhase {
                    case .active:
                        // Resume the server when the app becomes active
                        print("App is active. Starting server...")
                        ServerManager.shared.startServers()
                    case .background:
                        // Stop the server when the app goes to the background
                        print("App is in the background. Stopping server...")
                        ServerManager.shared.stopServers()
                    default:
                        break
                    }
                }
                       
    }
    
}
