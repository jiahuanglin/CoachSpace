import SwiftUI

struct ClassDetailView: View {
    let classId: String
    @State private var classData: Class?
    @State private var venue: Venue?
    @State private var instructor: User?
    @State private var reviews: [Review] = []
    @State private var isLoading = true
    @State private var error: Error?
    @State private var booking: Booking?
    @State private var isBooking = false
    @State private var bookingError: Error?
    @State private var showingBookingAlert = false
    @State private var showingCancelAlert = false
    @Environment(\.dismiss) private var dismiss
    
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
                        
                        // Booking Button
                        if booking == nil {
                            Button(action: {
                                showingBookingAlert = true
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
                            .disabled(isBooking)
                            .alert("Confirm Booking", isPresented: $showingBookingAlert) {
                                Button("Book Now", role: .none) {
                                    Task {
                                        await bookClass()
                                    }
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("Would you like to book this class?")
                            }
                        } else if booking?.status != .cancelled {
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
                            .alert("Cancel Booking", isPresented: $showingCancelAlert) {
                                Button("Cancel Booking", role: .destructive) {
                                    Task {
                                        await cancelBooking()
                                    }
                                }
                                Button("Keep Booking", role: .cancel) {}
                            } message: {
                                Text("Are you sure you want to cancel this booking?")
                            }
                        }
                        
                        if isBooking {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                        
                        if let bookingError = bookingError {
                            Text(bookingError.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        error = nil
        
        do {
            async let classResult = ClassService.shared.getClass(id: classId)
            let classData = try await classResult
            
            guard let classData = classData else {
                throw ClassError.classNotFound
            }
            
            self.classData = classData
            
            async let venueResult = VenueService.shared.getVenue(id: classData.venueId)
            async let instructorResult = UserService.shared.getUser(id: classData.instructorId)
            async let reviewsResult = ClassService.shared.getClassReviews(classId: classId)
            
            // Load booking status if user is logged in
            if let userId = AuthService.shared.currentUser?.id {
                let bookings = try await BookingService.shared.getBookingsForClass(classId: classId)
                self.booking = bookings.first { $0.userId == userId }
            }
            
            let (venue, instructor, reviews) = try await (venueResult, instructorResult, reviewsResult)
            
            self.venue = venue
            self.instructor = instructor
            self.reviews = reviews
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func bookClass() async {
        guard let userId = AuthService.shared.currentUser?.id else {
            bookingError = NSError(domain: "Booking", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please log in to book classes"])
            return
        }
        
        isBooking = true
        bookingError = nil
        
        do {
            let booking = try await BookingService.shared.createBooking(for: classId, userId: userId)
            self.booking = booking
        } catch {
            bookingError = error
        }
        
        isBooking = false
    }
    
    private func cancelBooking() async {
        guard let booking = booking else { return }
        
        isBooking = true
        bookingError = nil
        
        do {
            try await BookingService.shared.cancelBooking(bookingId: booking.id)
            await loadData() // Reload to get updated booking status
        } catch {
            bookingError = error
        }
        
        isBooking = false
    }
}

struct ClassDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ClassDetailView(classId: "preview_class_id")
        }
    }
}
