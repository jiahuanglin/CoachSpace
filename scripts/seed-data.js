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
      { email: 'student@example.com', password: 'password123', displayName: 'Alex Chen', role: 'student' },
      { email: 'instructor@example.com', password: 'password123', displayName: 'Mike Wilson', role: 'instructor' },
      { email: 'admin@example.com', password: 'password123', displayName: 'Admin User', role: 'admin' }
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
          role: user.role,
          phoneNumber: null,
          imageURL: null,
          preferences: {
            preferredCategories: [],
            preferredLevels: [],
            preferredInstructors: [],
            preferredVenues: [],
            equipment: {
              hasOwnEquipment: false,
              equipmentDetails: [],
              preferredRentalLocation: null
            },
            notifications: {
              classReminders: true,
              promotions: true,
              messages: true,
              email: true,
              push: true,
              sms: false
            }
          },
          stats: {
            totalClasses: 0,
            totalHours: 0,
            averageRating: 0,
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
        }, { merge: true });
        
        console.log(`Created/Updated Firestore document for user: ${user.email}`);
      } catch (error) {
        console.error(`Error processing user ${user.email}:`, error);
        throw error;
      }
    }

    console.log('Seed data written successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding data:', error);
    process.exit(1);
  }
}

seedData(); 