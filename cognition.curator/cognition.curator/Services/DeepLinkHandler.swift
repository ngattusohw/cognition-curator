import SwiftUI
import Foundation

class DeepLinkHandler: ObservableObject {
    @Published var targetCardId: UUID?
    @Published var shouldOpenReview = false
    @Published var selectedTab = 2 // Review tab is index 2
    
    func handle(url: URL) {
        guard url.scheme == "cognitioncurator" else { return }
        
        let path = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch path {
        case "review":
            if pathComponents.count > 0, let cardIdString = pathComponents.first {
                // Widget clicked with specific card ID
                if let cardId = UUID(uuidString: cardIdString) {
                    targetCardId = cardId
                }
            }
            
            // Navigate to review tab and trigger review
            selectedTab = 2 // Review tab index
            shouldOpenReview = true
            
        default:
            // Default to opening the review tab
            selectedTab = 2
            shouldOpenReview = true
        }
    }
    
    func clearDeepLink() {
        targetCardId = nil
        shouldOpenReview = false
    }
} 