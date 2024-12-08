const admin = require('firebase-admin');

// Initialize without credentials for emulator
admin.initializeApp({
  projectId: 'coachspace-62ebd'
});

const db = admin.firestore();
// Configure to use emulator
db.settings({
  host: 'localhost:8080',
  ssl: false
});

async function seedData() {
  console.log('Starting to seed data...');

  // Create venues
  const venues = [
    {
      id: 'venue1',
      name: 'Whistler Blackcomb',
      description: 'World-renowned ski resort with extensive terrain for all skill levels.',
      address: '4545 Blackcomb Way, Whistler, BC V8E 0X9, Canada',
      coordinates: {
        latitude: 50.1163,
        longitude: -122.9574
      },
      type: 'resort',
      amenities: ['rentals', 'lessons', 'dining', 'parking'],
      imageURL: 'https://example.com/whistler.jpg',
      trailMap: 'https://example.com/whistler-trail-map.jpg',
      operatingHours: [],
      weatherInfo: null,
      status: 'open',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    },
    {
      id: 'venue2',
      name: 'Grouse Mountain',
      description: 'Local mountain with excellent facilities and night skiing.',
      address: '6400 Nancy Greene Way, North Vancouver, BC V7R 4K9, Canada',
      coordinates: {
        latitude: 49.3808,
        longitude: -123.0828
      },
      type: 'resort',
      amenities: ['rentals', 'lessons', 'dining', 'parking', 'night skiing'],
      imageURL: 'https://example.com/grouse.jpg',
      trailMap: 'https://example.com/grouse-trail-map.jpg',
      operatingHours: [],
      weatherInfo: null,
      status: 'open',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    }
  ];

  // Create instructors
  const instructors = [
    {
      id: 'instructor1',
      email: 'mike@example.com',
      displayName: 'Mike Wilson',
      phoneNumber: '+1234567890',
      imageURL: 'https://example.com/mike.jpg',
      role: 'instructor',
      preferences: {
        preferredCategories: ['snowboard'],
        preferredLevels: ['beginner', 'intermediate'],
        preferredInstructors: [],
        preferredVenues: ['venue1', 'venue2'],
        equipment: {
          hasOwnEquipment: true,
          equipmentDetails: ['Burton Custom Board', 'Burton Boots'],
          preferredRentalLocation: null
        },
        notifications: {
          classReminders: true,
          promotions: true,
          messages: true,
          email: true,
          push: true,
          sms: true
        }
      },
      stats: {
        totalClasses: 150,
        totalHours: 450,
        averageRating: 4.8,
        skillLevels: [],
        achievements: []
      },
      settings: {
        language: 'en',
        timezone: 'America/Vancouver',
        currency: 'CAD',
        measurementSystem: 'metric'
      },
      status: 'active',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    },
    {
      id: 'instructor2',
      email: 'sarah@example.com',
      displayName: 'Sarah Johnson',
      phoneNumber: '+1987654321',
      imageURL: 'https://example.com/sarah.jpg',
      role: 'instructor',
      preferences: {
        preferredCategories: ['ski'],
        preferredLevels: ['intermediate', 'advanced'],
        preferredInstructors: [],
        preferredVenues: ['venue1'],
        equipment: {
          hasOwnEquipment: true,
          equipmentDetails: ['Atomic Redster Skis', 'Atomic Boots'],
          preferredRentalLocation: null
        },
        notifications: {
          classReminders: true,
          promotions: true,
          messages: true,
          email: true,
          push: true,
          sms: true
        }
      },
      stats: {
        totalClasses: 200,
        totalHours: 600,
        averageRating: 4.9,
        skillLevels: [],
        achievements: []
      },
      settings: {
        language: 'en',
        timezone: 'America/Vancouver',
        currency: 'CAD',
        measurementSystem: 'metric'
      },
      status: 'active',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    }
  ];

  // Create classes
  const classes = [
    {
      id: 'class1',
      name: 'Beginner Snowboarding',
      description: 'Perfect introduction to snowboarding. Learn the basics of stance, balance, and control.',
      instructorId: 'instructor1',
      venueId: 'venue1',
      category: 'snowboard',
      level: 'beginner',
      duration: 120,
      price: 99.99,
      startTime: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)), // Tomorrow
      maxParticipants: 6,
      currentParticipants: 3,
      imageURL: 'https://example.com/snowboard-beginner.jpg',
      tags: ['beginner', 'basics', 'snowboard'],
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    },
    {
      id: 'class2',
      name: 'Advanced Ski Techniques',
      description: 'Master advanced skiing techniques including carving, moguls, and off-piste skiing.',
      instructorId: 'instructor2',
      venueId: 'venue1',
      category: 'ski',
      level: 'advanced',
      duration: 180,
      price: 149.99,
      startTime: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 172800000)), // Day after tomorrow
      maxParticipants: 4,
      currentParticipants: 2,
      imageURL: 'https://example.com/ski-advanced.jpg',
      tags: ['advanced', 'ski', 'techniques'],
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    },
    {
      id: 'class3',
      name: 'Intermediate Snowboarding',
      description: 'Take your snowboarding to the next level with intermediate techniques and tricks.',
      instructorId: 'instructor1',
      venueId: 'venue2',
      category: 'snowboard',
      level: 'intermediate',
      duration: 150,
      price: 129.99,
      startTime: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 86400000)), // Yesterday
      maxParticipants: 5,
      currentParticipants: 5,
      imageURL: 'https://example.com/snowboard-intermediate.jpg',
      tags: ['intermediate', 'snowboard', 'tricks'],
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    }
  ];

  // Create bookings
  const bookings = [
    {
      id: 'booking1',
      classId: 'class1',
      userId: 'user1',
      status: 'confirmed',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      id: 'booking2',
      classId: 'class2',
      userId: 'user1',
      status: 'confirmed',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      id: 'booking3',
      classId: 'class3',
      userId: 'user2',
      status: 'confirmed',
      createdAt: admin.firestore.Timestamp.now()
    }
  ];

  // Create reviews
  const reviews = [
    {
      id: 'review1',
      classId: 'class1',
      userId: 'user1',
      rating: 5,
      comment: 'Great introduction to snowboarding! Mike is an excellent instructor.',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      id: 'review2',
      classId: 'class2',
      userId: 'user2',
      rating: 4,
      comment: 'Sarah really knows her stuff. Advanced techniques were well explained.',
      createdAt: admin.firestore.Timestamp.now()
    }
  ];

  // Additional bookings
  const additionalBookings = [
    {
      id: 'booking6',
      classId: 'class1',
      userId: 'user3',
      status: 'confirmed',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      id: 'booking7',
      classId: 'class2',
      userId: 'user1',
      status: 'confirmed',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      id: 'booking8',
      classId: 'class3',
      userId: 'user4',
      status: 'confirmed',
      createdAt: admin.firestore.Timestamp.now()
    }
  ];

  // Additional reviews
  const additionalReviews = [
    {
      id: 'review5',
      classId: 'class2',
      userId: 'user2',
      rating: 5,
      comment: 'The advanced techniques were perfectly explained. Great progression!',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      id: 'review6',
      classId: 'class1',
      userId: 'user4',
      rating: 4,
      comment: 'Great beginner class, very patient instructor.',
      createdAt: admin.firestore.Timestamp.now()
    }
  ];

  try {
    // Add venues
    for (const venue of venues) {
      await db.collection('venues').doc(venue.id).set(venue);
    }
    console.log('Venues seeded successfully');

    // Add instructors
    for (const instructor of instructors) {
      await db.collection('users').doc(instructor.id).set(instructor);
    }
    console.log('Instructors seeded successfully');

    // Add classes
    for (const classData of classes) {
      await db.collection('classes').doc(classData.id).set(classData);
    }
    console.log('Classes seeded successfully');

    // Add all bookings
    const allBookings = [...bookings, ...additionalBookings];
    for (const booking of allBookings) {
      if (booking.id) {
        await db.collection('bookings').doc(booking.id).set(booking);
      }
    }
    console.log('Bookings seeded successfully');

    // Add all reviews
    const allReviews = [...reviews, ...additionalReviews];
    for (const review of allReviews) {
      if (review.id) {
        await db.collection('reviews').doc(review.id).set(review);
      }
    }
    console.log('Reviews seeded successfully');

    console.log('All data seeded successfully!');
  } catch (error) {
    console.error('Error seeding data:', error);
  }
}

// Run the seed function
seedData().then(() => {
  console.log('Seed script completed');
  process.exit(0);
}).catch((error) => {
  console.error('Seed script failed:', error);
  process.exit(1);
}); 