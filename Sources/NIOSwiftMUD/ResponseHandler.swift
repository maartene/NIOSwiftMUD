//
//  File.swift
//  
//
//  Created by Maarten Engels on 01/11/2021.
//

import Foundation
import NIO

final class ResponseHandler: ChannelInboundHandler {
    typealias InboundIn = MudResponse
    typealias InboundOut = ByteBuffer
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let response = self.unwrapInboundIn(data)
        
        let greenString = "\u{1B}[32m" + response.message + "\u{1B}[0m" + "\n> "
        
        var outBuff = context.channel.allocator.buffer(capacity: greenString.count)
        outBuff.writeString(greenString)
    
        context.writeAndFlush(self.wrapInboundOut(outBuff), promise: nil)
        
        if response.session.shouldClose {
            print("Closing session: \(response.session)")
            _ = context.close()
        }
    }
}
