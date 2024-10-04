import NIO
import NIOHTTP1
import NIOWebSocket
import Foundation
import SwiftUI

struct WebSocketResponse: Codable {
    let content: String
    let mType: String
}

final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame
    private var documentText: String?
    private var channel: Channel?
    private var context: ChannelHandlerContext?
    

//        init(document: eWriter2Document) {
//            self.documentText = document.text
//        }
    init(){
        
    }
        
        // Manually update the document reference if needed
    func updateDocument(documentText: String, oldText: String) {
            self.documentText = documentText
            if let channel = channel {
                sendUpdatedDocumentContent(on: channel, oldText: oldText, newText: documentText)
                    }
        }
    
    func handlerAdded(context: ChannelHandlerContext) {
            self.channel = context.channel
            self.context = context
    
        }
    
    func sendCursorSelectionUpdate(cursorPosition: Int, startSelection: Int?, endSelection: Int?) {
        guard let context = self.context else {
            print("No context available for sending data.")
            return
        }

            let cursorJson = ["cursorPosition": cursorPosition, "startSelection": startSelection, "endSelection": endSelection]
            let cursorUpdate = try? JSONEncoder().encode(cursorJson)
            let cursorString = String(data: cursorUpdate!, encoding: .utf8)
            let update = WebSocketResponse(
                content: cursorString ?? "",
                mType: "cursorUpdate"
            )

            if let jsonData = try? JSONEncoder().encode(update) {
                var buffer = context.channel.allocator.buffer(capacity: jsonData.count)
                buffer.writeBytes(jsonData)
                let responseFrame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
                context.writeAndFlush(self.wrapOutboundOut(responseFrame), promise: nil)
            }
        }

    
    func sendUpdatedDocumentContent(on channel: Channel, oldText: String, newText: String) {
//            let fileContent = self.documentText
            let diffJson = convertDiffToJSONString(oldText: oldText, newText: newText)
        
            guard let diffJson = diffJson else {
                print("Failed to generate diff JSON")
                // Handle the nil case, e.g., return or send an error response
                return
            }
            // Create a JSON response
            let response = WebSocketResponse(
                content: diffJson,
                mType: "diff"
            )
            
            // Encode the struct as JSON
            if let jsonData = try? JSONEncoder().encode(response) {
                var buffer = channel.allocator.buffer(capacity: jsonData.count)
                buffer.writeBytes(jsonData)
                let responseFrame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
                
                // Send the JSON response
                channel.writeAndFlush(self.wrapOutboundOut(responseFrame), promise: nil)
            }
        }
    

    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        self.context = context
        let frame = self.unwrapInboundIn(data)
//        print("Frame received: \(frame)")
        
        
        if frame.opcode == .text {
            var data = frame.unmaskedData
            if let byteArray = data.readBytes(length: data.readableBytes) {
                if let message = String(bytes: byteArray, encoding: .utf8) {
//                    print("Decoded message: \(message)")
                    
                    // Try to parse the message as JSON
                    if let jsonData = message.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let requestType = jsonObject["request"] as? String {
                        
                        // Only respond if the request is 'getContent'
                        if requestType == "getContent" {
                            
                            if let fileContent = self.documentText {
                                
                                // Create the response struct
                                let response = WebSocketResponse(content: fileContent, mType: "reload")
                                
                                // Encode the struct as JSON
                                if let jsonData = try? JSONEncoder().encode(response) {
                                    var buffer = context.channel.allocator.buffer(capacity: jsonData.count)
                                    buffer.writeBytes(jsonData)
                                    let responseFrame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
                                    
                                    // Send the JSON response
                                    context.writeAndFlush(self.wrapOutboundOut(responseFrame), promise: nil)
                                } else {
                                    print("Failed to encode JSON response")
                                }
                            }
                        } else {
                            print("Unknown request type: \(requestType)")
                        }
                    } else {
                        print("Failed to parse JSON or invalid format")
                    }
                }
            }
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("WebSocket error: \(error)")
        context.close(promise: nil)
    }
}

func startWebSocketServer(group: EventLoopGroup, handler: WebSocketHandler) throws {
    let bootstrap = ServerBootstrap(group: group)
        .childChannelInitializer { channel in
            let upgrader = NIOWebSocketServerUpgrader(shouldUpgrade: { (_, _) in
                channel.eventLoop.makeSucceededFuture([:])
            }, upgradePipelineHandler: { (channel, _) in
                channel.pipeline.addHandler(handler)
            })
            
            return channel.pipeline.configureHTTPServerPipeline(
                withServerUpgrade: (upgraders: [upgrader], completionHandler: { ctx in
                    ctx.fireChannelRead(NIOAny(HTTPServerRequestPart.end(nil)))
                })
            )
        }
        .serverChannelOption(ChannelOptions.backlog, value: 256)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

    let serverChannel = try bootstrap.bind(host: "0.0.0.0", port: 7789).wait()
    print("WebSocket server running on: \(serverChannel.localAddress!)")
    
    try serverChannel.closeFuture.wait()
}

class WebSocketHandlerContainer: ObservableObject {
//    @Published var handler: WebSocketHandler?
    var handler: WebSocketHandler

    init(handler: WebSocketHandler) {
        self.handler = handler
    }

}
