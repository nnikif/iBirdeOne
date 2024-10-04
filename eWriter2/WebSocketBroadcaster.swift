//
//  WebSocketBroadcaster.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 04.10.2024.
//


import NIO
import NIOWebSocket
import SwiftUI

final class WebSocketBroadcaster {
    static let shared = WebSocketBroadcaster()
    private var connectedChannels = [ObjectIdentifier: Channel]()
    private let queue = DispatchQueue(label: "WebSocketBroadcasterQueue")
    var documentText: String = ""

    private init() {}

    func addChannel(_ channel: Channel) {
        queue.sync {
            connectedChannels[ObjectIdentifier(channel)] = channel
        }
    }

    func removeChannel(_ channel: Channel) {
        queue.sync {
            connectedChannels.removeValue(forKey: ObjectIdentifier(channel))
        }
    }

    func broadcast(message: String) {
        queue.sync {
            for (_, channel) in connectedChannels {
                var buffer = channel.allocator.buffer(capacity: message.utf8.count)
                buffer.writeString(message)
                let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
                channel.writeAndFlush(frame, promise: nil)
            }
        }
    }
}
