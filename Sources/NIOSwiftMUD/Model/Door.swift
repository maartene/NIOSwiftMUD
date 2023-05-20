import Foundation

struct Door: DBType {
    static var storage: AwesomeDB<Door> = AwesomeDB()
    static var persist = true
    
    let id: UUID
    
    var isOpen = false
}

