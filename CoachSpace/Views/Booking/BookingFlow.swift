import SwiftUI

struct BookingFlow: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var hasAgreedToWaiver = false
    @State private var selectedEquipment = "Own Equipment"
    @State private var selectedLevel = "Intermediate"
    let classDetails: Class // Renamed from 'class'
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Steps
                StepProgressView(currentStep: currentStep)
                    .padding()
                
                TabView(selection: $currentStep) {
                    // Step 1: Class Info
                    ClassInfoView(classDetails: classDetails)
                        .tag(0)
                    
                    // Step 2: Requirements & Equipment
                    RequirementsView(selectedEquipment: $selectedEquipment, selectedLevel: $selectedLevel)
                        .tag(1)
                    
                    // Step 3: Waiver
                    WaiverView(hasAgreed: $hasAgreedToWaiver)
                        .tag(2)
                    
                    // Step 4: Payment
                    PaymentView()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom Button
                VStack(spacing: 16) {
                    if currentStep == 2 && !hasAgreedToWaiver {
                        Text("Please read and accept the waiver to continue")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: handleButtonTap) {
                        Text(buttonTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(buttonEnabled ? Color.blue : Color.gray)
                            .cornerRadius(16)
                    }
                    .disabled(!buttonEnabled)
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(radius: 8)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
        }
    }
    
    private var navigationTitle: String {
        switch currentStep {
        case 0: return "Class Details"
        case 1: return "Requirements"
        case 2: return "Waiver"
        case 3: return "Payment"
        default: return ""
        }
    }
    
    private var buttonTitle: String {
        if currentStep == 3 { return "Confirm Payment" }
        return "Continue"
    }
    
    private var buttonEnabled: Bool {
        if currentStep == 2 { return hasAgreedToWaiver }
        return true
    }
    
    private func handleButtonTap() {
        if currentStep == 3 {
            // Handle payment confirmation
            dismiss()
        } else {
            withAnimation {
                currentStep += 1
            }
        }
    }
}

struct StepProgressView: View {
    let currentStep: Int
    private let steps = ["Info", "Requirements", "Waiver", "Payment"]
    
    var body: some View {
        HStack {
            ForEach(0..<steps.count, id: \.self) { index in
                if index > 0 {
                    Rectangle()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 2)
                }
                
                Circle()
                    .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
            }
        }
    }
}

struct ClassInfoView: View {
    let classDetails: Class
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Class Image
                Image("class_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(16)
                
                // Class Details
                VStack(alignment: .leading, spacing: 16) {
                    Text(classDetails.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Instructor Info
                    HStack {
                        Image("instructor_image")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(classDetails.instructor.name)
                                .font(.headline)
                            Text("\(classDetails.instructor.yearsOfExperience) years experience")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Class Info Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        InfoItem(title: "Date", value: classDetails.startTime.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                        InfoItem(title: "Time", value: classDetails.startTime.formatted(date: .omitted, time: .shortened), icon: "clock")
                        InfoItem(title: "Duration", value: "\(classDetails.duration) min", icon: "timer")
                        InfoItem(title: "Level", value: classDetails.level.rawValue, icon: "speedometer")
                    }
                    
                    Divider()
                    
                    // Description
                    Text("About this class")
                        .font(.headline)
                    Text(classDetails.description)
                        .foregroundColor(.gray)
                }
                .padding()
            }
        }
    }
}

struct RequirementsView: View {
    @Binding var selectedEquipment: String
    @Binding var selectedLevel: String
    
