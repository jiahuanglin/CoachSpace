import SwiftUI

struct ScheduleView: View {
    @State private var selectedTab = 0
    @State private var selectedDate = Date()
    @State private var calendarSheetPresented = false
    @State private var upcomingClasses: [Class] = []
    @State private var pastClasses: [Class] = []
    @State private var bookings: [String: Booking] = [:]
    @State private var isLoading = false
    @State private var error: Error?
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar Header
                VStack(spacing: 12) {
                    // Month and Year
                    HStack {
                        Text(selectedDate.formatted(.dateTime.month().year()))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            calendarSheetPresented = true
                        }) {
                            Image(systemName: "calendar")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Week View
                    WeekStripView(
                        selectedDate: $selectedDate,
                        onDateSelected: {
                            Task {
                                await loadClasses()
                            }
                        }
                    )
                }
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10)
                )
                .padding()
                
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
            .sheet(isPresented: $calendarSheetPresented) {
                CalendarSheet(
                    selectedDate: $selectedDate,
                    onDateSelected: {
                        calendarSheetPresented = false
                        Task {
                            await loadClasses()
                        }
                    }
                )
            }
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

struct WeekStripView: View {
    @Binding var selectedDate: Date
    let onDateSelected: () -> Void
    private let calendar = Calendar.current
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    @State private var weekOffset = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // Week Navigation
            HStack {
                Button(action: { changeWeek(-1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(weekRange)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: { changeWeek(1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            // Days of Week
            HStack(spacing: 0) {
                ForEach(0..<7) { index in
                    let date = getDate(for: index)
                    DayButton(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        onTap: {
                            selectedDate = date
                            onDateSelected()
                        }
                    )
                }
            }
        }
        .onChange(of: selectedDate) { newDate in
            updateWeekOffset(for: newDate)
        }
    }
    
    private var weekRange: String {
        let startOfWeek = calendar.date(byAdding: .day, value: weekOffset * 7, to: Date())!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
    
    private func getDate(for index: Int) -> Date {
        let startOfWeek = calendar.date(byAdding: .day, value: weekOffset * 7, to: Date())!
        return calendar.date(byAdding: .day, value: index, to: startOfWeek)!
    }
    
    private func changeWeek(_ offset: Int) {
        weekOffset += offset
        let startOfWeek = calendar.date(byAdding: .day, value: weekOffset * 7, to: Date())!
        selectedDate = startOfWeek
        onDateSelected()
    }
    
    private func updateWeekOffset(for date: Date) {
        let today = Date()
        let components = calendar.dateComponents([.day], from: today, to: date)
        if let dayDifference = components.day {
            weekOffset = dayDifference / 7
        }
    }
}

struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Weekday
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .gray)
                
                // Day
                Text("\(calendar.component(.day, from: date))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : isToday ? .blue : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
        }
    }
}

struct CalendarSheet: View {
    @Binding var selectedDate: Date
    let onDateSelected: () -> Void
    @Environment(\.dismiss) private var dismiss
    private let calendar = Calendar.current
    @State private var displayedMonth: Date
    
    init(selectedDate: Binding<Date>, onDateSelected: @escaping () -> Void) {
        self._selectedDate = selectedDate
        self.onDateSelected = onDateSelected
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Month Navigation
                HStack {
                    Button(action: { changeMonth(-1) }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text(displayedMonth.formatted(.dateTime.month().year()))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { changeMonth(1) }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Weekday Headers
                HStack {
                    ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                        Text(weekday)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Calendar Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(days, id: \.self) { date in
                        if let date = date {
                            MonthDayButton(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date)
                            ) {
                                selectedDate = date
                                onDateSelected()
                                dismiss()
                            }
                        } else {
                            Color.clear
                                .aspectRatio(1, contentMode: .fill)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var days: [Date?] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: start)!.count
        
        let firstWeekday = calendar.component(.weekday, from: start)
        let leadingSpaces = firstWeekday - 1
        
        var days: [Date?] = Array(repeating: nil, count: leadingSpaces)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: start) {
                days.append(date)
            }
        }
        
        let trailingSpaces = 7 - (days.count % 7)
        if trailingSpaces < 7 {
            days.append(contentsOf: Array(repeating: nil as Date?, count: trailingSpaces))
        }
        
        return days
    }
    
    private func changeMonth(_ offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

struct MonthDayButton: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            Text("\(calendar.component(.day, from: date))")
                .font(.body)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isSelected ? .white : isToday ? .blue : .primary)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 1)
                        )
                )
        }
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
} 