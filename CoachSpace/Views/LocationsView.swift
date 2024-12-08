import SwiftUI
import MapKit

struct LocationsView: View {
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.1163, longitude: -122.9574), // Whistler coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    @State private var selectedSchool: School?
    @State private var showingFilters = false
    @State private var searchText = ""
    @State private var mapStyle: MapStyle = .standard
    
    enum MapStyle {
        case standard, satellite, hybrid
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Map
            Map(position: $position) {
                ForEach(sampleSchools) { school in
                    Annotation(school.name, coordinate: school.coordinate) {
                        SchoolMapMarker(school: school, isSelected: selectedSchool?.id == school.id) {
                            selectedSchool = school
                        }
                    }
                }
                UserAnnotation()
            }
            .mapStyle(mapStyle == .standard ? .standard : mapStyle == .satellite ? .imagery : .hybrid)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .ignoresSafeArea()
            
            // Search and Filters
            VStack(spacing: 16) {
                // Search Bar
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search locations", text: $searchText)
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Map Style Selector
                Picker("Map Style", selection: $mapStyle) {
                    Text("Standard").tag(MapStyle.standard)
                    Text("Satellite").tag(MapStyle.satellite)
                    Text("Hybrid").tag(MapStyle.hybrid)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // School List
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(sampleSchools) { school in
                            SchoolCard(school: school, isSelected: selectedSchool?.id == school.id)
                                .onTapGesture {
                                    withAnimation {
                                        selectedSchool = school
                                        position = .region(MKCoordinateRegion(
                                            center: school.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        ))
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Selected School Detail
            if let school = selectedSchool {
                VStack {
                    Spacer()
                    SchoolDetailCard(school: school) {
                        selectedSchool = nil
                    }
                }
                .transition(.move(edge: .bottom))
            }
        }
    }
}

struct School: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let rating: Double
    let reviewCount: Int
    let coordinate: CLLocationCoordinate2D
    let imageURL: String
    let address: String
    let activeInstructors: Int
    let classesAvailable: Int
}

struct SchoolMapMarker: View {
    let school: School
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "building.2")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .blue)
                    .padding(8)
                    .background(isSelected ? Color.blue : Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 4)
                
                if isSelected {
                    Text(school.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
            }
        }
    }
}

struct SchoolCard: View {
    let school: School
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(school.imageURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 120)
                .clipped()
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(school.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", school.rating))
                    Text("(\(school.reviewCount))")
                        .foregroundColor(.gray)
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 200)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue, lineWidth: isSelected ? 2 : 0)
        )
    }
}

struct SchoolDetailCard: View {
    let school: School
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 4)
                .padding(.vertical, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Image
                    Image(school.imageURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(16)
                    
                    // School Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(school.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(school.type)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Label("\(school.rating, specifier: "%.1f")", systemImage: "star.fill")
                                .foregroundColor(.yellow)
                            Text("(\(school.reviewCount) reviews)")
                                .foregroundColor(.gray)
                        }
                        .font(.subheadline)
                    }
                    
                    Divider()
                    
                    // Quick Stats
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(school.activeInstructors)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Instructors")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        VStack {
                            Text("\(school.classesAvailable)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Classes")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Label("View Classes", systemImage: "calendar")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {}) {
                            Label("Contact", systemImage: "message")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height > 100 {
                        onDismiss()
                    }
                }
        )
    }
}

// Sample Data
let sampleSchools = [
    School(
        name: "Whistler Blackcomb Snow School",
        type: "Ski & Snowboard School",
        rating: 4.8,
        reviewCount: 1250,
        coordinate: CLLocationCoordinate2D(latitude: 50.1163, longitude: -122.9574),
        imageURL: "school_image1",
        address: "4545 Blackcomb Way, Whistler, BC V8E 0X9",
        activeInstructors: 85,
        classesAvailable: 32
    ),
    School(
        name: "Peak Performance Academy",
        type: "Advanced Training Center",
        rating: 4.7,
        reviewCount: 820,
        coordinate: CLLocationCoordinate2D(latitude: 50.1158, longitude: -122.9482),
        imageURL: "school_image2",
        address: "4293 Mountain Square, Whistler, BC V8E 1B8",
        activeInstructors: 45,
        classesAvailable: 18
    ),
    School(
        name: "Creekside Ski School",
        type: "Beginner Friendly",
        rating: 4.6,
        reviewCount: 650,
        coordinate: CLLocationCoordinate2D(latitude: 50.0839, longitude: -122.9726),
        imageURL: "school_image3",
        address: "2101 Lake Placid Rd, Whistler, BC V8E 0B6",
        activeInstructors: 30,
        classesAvailable: 24
    )
]

struct LocationsView_Previews: PreviewProvider {
    static var previews: some View {
        LocationsView()
    }
} 