//
//  SessionHandler.swift
//  
//
//  Created by Maarten Engels on 01/11/2021.
//

import Foundation
import NIO
import NIOSSH

struct MudSession: Session {
    let id: UUID
    let channel: Channel
    var playerID: UUID?
    var shouldClose = false
    var currentString = ""
}

struct TextCommand {
    let session: MudSession
    let command: String
}

final class SessionHandler: ChannelInboundHandler {
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
        
        var session = SessionStorage.first(where: { session in 
            if let session = session as? MudSession {
                return session.channel.remoteAddress == context.channel.remoteAddress
            } else {
                return false
            }
        }) as? MudSession ?? MudSession(id: UUID(), channel: context.channel, playerID: nil)

        switch str {
        case "\u{7F}":  // backspace was pressed
            session = processBackspace(session, context: context)
            SessionStorage.replaceOrStoreSessionSync(session)
        case "\n", "\r":      // an end-of-line character, time to send the command
            sendCommand(session, context: context)
        default:        // any other character, just append it to the sessions current string and echo back.
            session.currentString += str
            context.writeAndFlush(self.wrapOutboundOut(inBuff), promise: nil)
            SessionStorage.replaceOrStoreSessionSync(session)
        }
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
        
        let channelData = SSHChannelData(byteBuffer: outBuff)
        context.writeAndFlush(self.wrapOutboundOut(channelData), promise: nil)
    }

    private func sendCommand(_ session: MudSession, context: ChannelHandlerContext) {
        let command = TextCommand(session: session.erasingCurrentString(), command: session.currentString)
        context.fireChannelRead(wrapInboundOut(command))
    }

    private func processBackspace(_ session: MudSession, context: ChannelHandlerContext) -> MudSession {
        guard session.currentString.count > 0 else {
            //print("Empty string, nothing to backspace.")
            return session
        }

        var updatedSession = session

        updatedSession.currentString = String(session.currentString.dropLast(1))
        //print("Backspace: \(updatedSession.currentString)")
        let backspaceString = "\u{1B}[1D \u{1B}[1D"
        var outBuff = context.channel.allocator.buffer(capacity: backspaceString.count)
        outBuff.writeString(backspaceString)

        let channelData = SSHChannelData(byteBuffer: outBuff)
        context.writeAndFlush(self.wrapOutboundOut(channelData), promise: nil)
        return updatedSession
    }
}
