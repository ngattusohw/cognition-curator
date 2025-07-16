import Foundation

extension DateFormatter {
    /// Formats date as "January 2024"
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    /// Formats date as "Jan 15, 2024"
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Formats date as "2024-01-15"
    static let iso8601Date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// Formats date as "3:45 PM"
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// Formats date as "Jan 15, 3:45 PM"
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
} 