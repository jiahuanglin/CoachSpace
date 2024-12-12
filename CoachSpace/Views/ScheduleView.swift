import SwiftUI

struct ScheduleView: View {
    @State private var selectedTab = 0
    @State private var selectedDate = Date()
    @State private var upcomingClasses: [Class] = []
    @State private var pastClasses: [Class] = []
    @State private var bookings: [String: Booking] = [:] // Map of classId to Booking
    @State private var isLoading = false
    @State private var error: Error?
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<14) { index in
                            let date = calendar.date(byAdding: .day, value: index, to: Date())!
                            DateButton(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                action: { 
                                    selectedDate = date
                                    Task {
                                        await loadClasses()
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
                
                // Tab Selector
                Picker("View", selection: $selectedTab) {
                    Text("Upcoming").tag(0)
                    Text("Past").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if let error = error {
                    VStack(spacing: 16) {
                        Text("Error loading schedule")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await loadClasses()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    if selectedTab == 0 {
                        UpcomingClassesView(classes: upcomingClasses, bookings: bookings)
                            .onChange(of: bookings) { _ in
                                Task {
                                    await loadClasses()
                                }
                            }
                    } else {
                        PastClassesView(classes: pastClasses, bookings: bookings)
                    }
                }
            }
            .navigationTitle("Schedule")
            .background(Color(.systemGray6))
        }
        .task {
            await loadClasses()
        }
    }
    
    private func loadClasses() async {
        isLoading = true
        error = nil
        
        do {
            guard let user = AuthService.shared.currentUser else {
                print("🚫 [ScheduleView] No user logged in")
                throw NSError(domain: "Schedule", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please log in to view schedule"])
            }
            
            print("👤 [ScheduleView] Loading schedule for user: \(user.id), role: \(user.role)")
            
            if user.role == .instructor {
                // For instructors, load classes they are teaching
                print("👨‍🏫 [ScheduleView] Loading instructor's classes")
                let allClasses = try await ClassService.shared.getInstructorClasses(instructorId: user.id)
                
                // Split into upcoming and past based on date
                let now = Date()
                upcomingClasses = allClasses.filter { $0.startTime > now }
                pastClasses = allClasses.filter { $0.startTime <= now }
                
                print("📈 [ScheduleView] Found \(upcomingClasses.count) upcoming classes to teach")
                upcomingClasses.forEach { classItem in
                    print("   - Upcoming: id=\(classItem.id), name=\(classItem.name), time=\(classItem.startTime)")
                }
                
                print("📉 [ScheduleView] Found \(pastClasses.count) past classes taught")
                pastClasses.forEach { classItem in
                    print("   - Past: id=\(classItem.id), name=\(classItem.name), time=\(classItem.startTime)")
                }
            } else {
                // For students, load their booked classes
                print("🎓 [ScheduleView] Loading student's bookings")
                
                // Load bookings first
                let userBookings = try await BookingService.shared.getBookingsForUser(userId: user.id)
                print("📚 [ScheduleView] Found \(userBookings.count) bookings")
                userBookings.forEach { booking in
                    print("   - Booking: classId=\(booking.classId), status=\(booking.status)")
                }
                
                bookings = Dictionary(uniqueKeysWithValues: userBookings.map { ($0.classId, $0) })
                
                // Get upcoming and past classes
                async let upcoming = ClassService.shared.getUpcomingClasses(for: user.id)
                async let past = ClassService.shared.getPastClasses(for: user.id)
                
                let (upcomingResult, pastResult) = try await (upcoming, past)
                print("📈 [ScheduleView] Found \(upcomingResult.count) upcoming booked classes")
                upcomingResult.forEach { classItem in
                    print("   - Upcoming: id=\(classItem.id), name=\(classItem.name), time=\(classItem.startTime)")
                }
                
                print("📉 [ScheduleView] Found \(pastResult.count) past booked classes")
                pastResult.forEach { classItem in
                    print("   - Past: id=\(classItem.id), name=\(classItem.name), time=\(classItem.startTime)")
                }
                
                upcomingClasses = upcomingResult
                pastClasses = pastResult
            }
        } catch {
            print("❌ [ScheduleView] Error loading classes: \(error.localizedDescription)")
            self.error = error
        }
        
        isLoading = false
    }
}

struct UpcomingClassesView: View {
    let classes: [Class]
    let bookings: [String: Booking]
    
    var body: some View {
        if classes.isEmpty {
            ContentUnavailableView(
                "No Upcoming Classes",
                systemImage: "calendar.badge.plus",
                description: Text("Book a class to get started!")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(classes) { classItem in
                        UpcomingClassCard(
                            classItem: classItem,
                            booking: bookings[classItem.id]
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct PastClassesView: View {
    let classes: [Class]
    let bookings: [String: Booking]
    
    var body: some View {
        if classes.isEmpty {
            ContentUnavailableView(
                "No Past Classes",
                systemImage: "calendar.badge.clock",
                description: Text("Your completed classes will appear here")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(classes) { classItem in
                        PastClassCard(
                            classItem: classItem,
                            booking: bookings[classItem.id]
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct UpcomingClassCard: View {
    let classItem: Class
    let booking: Booking?
    @State private var venue: Venue?
    @State private var instructor: User?
    @State private var showingCancelAlert = false
    @State private var isCancelling = false
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            HStack(spacing: 16) {
                // Time Column
                VStack(spacing: 4) {
                    Text(classItem.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(classItem.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: 60)
                
                // Class Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(classItem.name)
                        .font(.headline)
                    
                    if let instructor = instructor {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray)
                            Text(instructor.displayName)
                                .foregroundColor(.gray)
                        }
                        .font(.subheadline)
                    }
                    
                    HStack {
                        StatusTag(text: "\(classItem.duration)m", icon: "clock.fill", color: .gray)
                        StatusTag(text: classItem.level.rawValue, icon: "speedometer", color: .gray)
                        if let booking = booking {
                            StatusTag(
                                text: booking.status == .confirmed ? "Confirmed" :
                                      booking.status == .waitlisted ? "Waitlisted" : "Cancelled",
                                icon: booking.status == .confirmed ? "checkmark.circle.fill" :
                                      booking.status == .waitlisted ? "clock.fill" : "xmark.circle.fill",
                                color: booking.status == .confirmed ? .green :
                                       booking.status == .waitlisted ? .orange : .red
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Action Button
                NavigationLink(destination: ClassDetailView(classId: classItem.id)) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .alert("Cancel Booking", isPresented: $showingCancelAlert) {
            Button("Cancel Booking", role: .destructive) {
                Task {
                    await cancelBooking()
                }
            }
            Button("Keep Booking", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this booking? This action cannot be undone.")
        }
        .alert("Error", isPresented: .init(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        }
        .task {
            do {
                async let venueResult = VenueService.shared.getVenue(id: classItem.venueId)
                async let instructorResult = UserService.shared.getUser(id: classItem.instructorId)
                
                let (venue, instructor) = try await (venueResult, instructorResult)
                self.venue = venue
                self.instructor = instructor
            } catch {
                self.error = error
            }
        }
        .contextMenu {
            if let booking = booking, booking.status != .cancelled {
                Button(role: .destructive) {
                    showingCancelAlert = true
                } label: {
                    Label("Cancel Booking", systemImage: "xmark.circle")
                }
            }
        }
    }
    
    private func cancelBooking() async {
        guard let booking = booking else { return }
        
        isCancelling = true
        error = nil
        
        do {
            try await BookingService.shared.cancelBooking(bookingId: booking.id)
        } catch {
            self.error = error
        }
        
        isCancelling = false
    }
}

struct PastClassCard: View {
    let classItem: Class
    let booking: Booking?
    @State private var venue: Venue?
    @State private var instructor: User?
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            HStack(spacing: 16) {
                // Time Column
                VStack(spacing: 4) {
                    Text(classItem.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(classItem.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: 60)
                
                // Class Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(classItem.name)
                        .font(.headline)
                    
                    if let instructor = instructor {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray)
                            Text(instructor.displayName)
                                .foregroundColor(.gray)
                        }
                        .font(.subheadline)
                    }
                    
                    HStack {
                        StatusTag(text: "\(classItem.duration)m", icon: "clock.fill", color: .gray)
                        StatusTag(text: classItem.level.rawValue, icon: "speedometer", color: .gray)
                        if let booking = booking {
                            StatusTag(
                                text: booking.status == .confirmed ? "Attended" : "Cancelled",
                                icon: booking.status == .confirmed ? "checkmark.circle.fill" : "xmark.circle.fill",
                                color: booking.status == .confirmed ? .green : .red
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Action Button
                NavigationLink(destination: ClassDetailView(classId: classItem.id)) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .task {
            do {
                async let venueResult = VenueService.shared.getVenue(id: classItem.venueId)
                async let instructorResult = UserService.shared.getUser(id: classItem.instructorId)
                
                let (venue, instructor) = try await (venueResult, instructorResult)
                self.venue = venue
                self.instructor = instructor
            } catch {
                self.error = error
            }
        }
    }
}

struct StatusTag: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(calendar.component(.day, from: date).description)
                    .font(.headline)
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption2)
                    .textCase(.uppercase)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 45, height: 64)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
} 