//
//  File.swift
//  
//
//  Created by Maarten Engels on 08/11/2021.
//

import Foundation
import NIO

struct Session {
    let id: UUID
    let channel: Channel
    var playerID: UUID?
    var shouldClose = false
    var currentString = ""
    
    func erasingCurrentString() -> Session {
        var updatedSession = self
        updatedSession.currentString = ""
        return updatedSession
    }
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
