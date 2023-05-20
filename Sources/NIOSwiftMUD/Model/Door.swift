import Foundation

struct Door: DBType {
    static var storage: AwesomeDB<Door> = AwesomeDB()
    
    let id: UUID
    
    var isOpen = false
}

