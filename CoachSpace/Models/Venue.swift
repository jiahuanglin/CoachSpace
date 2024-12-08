import Foundation
import FirebaseFirestore
import CoreLocation

struct Venue: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let rating: Double
    let imageURL: String
    let latitude: Double
    let longitude: Double
    let amenities: [Amenity]
    let type: VenueType
    let operatingHours: [OperatingHours]
    let weatherInfo: WeatherInfo?
    let trailMap: String? // URL to trail map image
    let createdAt: Date
    let updatedAt: Date
    
    enum VenueType: String, Codable {
        case skiResort = "Ski Resort"
        case indoorTrainingCenter = "Indoor Training Center"
        case snowPark = "Snow Park"
    }
    
    enum Amenity: String, Codable, CaseIterable {
        case rentalShop = "Rental Shop"
        case lodge = "Lodge"
        case restaurant = "Restaurant"
        case parking = "Parking"
        case lockers = "Lockers"
        case skiSchool = "Ski School"
        case medicalCenter = "Medical Center"
        case childcare = "Childcare"
    }
    
    struct OperatingHours: Codable {
        let dayOfWeek: Int // 1 (Sunday) to 7 (Saturday)
        let openTime: String // 24-hour format "HH:mm"
        let closeTime: String // 24-hour format "HH:mm"
        let isOpen: Bool
    }
    
    struct WeatherInfo: Codable {
        let temperature: Double
        let conditions: String
        let snowDepth: Double
        let lastSnowfall: Date
        let windSpeed: Double
        let visibility: Double
        let updatedAt: Date
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var formattedAmenities: String {
        amenities.map { $0.rawValue }.joined(separator: " • ")
    }
}

// Firestore Extensions
extension Venue {
    static func from(_ document: DocumentSnapshot) -> Venue? {
        try? document.data(as: Venue.self)
    }
    
    var toFirestore: [String: Any] {
        guard let data = try? Firestore.Encoder().encode(self) else { return [:] }
        return data
    }
} 