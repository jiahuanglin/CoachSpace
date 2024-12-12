import SwiftUI
import EventKit

struct ClassDetailView: View {
    let classId: String
    @State private var classData: Class?
    @State private var venue: Venue?
    @State private var instructor: User?
    @State private var reviews: [Review] = []
    @State private var booking: Booking?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showingCancelAlert = false
    @State private var showingCalendarSheet = false
    @State private var showingCalendarAlert = false
    @State private var calendarError: Error?
    @State private var isProcessing = false
    @Environment(\.dismiss) private var dismiss
    
    var isInstructor: Bool {
        guard let user = AuthService.shared.currentUser,
              let classData = classData else { return false }
        return user.role == .instructor && user.id == classData.instructorId
    }
    
    var canAddToCalendar: Bool {
        guard let classData = classData else { return false }
        if isInstructor {
            // Instructor can add if there are participants
            return classData.currentParticipants > 0
        } else {
            // Student can add if they have a confirmed booking
            return booking?.status == .confirmed
        }
    }
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if let error = error {
                VStack(spacing: 16) {
                    Text("Error loading class details")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await loadData()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if let classData = classData {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Image
                    if !classData.imageURL.isEmpty {
                        AsyncImage(url: URL(string: classData.imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(height: 250)
                        .clipped()
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Class Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(classData.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if let venue = venue {
                                Text(venue.name)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack(spacing: 16) {
                                Label("\(classData.duration) min", systemImage: "clock")
                                Label(classData.level.rawValue, systemImage: "speedometer")
                                Label("\(classData.currentParticipants)/\(classData.maxParticipants)", systemImage: "person.2")
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            
                            // Booking Status
                            if let booking = booking {
                                HStack {
                                    Image(systemName: booking.status == .confirmed ? "checkmark.circle.fill" : 
                                                     booking.status == .waitlisted ? "clock.fill" : "xmark.circle.fill")
                                        .foregroundColor(booking.status == .confirmed ? .green :
                                                       booking.status == .waitlisted ? .orange : .red)
                                    Text(booking.status == .confirmed ? "Booking Confirmed" :
                                         booking.status == .waitlisted ? "On Waitlist" : "Booking Cancelled")
                                        .font(.subheadline)
                                        .foregroundColor(booking.status == .confirmed ? .green :
                                                       booking.status == .waitlisted ? .orange : .red)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        Divider()
                        
                        // Instructor
                        if let instructor = instructor {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Instructor")
                                    .font(.headline)
                                
                                HStack(spacing: 12) {
                                    if let imageURL = instructor.imageURL {
                                        AsyncImage(url: URL(string: imageURL)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Circle()
                                                .fill(Color.gray.opacity(0.2))
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(instructor.displayName)
                                            .font(.headline)
                                    }
                                }
                            }
                            
                            Divider()
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)
                            Text(classData.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Location
                        if let venue = venue {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Location")
                                    .font(.headline)
                                
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(venue.address)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Divider()
                        }
                        
                        // Reviews
                        if !reviews.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Reviews")
                                    .font(.headline)
                                
                                ForEach(reviews.prefix(3), id: \.id) { review in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            ForEach(0..<5) { index in
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(index < review.rating ? .yellow : .gray)
                                            }
                                            Spacer()
                                            Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Text(review.comment)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        // Calendar Sync Button
                        if canAddToCalendar {
                            Button(action: {
                                showingCalendarSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                    Text(isInstructor ? "Add Class Schedule" : "Add to Calendar")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isProcessing)
                        }
                        
                        // Action Buttons
                        if isInstructor {
                            Button(action: {
                                showingCancelAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Cancel Class")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isProcessing)
                        } else if let booking = booking {
                            if booking.status != .cancelled {
                                Button(action: {
                                    showingCancelAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "xmark.circle")
                                        Text("Cancel Booking")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(isProcessing)
                            }
                        } else {
                            Button(action: {
                                Task {
                                    await bookClass()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("Book Class")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isProcessing)
                        }
                        
                        if isProcessing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Calendar Sync", isPresented: $showingCalendarAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = calendarError {
                Text(error.localizedDescription)
            } else {
                Text(isInstructor ? "Class schedule has been added to your calendar!" : "Class has been added to your calendar!")
            }
        }
        .alert(isInstructor ? "Cancel Class" : "Cancel Booking", isPresented: $showingCancelAlert) {
            Button(isInstructor ? "Yes, Cancel Class" : "Cancel Booking", role: .destructive) {
                Task {
                    if isInstructor {
                        await cancelClass()
                    } else {
                        await cancelBooking()
                    }
                }
            }
            Button(isInstructor ? "No, Keep Class" : "Keep Booking", role: .cancel) {}
        } message: {
            if isInstructor {
                Text("Are you sure you want to cancel this class? This will cancel all student bookings and remove the class from the schedule. This action cannot be undone.")
            } else {
                Text("Are you sure you want to cancel your booking? This action cannot be undone.")
            }
        }
        .sheet(isPresented: $showingCalendarSheet) {
            CalendarOptionsSheet(
                classData: classData,
                venue: venue,
                instructor: instructor,
                isProcessing: $isProcessing,
                error: $calendarError,
                showAlert: $showingCalendarAlert,
                isInstructor: isInstructor,
                dismiss: { showingCalendarSheet = false }
            )
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        error = nil
        
        do {
            // First get the class data
            let classData = try await ClassService.shared.getClass(id: classId)
            guard let classData = classData else {
                throw ClassError.classNotFound
            }
            
            self.classData = classData
            
            // Then load related data concurrently
            async let venueResult = VenueService.shared.getVenue(id: classData.venueId)
            async let instructorResult = UserService.shared.getUser(id: classData.instructorId)
            async let reviewsResult = ClassService.shared.getClassReviews(classId: classId)
            
            let (venue, instructor, reviews) = try await (venueResult, instructorResult, reviewsResult)
            
            self.venue = venue
            self.instructor = instructor
            self.reviews = reviews
            
            // Load booking status if user is logged in and not the instructor
            if let userId = AuthService.shared.currentUser?.id,
               userId != classData.instructorId {
                let bookings = try await BookingService.shared.getBookingsForClass(classId: classId)
                booking = bookings.first { $0.userId == userId }
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func bookClass() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        
        isProcessing = true
        error = nil
        
        do {
            try await ClassService.shared.bookClass(classId, userId: userId)
            await loadData() // Reload to get updated status
        } catch {
            self.error = error
        }
        
        isProcessing = false
    }
    
    private func cancelBooking() async {
        guard let booking = booking,
              let userId = AuthService.shared.currentUser?.id else { return }
        
        isProcessing = true
        error = nil
        
        do {
            try await ClassService.shared.cancelBooking(classId: booking.classId, userId: userId)
            await loadData() // Reload to get updated booking status
        } catch {
            self.error = error
        }
        
        isProcessing = false
    }
    
    private func cancelClass() async {
        guard isInstructor else { return }
        
        isProcessing = true
        error = nil
        
        do {
            try await ClassService.shared.cancelClass(classId)
            dismiss() // Return to schedule view after cancelling
        } catch {
            self.error = error
        }
        
        isProcessing = false
    }
}

struct CalendarOptionsSheet: View {
    let classData: Class?
    let venue: Venue?
    let instructor: User?
    @Binding var isProcessing: Bool
    @Binding var error: Error?
    @Binding var showAlert: Bool
    let isInstructor: Bool
    let dismiss: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        Task {
                            await addToLocalCalendar()
                        }
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(isInstructor ? "Add to iPhone Calendar as Instructor" : "Add to iPhone Calendar")
                        }
                    }
                    .disabled(isProcessing)
                } header: {
                    Text("Local Calendar")
                } footer: {
                    if isInstructor {
                        Text("Add this class to your calendar with instructor details and participant count")
                    }
                }
                
                Section {
                    Button(action: {
                        // Show Google Sign In
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .foregroundColor(.red)
                            Text("Sign in with Google Calendar")
                        }
                    }
                    .disabled(isProcessing)
                } header: {
                    Text("Google Calendar")
                } footer: {
                    Text("Sign in with Google to sync with Google Calendar")
                }
            }
            .navigationTitle(isInstructor ? "Add Class Schedule" : "Add to Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addToLocalCalendar() async {
        guard let classData = classData else { return }
        
        isProcessing = true
        error = nil
        
        do {
            try await CalendarService.shared.addToLocalCalendar(classData, venue: venue, instructor: instructor)
            showAlert = true
            dismiss()
        } catch {
            self.error = error
            showAlert = true
        }
        
        isProcessing = false
    }
}

struct ClassDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ClassDetailView(classId: "preview_class_id")
        }
    }
}
