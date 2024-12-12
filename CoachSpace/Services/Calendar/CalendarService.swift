import Foundation
import EventKit

class CalendarService {
    static let shared = CalendarService()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    func requestCalendarAccess() async throws -> Bool {
        return await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .event) { granted, error in
                if let error = error {
                    print("❌ [CalendarService] Error requesting calendar access: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                } else {
                    print("✅ [CalendarService] Calendar access \(granted ? "granted" : "denied")")
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func addToLocalCalendar(_ classData: Class, venue: Venue?, instructor: User?) async throws {
        print("🔄 [CalendarService] Starting local calendar sync for class: \(classData.id)")
        
        // Request calendar access if needed
        guard try await requestCalendarAccess() else {
            throw CalendarError.accessDenied
        }
        
        // Create event
        let event = EKEvent(eventStore: eventStore)
        event.title = classData.name
        event.startDate = classData.startTime
        event.endDate = classData.startTime.addingTimeInterval(TimeInterval(classData.duration * 60))
        
        // Add location if available
        if let venue = venue {
            event.location = "\(venue.name) - \(venue.address)"
        }
        
        // Add notes with class details
        var notes = [classData.description]
        if let instructor = instructor {
            notes.append("Instructor: \(instructor.displayName)")
        }
        notes.append("Level: \(classData.level.rawValue)")
        notes.append("Duration: \(classData.duration) minutes")
        event.notes = notes.joined(separator: "\n\n")
        
        // Set calendar
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Add alert
        let alarm = EKAlarm(relativeOffset: -3600) // 1 hour before
        event.addAlarm(alarm)
        
        // Save event
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ [CalendarService] Successfully added class to local calendar: \(event.eventIdentifier ?? "")")
        } catch {
            print("❌ [CalendarService] Error saving event: \(error.localizedDescription)")
            throw CalendarError.saveFailed(error)
        }
    }
    
    func getAvailableCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }
}

enum CalendarError: LocalizedError {
    case accessDenied
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied. Please enable calendar access in Settings."
        case .saveFailed(let error):
            return "Failed to save event: \(error.localizedDescription)"
        }
    }
} 
