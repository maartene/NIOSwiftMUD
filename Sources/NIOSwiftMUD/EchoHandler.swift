//
//  File.swift
//  
//
//  Created by Maarten Engels on 01/11/2021.
//

import Foundation
import NIO

final class EchoHandler: ChannelInboundHandler {
    
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let inBuff = self.unwrapInboundIn(data)
        let str = inBuff.getString(at: 0, length: inBuff.readableBytes) ?? ""
        
        let greenString = "\u{1B}[32m" + str + "\u{1B}[0m"
        
        var outBuff = context.channel.allocator.buffer(capacity: greenString.count)
        outBuff.writeString(greenString)
    
        context.writeAndFlush(self.wrapInboundOut(outBuff), promise: nil)
    }
}
