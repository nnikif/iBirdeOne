//
//  ServerManager.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 06.10.2024.
//

import SwiftUI
import NIO

class ServerManager {
    static let shared = ServerManager()
    private var serverGroup: MultiThreadedEventLoopGroup?

    private init() {}

    func startServers() {
        if serverGroup == nil {
            serverGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        }

        guard let group = serverGroup else {
            return
        }

        let htmlFilePath = Bundle.main.path(forResource: "index", ofType: "html") ?? ""

        // Start the HTTP and WebSocket servers in parallel
        DispatchQueue.global().async {
            do {
                try startHTTPServer(group: group, htmlFilePath: htmlFilePath)
            } catch {
                print("Failed to start HTTP server: \(error)")
            }
        }

        DispatchQueue.global().async {
            do {
                try startWebSocketServer(group: group)
            } catch {
                print("Failed to start WebSocket server: \(error)")
            }
        }
    }

    func stopServers() {
        if let group = serverGroup {
            do {
                try group.syncShutdownGracefully()
                serverGroup = nil
            } catch {
                print("Failed to shut down server group: \(error)")
            }
        }
    }
}
