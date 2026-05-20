import Foundation

struct Door {
    let id: UUID
    
    var isOpen = false
}

extension Door: Identifiable {
    
}
