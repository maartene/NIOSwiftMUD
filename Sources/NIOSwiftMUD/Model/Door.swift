import Foundation
import Atomics

struct Door: DBType {
    static let storage: AwesomeDB<Door> = AwesomeDB()
    static let persist = ManagedAtomic(true)
    
    let id: UUID
    
    var isOpen = false
}