    private let equipmentOptions = ["Own Equipment", "Need Rental", "Not Sure"]
    private let levelOptions = ["Beginner", "Intermediate", "Advanced", "Expert"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Equipment Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Equipment")
                        .font(.headline)
                    
                    ForEach(equipmentOptions, id: \.self) { option in
                        Button(action: { selectedEquipment = option }) {
                            HStack {
                                Image(systemName: selectedEquipment == option ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedEquipment == option ? .blue : .gray)
                                Text(option)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // Skill Level Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Skill Level")
                        .font(.headline)
                    
                    ForEach(levelOptions, id: \.self) { level in
                        Button(action: { selectedLevel = level }) {
                            HStack {
                                Image(systemName: selectedLevel == level ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedLevel == level ? .blue : .gray)
                                Text(level)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // Requirements List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Requirements")
                        .font(.headline)
                    
                    RequirementRow(text: "Warm, waterproof clothing", isRequired: true)
                    RequirementRow(text: "Helmet (available for rent)", isRequired: true)
                    RequirementRow(text: "Gloves", isRequired: true)
                    RequirementRow(text: "Goggles", isRequired: false)
                }
            }
            .padding()
        }
    }
}

struct WaiverView: View {
    @Binding var hasAgreed: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Please read the following waiver carefully")
                    .font(.headline)
                
                Text(waiverText)
                    .foregroundColor(.gray)
                
                VStack(spacing: 16) {
                    Button(action: { hasAgreed.toggle() }) {
                        HStack {
                            Image(systemName: hasAgreed ? "checkmark.square.fill" : "square")
                                .foregroundColor(hasAgreed ? .blue : .gray)
                            Text("I have read and agree to the terms above")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private let waiverText = """
    1. ACKNOWLEDGMENT OF RISKS
    
    I understand that participating in snow sports activities, including but not limited to skiing and snowboarding, involves inherent risks, hazards, and dangers that can cause injury, damage, death, or other loss.
    
    2. ASSUMPTION OF RISKS
    
    I expressly agree and promise to accept and assume all risks associated with participating in this activity. My participation is purely voluntary, and I elect to participate in spite of the risks.
    
    3. RELEASE OF LIABILITY
    
    I hereby voluntarily release and forever discharge the instructor, venue, and all other persons or entities from any and all liability, claims, demands, actions, or rights of action related to my participation in this activity.
    
    4. MEDICAL TREATMENT
    
    I authorize and consent to any emergency medical care that may be necessary during the activity.
    
    5. MEDIA RELEASE
    
    I grant permission to use my photographic or video likeness in promotional materials.
    """
}

struct PaymentView: View {
    @State private var selectedCard: Int = 0
    private let cards = ["Visa ending in 4242", "Mastercard ending in 8353"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Price Breakdown
                VStack(spacing: 16) {
                    PriceRow(title: "Class Fee", price: "$120.00")
                    PriceRow(title: "Equipment Rental", price: "$45.00")
                    PriceRow(title: "Insurance", price: "$15.00")
                    
                    Divider()
                    
                    PriceRow(title: "Total", price: "$180.00", isTotal: true)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Payment Method
                VStack(alignment: .leading, spacing: 16) {
                    Text("Payment Method")
                        .font(.headline)
                    
                    ForEach(0..<cards.count, id: \.self) { index in
                        Button(action: { selectedCard = index }) {
                            HStack {
                                Image(systemName: selectedCard == index ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedCard == index ? .blue : .gray)
                                Text(cards[index])
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Card")
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
}

struct InfoItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RequirementRow: View {
    let text: String
    let isRequired: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isRequired ? "checkmark.circle.fill" : "info.circle.fill")
                .foregroundColor(isRequired ? .green : .orange)
            Text(text)
            if isRequired {
                Text("Required")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

struct PriceRow: View {
    let title: String
    let price: String
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(isTotal ? .bold : .regular)
            Spacer()
            Text(price)
                .fontWeight(isTotal ? .bold : .regular)
        }
    }
}

// Sample Data
let sampleClass = Class(
    id: UUID(),
    name: "Advanced Snowboarding",
    description: "Master advanced snowboarding techniques with expert instruction. Perfect for intermediate riders looking to take their skills to the next level.",
    instructor: Instructor(
        id: UUID(),
        name: "Mike Wilson",
        bio: "Professional snowboarder with 10 years of teaching experience.",
        specialties: ["Freestyle", "All-Mountain"],
        rating: 4.9,
        imageURL: "instructor_image",
        certifications: ["PSIA Level 3"],
        yearsOfExperience: 10
    ),
    venue: Venue(
        id: UUID(),
        name: "Whistler Blackcomb",
        address: "4545 Blackcomb Way",
        rating: 4.8,
        imageURL: "venue_image",
        latitude: 50.1163,
        longitude: -122.9574,
        amenities: ["Rental Shop", "Lodge"],
        type: .skiResort
    ),
    category: .snowboard,
    level: .advanced,
    duration: 120,
    price: 120.0,
    startTime: Date().addingTimeInterval(86400), // Tomorrow
    maxParticipants: 6,
    currentParticipants: 3,
    imageURL: "class_image",
    tags: ["Advanced", "All-Mountain"]
)

struct BookingFlow_Previews: PreviewProvider {
    static var previews: some View {
        BookingFlow(classDetails: sampleClass)
    }
} 