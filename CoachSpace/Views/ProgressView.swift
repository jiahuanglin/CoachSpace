import SwiftUI

struct ProgressView: View {
    @State private var selectedTimeFrame: TimeFrame = .month
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Frame Selector
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.rawValue).tag(timeFrame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Progress Summary Card
                    VStack(spacing: 16) {
                        HStack(spacing: 40) {
                            ProgressStat(value: "12", title: "Classes\nCompleted")
                            ProgressStat(value: "48", title: "Hours\nPracticed")
                            ProgressStat(value: "4.8", title: "Average\nRating")
                        }
                        
                        Divider()
                        
                        // Level Progress
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Level: Intermediate")
                                .font(.headline)
                            
                            HStack {
                                Text("Progress to Advanced")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("75%")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            ProgressBar(value: 0.75)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10)
                    .padding(.horizontal)
                    
                    // Skills Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Skills Breakdown")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            SkillProgressRow(skill: "Carving", progress: 0.8, level: "Advanced")
                            SkillProgressRow(skill: "Switch Riding", progress: 0.6, level: "Intermediate")
                            SkillProgressRow(skill: "Jumps", progress: 0.4, level: "Beginner")
                            SkillProgressRow(skill: "Rails", progress: 0.3, level: "Beginner")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 10)
                        .padding(.horizontal)
                    }
                    
                    // Recent Achievements
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Achievements")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ProgressAchievementCard(
                                    title: "Speed Demon",
                                    description: "Reached 50km/h",
                                    progress: 1.0,
                                    icon: "speedometer",
                                    color: .orange
                                )
                                
                                ProgressAchievementCard(
                                    title: "Early Bird",
                                    description: "5 morning classes",
                                    progress: 0.6,
                                    icon: "sunrise",
                                    color: .blue
                                )
                                
                                ProgressAchievementCard(
                                    title: "Consistent",
                                    description: "10 classes in a month",
                                    progress: 0.8,
                                    icon: "calendar",
                                    color: .green
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Classes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Classes")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(0..<3) { _ in
                                CompletedClassCard()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGray6))
            .navigationTitle("Progress")
        }
    }
}

struct ProgressStat: View {
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
}

struct ProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * value, height: 8)
                    .cornerRadius(4)
            }
        }
        .frame(height: 8)
    }
}

struct SkillProgressRow: View {
    let skill: String
    let progress: Double
    let level: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(skill)
                    .font(.headline)
                Spacer()
                Text(level)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            ProgressBar(value: progress)
        }
    }
}

struct ProgressAchievementCard: View {
    let title: String
    let description: String
    let progress: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            ProgressBar(value: progress)
        }
        .frame(width: 160)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct CompletedClassCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image("class_image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Advanced Carving")
                    .font(.headline)
                
                Text("with Mike Wilson")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: "star.fill")
                            .foregroundColor(index < 4 ? .yellow : .gray)
                    }
                }
            }
            
            Spacer()
            
            Text("Dec 8")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView()
    }
} 