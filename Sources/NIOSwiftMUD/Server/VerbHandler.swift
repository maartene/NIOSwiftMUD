//
//  VerbHandler.swift
//  
//
//  Created by Maarten Engels on 01/11/2021.
//

import Foundation
import NIO

final class VerbHandler: ChannelInboundHandler {
    static let commandFactory = MudCommandFactory()

    typealias InboundIn = TextCommand
    typealias InboundOut = MudCommand
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let textCommand = self.unwrapInboundIn(data)
        
        let mudCommand = Self.commandFactory.createMudCommand(from: textCommand.command, session: textCommand.session)
            
        context.fireChannelRead(wrapInboundOut(mudCommand))
    }
}
