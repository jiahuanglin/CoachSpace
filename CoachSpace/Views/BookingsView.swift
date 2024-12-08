import SwiftUI

struct BookingsView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Custom segmented control
                Picker("Bookings", selection: $selectedTab) {
                    Text("Upcoming").tag(0)
                    Text("Past").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    UpcomingBookingsList()
                } else {
                    PastBookingsList()
                }
            }
            .navigationTitle("My Bookings")
        }
    }
}

struct UpcomingBookingsList: View {
    var body: some View {
        List {
            ForEach(0..<3) { _ in
                BookingCard(isPast: false)
            }
        }
    }
}

struct PastBookingsList: View {
    var body: some View {
        List {
            ForEach(0..<5) { _ in
                BookingCard(isPast: true)
            }
        }
    }
}

struct BookingCard: View {
    let isPast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Power Yoga")
                        .font(.headline)
                    Text("Core Power Yoga - Downtown")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                if !isPast {
                    Button(action: {}) {
                        Text("Cancel")
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Label("Wed, Dec 8", systemImage: "calendar")
                Spacer()
                Label("9:30 AM", systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            
            if !isPast {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.blue)
                    Text("123 Main St, San Francisco")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Button(action: {}) {
                    Text("View Details")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.vertical, 4)
    }
}

struct BookingsView_Previews: PreviewProvider {
    static var previews: some View {
        BookingsView()
    }
} 