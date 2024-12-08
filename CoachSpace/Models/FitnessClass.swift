import Foundation

struct FitnessClass: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let instructor: String
    let studio: Studio
    let category: Category
    let duration: Int // in minutes
    let credits: Int
    let startTime: Date
    let maxCapacity: Int
    let currentBookings: Int
    let imageURL: String
    
    var isAvailable: Bool {
        currentBookings < maxCapacity
    }
    
    enum Category: String, CaseIterable {
        case yoga = "Yoga"
        case pilates = "Pilates"
        case hiit = "HIIT"
        case strength = "Strength"
        case cycling = "Cycling"
        case dance = "Dance"
    }
}

struct Studio: Identifiable {
    let id: UUID
    let name: String
    let address: String
    let rating: Double
    let imageURL: String
    let latitude: Double
    let longitude: Double
} 