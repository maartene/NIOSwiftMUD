//
//  ResponseHandler.swift
//  
//
//  Created by Maarten Engels on 01/11/2021.
//

import Foundation
import NIO
import NIOSSH

final class ResponseHandler: ChannelInboundHandler {
    typealias InboundIn = [MudResponse]
    typealias InboundOut = SSHChannelData
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let responses = self.unwrapInboundIn(data)
        
        //let greenString = "\u{1B}[32m" + "[Session ID: \(response.session.id) Player ID: \(response.session.playerID)]: "  + response.message + "\u{1B}[0m" + "\n> "
        
        responses.forEach { response in
            
            let greenString = "\n\u{1B}[32m" + response.message + "\u{1B}[0m" + "\n> "
            
            let sshGreenString = greenString.replacingOccurrences(of: "\n", with: "\r\n")
            
            var outBuff = context.channel.allocator.buffer(capacity: sshGreenString.count)
            outBuff.writeString(sshGreenString)
        
            let channelData = SSHChannelData(byteBuffer: outBuff)
            if let session = response.session as? MudSession {
                session.channel.writeAndFlush(self.wrapInboundOut(channelData), promise: nil)
            
                // Update the session, because we might now have a player id or any other settings changed from commands.
                SessionStorage.replaceOrStoreSessionSync(response.session)
                
                if response.session.shouldClose {
                    print("Closing session: \(response.session)")
                    SessionStorage.deleteSession(response.session)
                    _ = context.close()
                }
            }
        }
        
        
    }
}
