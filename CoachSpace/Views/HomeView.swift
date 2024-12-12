import SwiftUI

struct HomeView: View {
    @State private var selectedCategory: Class.Category?
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section with parallax
                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY
                        ZStack(alignment: .bottom) {
                            Image("featured_background")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(
                                    width: geometry.size.width,
                                    height: geometry.size.height + (minY > 0 ? minY : 0)
                                )
                                .clipped()
                                .offset(y: minY > 0 ? -minY : 0)
                            
                            // Gradient overlay
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear,
                                    .black.opacity(0.4),
                                    .black.opacity(0.8)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            
                            // Content
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Featured Experience")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("Master the Slopes")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Join expert instructors for an unforgettable winter adventure")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.bottom, 8)
                                
                                Button(action: {}) {
                                    Text("Explore Winter Sports")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(height: 500)
                    
                    // Main Content
                    VStack(spacing: 32) {
                        // Category Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Class.Category.allCases, id: \.self) { category in
                                    CategoryPill(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        action: { selectedCategory = category }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)
                        
                        // Nearby Classes
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Nearby Classes", icon: "map")
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(0..<5) { _ in
                                        NearbyClassCard()
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Popular Instructors
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Top Rated Instructors", icon: "star.fill")
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(0..<5) { _ in
                                        PopularInstructorCard()
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .overlay(
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                ,
                alignment: .top
            )
        }
        .navigationBarHidden(true)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search classes, instructors, or venues", text: $text)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct CategoryPill: View {
    let category: Class.Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                Text(category.rawValue)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct NearbyClassCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            ZStack(alignment: .topTrailing) {
                Image("class_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 280, height: 200)
                    .clipped()
                    .cornerRadius(24)
                
                Text("1.2 km")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Snowboard Basics")
                        .font(.headline)
                    Spacer()
                    Text("$85")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("4.8")
                        .fontWeight(.medium)
                    Text("(124)")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("2h")
                        .foregroundColor(.gray)
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct PopularInstructorCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Instructor Image
            Image("instructor_image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Sarah Johnson")
                    .font(.headline)
                
                Text("Snowboard Expert • 8 yrs")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: "star.fill")
                            .foregroundColor(index < 4 ? .yellow : .gray)
                    }
                    Text("(127)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 200)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Button(action: {}) {
                Text("View All")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
} 