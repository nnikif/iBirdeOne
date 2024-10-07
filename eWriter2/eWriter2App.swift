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
    
    @StateObject private var appConfig = AppConfiguration() // Create AppConfiguration as a @StateObject
    @State private var showSettings = false

    var body: some Scene {
        DocumentGroup(newDocument: eWriter2Document()) { file in
            ContentView(document: file.$document)
                .environmentObject(appConfig)
                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button(action: {
                                            // Action for opening settings or another view
                                            showSettings = true
                                            print("Settings button tapped")
                                        }) {
                                            Text("Open Settings")
                                                .font(.headline)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
            
                .sheet(isPresented: $showSettings) { // Handle modal at the App level
                            SettingsView()
                                .environmentObject(appConfig)
                        }
        }
        
        .onChange(of: scenePhase) { oldPhase, newPhase in
                    switch newPhase {
                    case .active:
                        // Resume the server when the app becomes active
                        print("App is active. Starting server...")
                        ServerManager.shared.startServers(config: appConfig)
                        UIApplication.shared.isIdleTimerDisabled = true
                    case .background:
                        // Stop the server when the app goes to the background
                        print("App is in the background. Stopping server...")
                        ServerManager.shared.stopServers()
                        UIApplication.shared.isIdleTimerDisabled = false
                    default:
                        break
                    }
                }
        WindowGroup("Settings") {
                    NavigationView {
                        SettingsView()
                    }
                }
        .environmentObject(appConfig)
                       
    }
    
}
