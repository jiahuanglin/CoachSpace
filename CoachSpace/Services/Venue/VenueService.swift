import Foundation
import FirebaseFirestore
import CoreLocation

protocol VenueServiceProtocol {
    func getVenue(id: String) async throws -> Venue?
    func createVenue(_ venue: Venue) async throws
    func updateVenue(_ venue: Venue) async throws
    func deleteVenue(_ venueId: String) async throws
    func getVenues(type: Venue.VenueType?) async throws -> [Venue]
    func searchVenues(query: String) async throws -> [Venue]
    func getNearbyVenues(location: CLLocation, radius: Double) async throws -> [Venue]
    func updateVenueWeather(_ weatherInfo: Venue.WeatherInfo, for venueId: String) async throws
    func getVenueOperatingHours(venueId: String, dayOfWeek: Int) async throws -> Venue.OperatingHours?
    func updateVenueOperatingHours(_ hours: [Venue.OperatingHours], for venueId: String) async throws
}

final class VenueService: VenueServiceProtocol {
    static let shared = VenueService()
    private let db = Firestore.firestore()
    private let storage = StorageService.shared
    
    private init() {}
    
    func getVenue(id: String) async throws -> Venue? {
        do {
            let doc = try await db.collection("venues").document(id).getDocument()
            return Venue.from(doc)
        } catch {
            throw VenueError.fetchFailed(error)
        }
    }
    
    func createVenue(_ venue: Venue) async throws {
        do {
            try await db.collection("venues").document(venue.id).setData(venue.toFirestore)
        } catch {
            throw VenueError.createFailed(error)
        }
    }
    
    func updateVenue(_ venue: Venue) async throws {
        do {
            try await db.collection("venues").document(venue.id).updateData(venue.toFirestore)
        } catch {
            throw VenueError.updateFailed(error)
        }
    }
    
    func deleteVenue(_ venueId: String) async throws {
        do {
            // Delete venue data
            try await db.collection("venues").document(venueId).delete()
            
            // Delete venue images
            if let venue = try await getVenue(id: venueId) {
                if !venue.imageURL.isEmpty {
                    try await storage.deleteImage(at: venue.imageURL)
                }
                if let trailMap = venue.trailMap {
                    try await storage.deleteImage(at: trailMap)
                }
            }
            
            // Delete related data (classes, etc.)
            try await cleanupVenueData(venueId)
        } catch {
            throw VenueError.deleteFailed(error)
        }
    }
    
    func getVenues(type: Venue.VenueType? = nil) async throws -> [Venue] {
        do {
            let collection = db.collection("venues")
            let query: Query = type != nil ? 
                collection.whereField("type", isEqualTo: type!.rawValue) :
                collection
            
            let snapshot = try await query.getDocuments()
            return snapshot.documents.compactMap { Venue.from($0) }
        } catch {
            throw VenueError.fetchFailed(error)
        }
    }
    
    func searchVenues(query: String) async throws -> [Venue] {
        do {
            let snapshot = try await db.collection("venues")
                .whereField("name", isGreaterThanOrEqualTo: query)
                .whereField("name", isLessThanOrEqualTo: query + "\u{f8ff}")
                .getDocuments()
            return snapshot.documents.compactMap { Venue.from($0) }
        } catch {
            throw VenueError.searchFailed(error)
        }
    }
    
    func getNearbyVenues(location: CLLocation, radius: Double) async throws -> [Venue] {
        do {
            let venues = try await getVenues()
            return venues.filter { venue in
                let venueLocation = CLLocation(latitude: venue.latitude, longitude: venue.longitude)
                let distance = location.distance(from: venueLocation)
                return distance <= radius
            }.sorted { venue1, venue2 in
                let location1 = CLLocation(latitude: venue1.latitude, longitude: venue1.longitude)
                let location2 = CLLocation(latitude: venue2.latitude, longitude: venue2.longitude)
                return location.distance(from: location1) < location.distance(from: location2)
            }
        } catch {
            throw VenueError.fetchFailed(error)
        }
    }
    
    func updateVenueWeather(_ weatherInfo: Venue.WeatherInfo, for venueId: String) async throws {
        do {
            let data = try Firestore.Encoder().encode(weatherInfo)
            try await db.collection("venues").document(venueId).updateData(["weatherInfo": data])
        } catch {
            throw VenueError.updateFailed(error)
        }
    }
    
    func getVenueOperatingHours(venueId: String, dayOfWeek: Int) async throws -> Venue.OperatingHours? {
        do {
            guard let venue = try await getVenue(id: venueId) else {
                throw VenueError.venueNotFound
            }
            return venue.operatingHours.first { $0.dayOfWeek == dayOfWeek }
        } catch {
            throw VenueError.fetchFailed(error)
        }
    }
    
    func updateVenueOperatingHours(_ hours: [Venue.OperatingHours], for venueId: String) async throws {
        do {
            let data = try Firestore.Encoder().encode(hours)
            try await db.collection("venues").document(venueId).updateData(["operatingHours": data])
        } catch {
            throw VenueError.updateFailed(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func cleanupVenueData(_ venueId: String) async throws {
        // Delete classes associated with the venue
        let classes = try await db.collection("classes")
            .whereField("venueId", isEqualTo: venueId)
            .getDocuments()
        
        for classDoc in classes.documents {
            try await ClassService.shared.deleteClass(classDoc.documentID)
        }
    }
}

// MARK: - Errors

enum VenueError: LocalizedError {
    case fetchFailed(Error)
    case createFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case searchFailed(Error)
    case venueNotFound
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error): return "Failed to fetch venue: \(error.localizedDescription)"
        case .createFailed(let error): return "Failed to create venue: \(error.localizedDescription)"
        case .updateFailed(let error): return "Failed to update venue: \(error.localizedDescription)"
        case .deleteFailed(let error): return "Failed to delete venue: \(error.localizedDescription)"
        case .searchFailed(let error): return "Failed to search venues: \(error.localizedDescription)"
        case .venueNotFound: return "Venue not found"
        }
    }
}

// MARK: - Extensions

extension CLLocation {
    func isWithinRadius(_ radius: Double, of location: CLLocation) -> Bool {
        return distance(from: location) <= radius
    }
} 