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

final class SessionStorage {
    static private var sessions = [Session]()
    static private var lock = NSLock()
    
    static func replaceOrStoreSessionSync(_ session: Session) {
        lock.lock()
        
        if let existingSessionIndex = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[existingSessionIndex] = session
        } else {
            sessions.append(session)
        }
        
        lock.unlock()
    }
    
    static func first(where predicate: (Session) throws -> Bool) -> Session? {
        lock.lock()
        let result = try? sessions.first(where: predicate)
        lock.unlock()
        return result
    }
    
    static func deleteSession(_ session: Session) {
        lock.lock()
        
        if  let existingSessionIndex = sessions.firstIndex(where: {$0.id == session.id }) {
            sessions.remove(at: existingSessionIndex)
            print("Succesfully deleted session: \(session)")
        } else {
            print("Could not find session \(session)")
        }
        
        lock.unlock()
    }
}

final class SessionHandler: ChannelInboundHandler {
    
    typealias InboundIn = ByteBuffer
    typealias InboundOut = TextCommand
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let inBuff = self.unwrapInboundIn(data)
        let str = inBuff.getString(at: 0, length: inBuff.readableBytes) ?? ""
        
        let session = SessionStorage.first(where: { $0.channel.remoteAddress == context.channel.remoteAddress }) ?? Session(id: UUID(), channel: context.channel, playerID: nil)
        
        SessionStorage.replaceOrStoreSessionSync(session)
        
        let command = TextCommand(session: session, command: str)
    
        context.fireChannelRead(wrapInboundOut(command))
    }
    
    public func channelActive(context: ChannelHandlerContext) {
        let welcomeText = """
        Welcome to NIOSwiftMUD!
        Hope you enjoy your stay.
        Please use 'CREATE_USER <username> <password>' to begin.
        You can leave by using the 'CLOSE' command.
        """
        
        let greenString = "\u{1B}[32m" + welcomeText + "\u{1B}[0m" + "\n> "
        
        var outBuff = context.channel.allocator.buffer(capacity: greenString.count)
        outBuff.writeString(greenString)
        
        context.writeAndFlush(NIOAny(outBuff), promise: nil)
    }
}
