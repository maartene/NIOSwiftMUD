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
        let promise = context.eventLoop.makePromise(of: Void.self)
        
        let mudCommand = self.unwrapInboundIn(data)
        
        // `Context` does not conform to `@Sendable`, but `EventLoop` does,
        // so we pass only the EventLoop and a reference to the `fireChannelRead` function.
        let eventLoop = context.eventLoop
        let fireChannelRead = context.fireChannelRead
        
        promise.completeWithTask {
            let response = await self.createMudResponse(mudCommand: mudCommand)
            
            eventLoop.execute {
                fireChannelRead(self.wrapInboundOut(response))
            }
        }
        
//        Task {
//            let mudCommand = self.unwrapInboundIn(data)
//
//            let response = await createMudResponse(mudCommand: mudCommand)
//
//            context.eventLoop.execute {
//                context.fireChannelRead(self.wrapInboundOut(response))
//            }
//        }
    }
    
    private func createMudResponse(mudCommand: MudCommand) async -> [MudResponse] {
        guard mudCommand.requiresLogin == false || mudCommand.session.playerID != nil else {
            return [MudResponse(session: mudCommand.session, message: "You need to be logged in to use this command.")]
        }
        
        return await mudCommand.execute()
    }
}
