//
//  WebSocketHandler.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 03.10.2024.
//


import Foundation
import NIO
import NIOHTTP1
import NIOWebSocket

final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let frame = self.unwrapInboundIn(data)
            
            // Check if the frame contains a text message
            if frame.opcode == .text {
                var data = frame.data
                if let message = data.readString(length: data.readableBytes) {
                    print("Received message: \(message)")
                    
                    // For simplicity, let's send back a fixed text content
                    let responseMessage = "This is the content from the server"
                    var buffer = context.channel.allocator.buffer(capacity: responseMessage.count)
                    buffer.writeString(responseMessage)
                    let responseFrame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
                    context.writeAndFlush(self.wrapOutboundOut(responseFrame), promise: nil)
                }
            }
        }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("WebSocket error: \(error)")
        context.close(promise: nil)
    }
}

func setupWebSocketServer(group: EventLoopGroup) throws {
    let bootstrap = ServerBootstrap(group: group)
        .childChannelInitializer { channel in
            let upgrader = NIOWebSocketServerUpgrader(shouldUpgrade: { (_, _) in
                channel.eventLoop.makeSucceededFuture([:])
            }, upgradePipelineHandler: { (channel, _) in
                channel.pipeline.addHandler(WebSocketHandler())
            })

            return channel.pipeline.configureHTTPServerPipeline(
                withServerUpgrade: (upgraders: [upgrader], completionHandler: { ctx in
                    ctx.fireChannelRead(NIOAny(HTTPServerRequestPart.end(nil)))
                })
            )
        }
        .serverChannelOption(ChannelOptions.backlog, value: 256)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

    let serverChannel = try bootstrap.bind(host: "0.0.0.0", port: 8585).wait()
    print("WebSocket server running on: \(serverChannel.localAddress!)")
    try serverChannel.closeFuture.wait()
}
