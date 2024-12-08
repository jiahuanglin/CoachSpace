import SwiftUI

struct ProfileView: View {
    @State private var isEditingProfile = false
    @State private var selectedLevel: SkillLevel = .intermediate
    
    enum SkillLevel: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .blue
            case .advanced: return .purple
            case .expert: return .orange
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        ZStack(alignment: .bottomTrailing) {
                            Image("profile_image")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 10)
                            
                            Button(action: {}) {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text("Alex Thompson")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Whistler, Canada")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Skill Level Badge
                        HStack {
                            ForEach(SkillLevel.allCases, id: \.self) { level in
                                VStack {
                                    Circle()
                                        .fill(level.color.opacity(selectedLevel == level ? 1 : 0.2))
                                        .frame(width: 12, height: 12)
                                    
                                    Text(level.rawValue)
                                        .font(.caption)
                                        .foregroundColor(selectedLevel == level ? level.color : .gray)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        StatCard(value: "28", title: "Classes", icon: "calendar")
                        StatCard(value: "12", title: "Schools", icon: "building.2")
                        StatCard(value: "8", title: "Instructors", icon: "person.2")
                    }
                    .padding(.horizontal)
                    
                    // Achievements
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Achievements")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                AchievementCard(
                                    title: "Black Diamond",
                                    description: "Completed 5 advanced courses",
                                    icon: "star.circle.fill",
                                    color: .purple
                                )
                                
                                AchievementCard(
                                    title: "Early Bird",
                                    description: "Attended 10 morning classes",
                                    icon: "sunrise.fill",
                                    color: .orange
                                )
                                
                                AchievementCard(
                                    title: "Social Butterfly",
                                    description: "Connected with 5 instructors",
                                    icon: "person.2.fill",
                                    color: .blue
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            ActivityRow(
                                title: "Advanced Snowboarding",
                                subtitle: "Completed class with Mike Wilson",
                                date: "Yesterday",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                            
                            ActivityRow(
                                title: "Whistler Blackcomb",
                                subtitle: "Booked 3 upcoming classes",
                                date: "2 days ago",
                                icon: "calendar.badge.plus",
                                color: .blue
                            )
                            
                            ActivityRow(
                                title: "New Achievement",
                                subtitle: "Earned 'Black Diamond' badge",
                                date: "1 week ago",
                                icon: "star.fill",
                                color: .yellow
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Settings Sections
                    VStack(spacing: 8) {
                        SettingsRow(title: "Preferred Sports", icon: "figure.skiing", color: .blue) {
                            Text("Snowboarding, Skiing")
                                .foregroundColor(.gray)
                        }
                        
                        SettingsRow(title: "Equipment", icon: "skateboard", color: .green) {
                            Text("View List →")
                                .foregroundColor(.blue)
                        }
                        
                        SettingsRow(title: "Payment Methods", icon: "creditcard", color: .purple) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        
                        SettingsRow(title: "Notifications", icon: "bell", color: .orange) {
                            Toggle("", isOn: .constant(true))
                        }
                        
                        Button(action: {}) {
                            Text("Log Out")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGray6))
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Edit") {
                isEditingProfile.toggle()
            })
        }
    }
}

struct StatCard: View {
    let value: String
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct AchievementCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 160)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let date: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(date)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: () -> Content
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
            
            Spacer()
            
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
} 