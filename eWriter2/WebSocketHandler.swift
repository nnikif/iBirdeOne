import NIO
import NIOHTTP1
import NIOWebSocket
import Foundation
import SwiftUI
import SystemConfiguration.CaptiveNetwork
import Network

struct WebSocketResponse: Codable {
    let content: String
    let mType: String
}

final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame

    func handlerAdded(context: ChannelHandlerContext) {
        WebSocketBroadcaster.shared.addChannel(context.channel)
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        WebSocketBroadcaster.shared.removeChannel(context.channel)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let frame = unwrapInboundIn(data)
            if frame.opcode == .text {
                var data = frame.unmaskedData
                if let byteArray = data.readBytes(length: data.readableBytes) {
                    if let message = String(bytes: byteArray, encoding: .utf8) {
                                            print("Decoded message: \(message)")
                        
                        // Try to parse the message as JSON
                        if let jsonData = message.data(using: .utf8),
                           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                           let requestType = jsonObject["request"] as? String {
                            switch requestType {
                            case "getContent":
                                let fileContent = WebSocketBroadcaster.shared.documentText
                                let paragraphs = splitTextIntoParagraphs(text: fileContent)
                                let messageObject = MessageObject(messageType:"paragraphReset", details: stringifyArrayofString(arrayData: paragraphs), cursorPositon: nil)
                                let jsonString = convertJSONToString(jsonObject: messageObject.toDictionary())
                                WebSocketBroadcaster.shared.broadcast(message: jsonString)
                            case "cutToClipboard":
                                DispatchQueue.main.async {
                                    SharedTextState.shared.cutCommandIssued = true
                                }
                            case "moveCursor":
                                if let newCursorPosition = jsonObject["cursorPosition"] as? Int {
                                    DispatchQueue.main.async {
                                        SharedTextState.shared.cursorMoved = true
                                        SharedTextState.shared.cursorPosition = recalculateCursorPosition(text: WebSocketBroadcaster.shared.documentText, position: newCursorPosition)
                                        
                                    }
                                }
                            case "selectionChange":
                                if let selectionStart = jsonObject["selectionStart"] as? Int {
                                   if let selectionEnd = jsonObject["selectionEnd"] as? Int {
                                       DispatchQueue.main.async {
                                           SharedTextState.shared.startSelection = recalculateSelectionPosition(text: WebSocketBroadcaster.shared.documentText, position: selectionStart, start: true)
                                           
                                       }
                                       DispatchQueue.main.async {
                                           SharedTextState.shared.selectionMoved = true
                                           SharedTextState.shared.endSelection = recalculateSelectionPosition(text: WebSocketBroadcaster.shared.documentText, position: selectionEnd, start: false)
                                           
                                       }
                                    }
                                }
                            case "copyToClipboard":
                                DispatchQueue.main.async {
                                    SharedTextState.shared.copyComandIssued = true
                                }
                            case "pasteFromClipboard":
                                DispatchQueue.main.async {
                                    SharedTextState.shared.pasteCommandIssued = true
                                }
                            case "undoCommand":
                                DispatchQueue.main.async {
                                    SharedTextState.shared.undoCommandIssued = true
                                }
                            case "redoCommand":
                                DispatchQueue.main.async {
                                    SharedTextState.shared.redoCommandIssued = true
                                }
                            case "toggleBold":
                                DispatchQueue.main.async {
                                    SharedTextState.shared.toggleBoldCommandIssued = true
                                }
                            case "toggleItalics":
                                DispatchQueue.main.async {
                                    SharedTextState.shared.toggleItalicCommandIssued = true
                                }
                            default:
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




func getWiFiAddress() -> String? {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>?

    if getifaddrs(&ifaddr) == 0 {
        var pointer = ifaddr
        while pointer != nil {
            let interface = pointer?.pointee
            let addrFamily = interface?.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                if let name = interface?.ifa_name {
                    let nameString = String(cString: name)
                    if nameString == "en0" || nameString == "pdp_ip0" { // "en0" is the WiFi interface on iOS
                        var addr = interface!.ifa_addr.pointee
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(&addr, socklen_t(interface!.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            pointer = pointer?.pointee.ifa_next
        }
        freeifaddrs(ifaddr)
    }

    return address
}


func startWebSocketServer(group: EventLoopGroup) throws {
    let bootstrap = ServerBootstrap(group: group)
        .childChannelInitializer { channel in
            let upgrader = NIOWebSocketServerUpgrader(
                shouldUpgrade: { (_, _) in
                    channel.eventLoop.makeSucceededFuture([:])
                },
                upgradePipelineHandler: { (channel, _) in
                    channel.pipeline.addHandler(WebSocketHandler())
                }
            )

            return channel.pipeline.configureHTTPServerPipeline(
                withServerUpgrade: (upgraders: [upgrader], completionHandler: { ctx in
                    ctx.fireChannelRead(NIOAny(HTTPServerRequestPart.end(nil)))
                })
            )
        }
        .serverChannelOption(ChannelOptions.backlog, value: 256)
        .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

    let serverChannel = try bootstrap.bind(host: "0.0.0.0", port: 7789).wait()
    print("WebSocket server running on: \(serverChannel.localAddress!)")
}

class WebSocketHandlerContainer: ObservableObject {
//    @Published var handler: WebSocketHandler?
    var handler: WebSocketHandler

    init(handler: WebSocketHandler) {
        self.handler = handler
    }

}

