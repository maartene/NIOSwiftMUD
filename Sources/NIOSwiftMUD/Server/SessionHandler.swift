//
//  File.swift
//  
//
//  Created by Maarten Engels on 01/11/2021.
//

import Foundation
import NIO
import NIOSSH


struct TextCommand {
    let session: Session
    let command: String
}

final class SessionHandler: ChannelInboundHandler {
    
    //typealias InboundIn = ByteBuffer
    typealias InboundIn = SSHChannelData
    typealias InboundOut = TextCommand
    typealias OutboundOut = SSHChannelData
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let inBuff = self.unwrapInboundIn(data)
        
        guard case .byteBuffer(let bytes) = inBuff.data else {
            fatalError("Unexpected read type")
        }
        
        guard case .channel = inBuff.type else {
            context.fireErrorCaught(SSHServerError.invalidDataType)
            return
        }
        
        let str = String(buffer: bytes)
                
        var session = SessionStorage.first(where: { $0.channel.remoteAddress == context.channel.remoteAddress }) ?? Session(id: UUID(), channel: context.channel, playerID: nil)
        
        session.currentString += str
        //print(str.debugDescription)
        if str.contains("\n") || str.contains("\r") {
            let commandString = session.currentString + str
            session.currentString = ""
            let command = TextCommand(session: session, command: commandString)
            
            context.fireChannelRead(wrapInboundOut(command))
        } else {
            context.writeAndFlush(self.wrapOutboundOut(inBuff), promise: nil)
        }
        
        SessionStorage.replaceOrStoreSessionSync(session)
    }
    
    public func channelActive(context: ChannelHandlerContext) {
        let welcomeText = """
        Welcome to NIOSwiftMUD!
        Hope you enjoy your stay.
        Please use 'CREATE_USER <username> <password>' to begin.
        You can leave by using the 'CLOSE' command.
        """
        
        let sshWelcomeText = welcomeText.replacingOccurrences(of: "\n", with: "\r\n")
        
        let greenString = "\u{1B}[32m" + sshWelcomeText + "\u{1B}[0m" + "\n\r> "
        
        var outBuff = context.channel.allocator.buffer(capacity: greenString.count)
        outBuff.writeString(greenString)
        
        let ioData = IOData.byteBuffer(outBuff)
        let channelData = SSHChannelData(type: .channel, data: ioData)
        
        context.writeAndFlush(self.wrapOutboundOut(channelData), promise: nil)
    }
}
