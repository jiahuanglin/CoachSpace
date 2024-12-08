import SwiftUI

struct ScheduleView: View {
    @State private var selectedTab = 0
    @State private var selectedDate = Date()
    @State private var upcomingClasses: [Class] = []
    @State private var pastClasses: [Class] = []
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
                                action: { selectedDate = date }
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
                        UpcomingClassesView(classes: upcomingClasses)
                    } else {
                        PastClassesView(classes: pastClasses)
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
            let userId = AuthService.shared.currentUser?.id ?? ""
            async let upcoming = ClassService.shared.getUpcomingClasses(for: userId)
            async let past = ClassService.shared.getPastClasses(for: userId)
            
            let (upcomingResult, pastResult) = try await (upcoming, past)
            upcomingClasses = upcomingResult
            pastClasses = pastResult
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

struct UpcomingClassesView: View {
    let classes: [Class]
    
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
                            showBookingStatus: true
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
                        PastClassCard(classItem: classItem)
                    }
                }
                .padding()
            }
        }
    }
}

struct UpcomingClassCard: View {
    let classItem: Class
    var showBookingStatus: Bool = false
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
                        StatusTag(text: "\(classItem.duration)m", icon: "clock.fill")
                        StatusTag(text: classItem.level.rawValue, icon: "speedometer")
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
            
            // Status Bar
            if showBookingStatus {
                StatusBar(
                    text: "Booking Confirmed",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
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
            Button(role: .destructive) {
                showingCancelAlert = true
            } label: {
                Label("Cancel Booking", systemImage: "xmark.circle")
            }
        }
    }
    
    private func cancelBooking() async {
        isCancelling = true
        do {
            let userId = AuthService.shared.currentUser?.id ?? ""
            try await ClassService.shared.cancelBooking(classId: classItem.id, userId: userId)
            NotificationCenter.default.post(name: .ClassCancelled, object: nil)
        } catch {
            self.error = error
        }
        isCancelling = false
    }
}

struct PastClassCard: View {
    let classItem: Class
    @State private var instructor: User?
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Class Image
                if !classItem.imageURL.isEmpty {
                    AsyncImage(url: URL(string: classItem.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                }
                
                // Class Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(classItem.name)
                        .font(.headline)
                    
                    if let instructor = instructor {
                        Text("with \(instructor.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Date
                VStack(alignment: .trailing, spacing: 4) {
                    Text(classItem.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    NavigationLink(destination: ClassDetailView(classId: classItem.id)) {
                        Text("Details")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
        .task {
            do {
                let instructor = try await UserService.shared.getUser(id: classItem.instructorId)
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
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .foregroundColor(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct StatusBar: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
    }
}

struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .gray)
                Text(date.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 45)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(12)
        }
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
} 