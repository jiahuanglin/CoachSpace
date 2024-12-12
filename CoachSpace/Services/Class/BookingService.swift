import Foundation
import FirebaseFirestore

class BookingService {
    static let shared = BookingService()
    private let db = Firestore.firestore()
    private let bookingsCollection = "bookings"
    private let classesCollection = "classes"
    
    private init() {}
    
    // MARK: - Create Booking
    func createBooking(for classId: String, userId: String) async throws -> Booking {
        // Get class details first to check availability
        let classRef = db.collection(classesCollection).document(classId)
        let classDoc = try await classRef.getDocument()
        if !classDoc.exists {
            throw NSError(domain: "BookingService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Class not found"])
        }
        
        let classData = classDoc.data() ?? [:]
        
        // Check if class is full
        let currentBookings = try await getBookingsForClass(classId: classId)
        let confirmedBookings = currentBookings.filter { $0.status == .confirmed }
        
        let status: Booking.BookingStatus = confirmedBookings.count >= (classData["maxParticipants"] as? Int ?? 0) ? .waitlisted : .confirmed
        
        // Create new booking
        let bookingId = UUID().uuidString
        let booking = Booking(
            id: bookingId,
            classId: classId,
            userId: userId,
            status: status,
            createdAt: Date()
        )
        
        // Convert to dictionary manually
        let bookingData: [String: Any] = [
            "id": booking.id,
            "classId": booking.classId,
            "userId": booking.userId,
            "status": booking.status.rawValue,
            "createdAt": Timestamp(date: booking.createdAt)
        ]
        
        // Save to Firestore
        try await db.collection(bookingsCollection).document(booking.id).setData(bookingData)
        
        print("📝 [BookingService] Created booking \(booking.id) for class \(classId) with status \(status)")
        return booking
    }
    
    // MARK: - Get Bookings
    func getBookingsForUser(userId: String) async throws -> [Booking] {
        let snapshot = try await db.collection(bookingsCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            return Booking(
                id: data["id"] as? String ?? "",
                classId: data["classId"] as? String ?? "",
                userId: data["userId"] as? String ?? "",
                status: Booking.BookingStatus(rawValue: data["status"] as? String ?? "") ?? .cancelled,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
    }
    
    func getBookingsForClass(classId: String) async throws -> [Booking] {
        let snapshot = try await db.collection(bookingsCollection)
            .whereField("classId", isEqualTo: classId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            return Booking(
                id: data["id"] as? String ?? "",
                classId: data["classId"] as? String ?? "",
                userId: data["userId"] as? String ?? "",
                status: Booking.BookingStatus(rawValue: data["status"] as? String ?? "") ?? .cancelled,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
    }
    
    // MARK: - Cancel Booking
    func cancelBooking(bookingId: String) async throws {
        let bookingRef = db.collection(bookingsCollection).document(bookingId)
        let bookingDoc = try await bookingRef.getDocument()
        if !bookingDoc.exists {
            throw NSError(domain: "BookingService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Booking not found"])
        }
        
        let data = bookingDoc.data() ?? [:]
        let booking = Booking(
            id: data["id"] as? String ?? "",
            classId: data["classId"] as? String ?? "",
            userId: data["userId"] as? String ?? "",
            status: Booking.BookingStatus(rawValue: data["status"] as? String ?? "") ?? .cancelled,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
        
        // Update status to cancelled
        let updatedData: [String: Any] = [
            "id": booking.id,
            "classId": booking.classId,
            "userId": booking.userId,
            "status": Booking.BookingStatus.cancelled.rawValue,
            "createdAt": Timestamp(date: booking.createdAt)
        ]
        
        try await bookingRef.setData(updatedData)
        print("❌ [BookingService] Cancelled booking \(bookingId)")
        
        // If there was a waitlist, promote the next person
        if booking.status == .confirmed {
            try await promoteFromWaitlist(classId: booking.classId)
        }
    }
    
    // MARK: - Waitlist Management
    private func promoteFromWaitlist(classId: String) async throws {
        let waitlistedBookings = try await db.collection(bookingsCollection)
            .whereField("classId", isEqualTo: classId)
            .whereField("status", isEqualTo: Booking.BookingStatus.waitlisted.rawValue)
            .order(by: "createdAt")
            .limit(to: 1)
            .getDocuments()
        
        guard let firstDoc = waitlistedBookings.documents.first else {
            return
        }
        
        let data = firstDoc.data()
        let booking = Booking(
            id: data["id"] as? String ?? "",
            classId: data["classId"] as? String ?? "",
            userId: data["userId"] as? String ?? "",
            status: Booking.BookingStatus(rawValue: data["status"] as? String ?? "") ?? .waitlisted,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
        
        // Update status to confirmed
        let updatedData: [String: Any] = [
            "id": booking.id,
            "classId": booking.classId,
            "userId": booking.userId,
            "status": Booking.BookingStatus.confirmed.rawValue,
            "createdAt": Timestamp(date: booking.createdAt)
        ]
        
        try await db.collection(bookingsCollection).document(booking.id).setData(updatedData)
        print("⬆️ [BookingService] Promoted booking \(booking.id) from waitlist to confirmed")
    }
}
