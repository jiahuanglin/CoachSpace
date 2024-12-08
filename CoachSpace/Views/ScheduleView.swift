import SwiftUI

struct ScheduleView: View {
    @State private var selectedTab = 0
    @State private var selectedDate = Date()
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
                
                if selectedTab == 0 {
                    UpcomingClassesView()
                } else {
                    PastClassesView()
                }
            }
            .navigationTitle("Schedule")
            .background(Color(.systemGray6))
        }
    }
}

struct UpcomingClassesView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<5) { index in
                    UpcomingClassCard(
                        showBookingStatus: index == 0,
                        showPaymentStatus: index == 1
                    )
                }
            }
            .padding()
        }
    }
}

struct PastClassesView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<10) { _ in
                    PastClassCard()
                }
            }
            .padding()
        }
    }
}

struct UpcomingClassCard: View {
    var showBookingStatus: Bool = false
    var showPaymentStatus: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            HStack(spacing: 16) {
                // Time Column
                VStack(spacing: 4) {
                    Text("9:30")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("AM")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: 60)
                
                // Class Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Advanced Snowboarding")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                        Text("Mike Wilson")
                            .foregroundColor(.gray)
                    }
                    .font(.subheadline)
                    
                    HStack {
                        StatusTag(text: "2h", icon: "clock.fill")
                        StatusTag(text: "Intermediate", icon: "speedometer")
                    }
                }
                
                Spacer()
                
                // Action Button
                Button(action: {}) {
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
            } else if showPaymentStatus {
                StatusBar(
                    text: "Payment Pending",
                    icon: "exclamationmark.circle.fill",
                    color: .orange
                )
            }
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct PastClassCard: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Class Image
                Image("class_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                
                // Class Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced Snowboarding")
                        .font(.headline)
                    
                    Text("with Mike Wilson")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .foregroundColor(index < 4 ? .yellow : .gray)
                        }
                        Text("4.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Date
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Dec 1")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Button(action: {}) {
                        Text("Review")
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