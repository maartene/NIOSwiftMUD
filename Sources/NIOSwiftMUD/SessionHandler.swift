//
//  File.swift
//  
//
//  Created by Maarten Engels on 01/11/2021.
//

import Foundation
import NIO

struct Session {
    let id: UUID
    let channel: Channel
    var playerID: UUID?
    var shouldClose = false
}

struct TextCommand {
    let session: Session
    let command: String
}

final class SessionHandler: ChannelInboundHandler {
    
    typealias InboundIn = ByteBuffer
    typealias InboundOut = TextCommand
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let inBuff = self.unwrapInboundIn(data)
        let str = inBuff.getString(at: 0, length: inBuff.readableBytes) ?? ""
        
        let session = Session(id: UUID(), channel: context.channel, playerID: nil)
        
        let command = TextCommand(session: session, command: str)
    
        context.fireChannelRead(wrapInboundOut(command))
    }
}
