//
//  ParseHandler.swift
//  
//
//  Created by Maarten Engels on 01/11/2021.
//

import Foundation
import NIO

final class ParseHandler: ChannelInboundHandler {
    
    typealias InboundIn = MudCommand
    typealias InboundOut = [MudResponse]
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        Task {
            let mudCommand = self.unwrapInboundIn(data)
            
            let response = await createMudResponse(mudCommand: mudCommand)
            
            context.eventLoop.execute {
                context.fireChannelRead(self.wrapInboundOut(response))
            }
        }
    }
    
    private func createMudResponse(mudCommand: MudCommand) async -> [MudResponse] {
        guard mudCommand.requiresLogin == false || mudCommand.session.playerID != nil else {
            return [MudResponse(session: mudCommand.session, message: "You need to be logged in to use this command.")]
        }
        
        return await mudCommand.execute()
    }
}
