//
//  StaticServer.swift
//  eWriter
//
//  Created by Nikolay Nikiforov on 03.10.2024.
//

import NIO
import NIOHTTP1
import Foundation

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    let htmlFilePath: String
    
    init(htmlFilePath: String) {
        self.htmlFilePath = htmlFilePath
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let request):
            if request.uri == "/" {
                serveStaticHTML(context: context)
            } else {
                sendNotFound(context: context)
            }
        case .body:
            break
        case .end:
            break
        }
    }
    
    // Serve the static HTML file
    private func serveStaticHTML(context: ChannelHandlerContext) {
        do {
//            print("HELLO!")
            let htmlData = try Data(contentsOf: URL(fileURLWithPath: htmlFilePath))
            let htmlString = String(data: htmlData, encoding: .utf8) ?? "<html><body>Error loading HTML</body></html>"
//            let htmlString = "<html><body>Hello World</body></html>"
            let responseHead = HTTPResponseHead(version: .http1_1, status: .ok)
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            
            var buffer = context.channel.allocator.buffer(capacity: htmlString.utf8.count)
            buffer.writeString(htmlString)
            context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        } catch {
            print("Error serving HTML: \(error)")
            let responseHead = HTTPResponseHead(version: .http1_1, status: .internalServerError)
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        }
    }
    
    // Handle 404 Not Found
    private func sendNotFound(context: ChannelHandlerContext) {
        let responseHead = HTTPResponseHead(version: .http1_1, status: .notFound)
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        var buffer = context.channel.allocator.buffer(capacity: 0)
        buffer.writeString("<html><body>404 Not Found</body></html>")
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error)")
        context.close(promise: nil)
    }
}

// This function sets up the HTTP server
func createServer(group: EventLoopGroup, htmlFilePath: String) throws {
    let bootstrap = ServerBootstrap(group: group)
        .childChannelInitializer { channel in
            channel.pipeline.configureHTTPServerPipeline().flatMap {
                channel.pipeline.addHandler(HTTPHandler(htmlFilePath: htmlFilePath))
            }
        }
        .serverChannelOption(ChannelOptions.backlog, value: 256)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    
    let serverChannel = try bootstrap.bind(host: "0.0.0.0", port: 8787).wait()
    print("Server running on: \(serverChannel.localAddress!)")
    try serverChannel.closeFuture.wait()
}
