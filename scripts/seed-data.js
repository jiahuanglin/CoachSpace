const admin = require('firebase-admin');

// Initialize without credentials for emulator
admin.initializeApp({
  projectId: 'coachspace-62ebd'
});

const db = admin.firestore();
const auth = admin.auth();

// Configure emulators
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';

db.settings({
  host: 'localhost:8080',
  ssl: false
});

async function createAuthUser(email, password, displayName) {
  try {
    // Check if user already exists
    try {
      const userRecord = await auth.getUserByEmail(email);
      console.log(`User ${email} already exists with ID: ${userRecord.uid}`);
      return userRecord.uid;
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // Create new user if not found
        const newUser = await auth.createUser({
          email: email,
          password: password,
          displayName: displayName,
          emailVerified: true
        });
        console.log(`Created new user ${email} with ID: ${newUser.uid}`);
        return newUser.uid;
      }
      throw error;
    }
  } catch (error) {
    console.error('Error in createAuthUser:', error);
    throw error;
  }
}

async function seedData() {
  try {
    console.log('Starting to seed data...');

    // Create demo users in Authentication first
    const demoUsers = [
      {
        email: 'student@example.com',
        password: 'password123',
        displayName: 'Alex Chen',
        role: 'student',
        preferences: {
          preferredCategories: ['Snowboard', 'Ski'],
          preferredLevels: ['Beginner', 'Intermediate'],
          preferredInstructors: [],
          preferredVenues: [],
          notifications: {
            classReminders: true,
            promotions: false,
            messages: true,
            email: true,
            push: true,
            sms: false
          }
        },
        stats: {
          totalClasses: 10,
          totalHours: 30,
          averageRating: 0,
          skillLevels: [
            {
              category: 'Snowboard',
              level: 'Intermediate',
              progress: 0.6,
              updatedAt: admin.firestore.Timestamp.now()
            }
          ],
          achievements: [
            {
              id: 'ach1',
              title: 'First Black Diamond',
              description: 'Completed first black diamond run',
              category: 'skill',
              progress: 1.0,
              isCompleted: true,
              completedAt: admin.firestore.Timestamp.now(),
              icon: 'mountain.2.fill'
            },
            {
              id: 'ach2',
              title: 'Early Bird',
              description: 'Complete 5 morning sessions',
              category: 'attendance',
              progress: 0.6,
              isCompleted: false,
              completedAt: null,
              icon: 'sunrise.fill'
            }
          ]
        }
      },
      {
        email: 'instructor@example.com',
        password: 'password123',
        displayName: 'Mike Wilson',
        role: 'instructor',
        preferences: {
          preferredCategories: ['Snowboard', 'Ski'],
          preferredLevels: ['Intermediate', 'Advanced'],
          preferredInstructors: [],
          preferredVenues: ['venue1', 'venue2'],
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
          averageRating: 4.9,
          skillLevels: [
            {
              category: 'Snowboard',
              level: 'Expert',
              progress: 1.0,
              updatedAt: admin.firestore.Timestamp.now()
            }
          ],
          achievements: [
            {
              id: 'ach3',
              title: 'Master Instructor',
              description: 'Taught 100+ successful classes',
              category: 'teaching',
              progress: 1.0,
              isCompleted: true,
              completedAt: admin.firestore.Timestamp.now(),
              icon: 'star.fill'
            },
            {
              id: 'ach4',
              title: 'Safety Expert',
              description: '1000+ accident-free lessons',
              category: 'safety',
              progress: 1.0,
              isCompleted: true,
              completedAt: admin.firestore.Timestamp.now(),
              icon: 'shield.fill'
            }
          ]
        }
      }
    ];

    // Create auth users and store their UIDs
    const userIds = {};
    for (const user of demoUsers) {
      try {
        const uid = await createAuthUser(user.email, user.password, user.displayName);
        userIds[user.email] = uid;

        // Create or update Firestore user document
        await db.collection('users').doc(uid).set({
          id: uid,
          email: user.email,
          displayName: user.displayName,
          phoneNumber: null,
          imageURL: null,
          role: user.role,
          preferences: user.preferences,
          stats: user.stats,
          settings: {
            language: 'en',
            timezone: 'America/Vancouver',
            currency: 'CAD',
            measurementSystem: 'metric'
          },
          status: 'active',
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now()
        }, { merge: true });

        console.log(`Created/Updated Firestore document for user: ${user.email}`);
      } catch (error) {
        console.error(`Error processing user ${user.email}:`, error);
        throw error;
      }
    }

    // Create classes
    const classes = [
      {
        id: 'class1',
        name: 'Beginner Snowboarding',
        description: 'Learn the basics of snowboarding in a fun and safe environment',
        instructorId: userIds['instructor@example.com'],
        venueId: 'venue1',
        category: 'Snowboard',
        level: 'Beginner',
        duration: 120,
        price: 99.99,
        startTime: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)), // Tomorrow
        maxParticipants: 6,
        currentParticipants: 0,
        imageURL: 'https://example.com/snowboard-class.jpg',
        tags: ['beginner', 'snowboard', 'basics'],
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      },
      {
        id: 'class2',
        name: 'Advanced Skiing Techniques',
        description: 'Master advanced skiing techniques and conquer challenging terrain',
        instructorId: userIds['instructor@example.com'],
        venueId: 'venue1',
        category: 'Ski',
        level: 'Advanced',
        duration: 180,
        price: 149.99,
        startTime: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 172800000)), // Day after tomorrow
        maxParticipants: 4,
        currentParticipants: 0,
        imageURL: 'https://example.com/ski-class.jpg',
        tags: ['advanced', 'ski', 'techniques'],
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      }
    ];

    // Seed classes
    for (const classData of classes) {
      await db.collection('classes').doc(classData.id).set(classData);
      console.log(`Created class: ${classData.name}`);
    }

    console.log('Seed data written successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding data:', error);
    process.exit(1);
  }
}

seedData(); 