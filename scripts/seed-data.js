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
            bookingUpdates: true,
            achievementAlerts: true,
            skillLevelUpdates: true,
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
            bookingUpdates: true,
            achievementAlerts: true,
            skillLevelUpdates: true,
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
          fcmToken: null,
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

    // Seed chat rooms and messages
    const chatRooms = [
      {
        id: 'chat1',
        type: 'direct',
        participants: [userIds['student@example.com'], userIds['instructor@example.com']],
        participantProfiles: {
          [userIds['student@example.com']]: {
            displayName: 'Alex Chen',
            imageURL: 'https://example.com/profile1.jpg',
            role: 'student'
          },
          [userIds['instructor@example.com']]: {
            displayName: 'Mike Wilson',
            imageURL: 'https://example.com/profile2.jpg',
            role: 'instructor'
          }
        },
        lastMessage: {
          content: 'See you at the lesson tomorrow!',
          senderId: userIds['instructor@example.com'],
          timestamp: admin.firestore.Timestamp.now(),
          read: false
        },
        unreadCount: {
          [userIds['student@example.com']]: 1,
          [userIds['instructor@example.com']]: 0
        },
        imageURL: 'https://example.com/chat1.jpg',
        createdAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 86400000)), // Yesterday
        updatedAt: admin.firestore.Timestamp.now()
      },
      {
        id: 'chat2',
        type: 'classGroup',
        name: 'Beginner Snowboarding Group',
        participants: [userIds['student@example.com'], userIds['instructor@example.com']],
        participantProfiles: {
          [userIds['student@example.com']]: {
            displayName: 'Alex Chen',
            imageURL: 'https://example.com/profile1.jpg',
            role: 'student'
          },
          [userIds['instructor@example.com']]: {
            displayName: 'Mike Wilson',
            imageURL: 'https://example.com/profile2.jpg',
            role: 'instructor'
          }
        },
        lastMessage: {
          content: 'Don\'t forget to bring your gear!',
          senderId: userIds['instructor@example.com'],
          timestamp: admin.firestore.Timestamp.now(),
          read: false
        },
        unreadCount: {
          [userIds['student@example.com']]: 1,
          [userIds['instructor@example.com']]: 0
        },
        imageURL: 'https://example.com/chat2.jpg',
        createdAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 172800000)), // 2 days ago
        updatedAt: admin.firestore.Timestamp.now()
      }
    ];

    // Create chat room references in userChatRooms collection
    for (const chatRoom of chatRooms) {
      // First create the main chat room document
      await db.collection('chatRooms').doc(chatRoom.id).set({
        ...chatRoom,
        lastMessage: {
          ...chatRoom.lastMessage,
          timestamp: admin.firestore.Timestamp.now()
        },
        updatedAt: admin.firestore.Timestamp.now()
      });
      console.log(`Created main chat room: ${chatRoom.id}`);

      // Then create references for each participant
      for (const userId of chatRoom.participants) {
        const userChatRoom = {
          id: chatRoom.id,
          chatRoomId: chatRoom.id,  // Add this explicit field
          type: chatRoom.type,
          name: chatRoom.name || null,
          participants: chatRoom.participants,
          participantProfiles: chatRoom.participantProfiles,
          lastMessage: chatRoom.lastMessage,
          unreadCount: chatRoom.unreadCount[userId] || 0,
          imageURL: chatRoom.imageURL,
          createdAt: chatRoom.createdAt,
          updatedAt: chatRoom.updatedAt,
          lastReadTimestamp: admin.firestore.Timestamp.now(),
          isArchived: false,
          isPinned: false
        };

        await db.collection('userChatRooms').doc(userId).collection('rooms').doc(chatRoom.id).set(userChatRoom);
        console.log(`Created chat room reference for user: ${userId} in room: ${chatRoom.id}`);
      }
    }

    // Create messages
    const messages = [
      // Chat 1 messages
      {
        id: 'msg1',
        chatRoomId: 'chat1',
        content: 'Welcome to CoachSpace! How can I help you today?',
        senderId: userIds['instructor@example.com'],
        senderProfile: {
          displayName: 'Mike Wilson',
          imageURL: 'https://example.com/profile2.jpg',
          role: 'instructor'
        },
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3600000)), // 1 hour ago
        read: true,
        type: 'text',
        status: 'sent'  // Add message status
      },
      {
        id: 'msg2',
        chatRoomId: 'chat1',
        content: 'Hi! I\'m interested in the beginner snowboarding class',
        senderId: userIds['student@example.com'],
        senderProfile: {
          displayName: 'Alex Chen',
          imageURL: 'https://example.com/profile1.jpg',
          role: 'student'
        },
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3300000)), // 55 min ago
        read: true,
        type: 'text',
        status: 'sent'
      },
      {
        id: 'msg3',
        chatRoomId: 'chat1',
        content: 'Great choice! I see you\'ve already booked. Looking forward to teaching you!',
        senderId: userIds['instructor@example.com'],
        senderProfile: {
          displayName: 'Mike Wilson',
          imageURL: 'https://example.com/profile2.jpg',
          role: 'instructor'
        },
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3000000)), // 50 min ago
        read: true,
        type: 'text',
        status: 'sent'
      },
      {
        id: 'msg4',
        chatRoomId: 'chat1',
        content: 'See you at the lesson tomorrow!',
        senderId: userIds['instructor@example.com'],
        senderProfile: {
          displayName: 'Mike Wilson',
          imageURL: 'https://example.com/profile2.jpg',
          role: 'instructor'
        },
        timestamp: admin.firestore.Timestamp.now(),
        read: false,
        type: 'text',
        status: 'sent'
      },
      // Chat 2 messages
      {
        id: 'msg5',
        chatRoomId: 'chat2',
        content: 'Welcome everyone to the Beginner Snowboarding class chat!',
        senderId: userIds['instructor@example.com'],
        senderProfile: {
          displayName: 'Mike Wilson',
          imageURL: 'https://example.com/profile2.jpg',
          role: 'instructor'
        },
        timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 172800000)), // 2 days ago
        read: true,
        type: 'text',
        status: 'sent'
      },
      {
        id: 'msg6',
        chatRoomId: 'chat2',
        content: 'Don\'t forget to bring your gear!',
        senderId: userIds['instructor@example.com'],
        senderProfile: {
          displayName: 'Mike Wilson',
          imageURL: 'https://example.com/profile2.jpg',
          role: 'instructor'
        },
        timestamp: admin.firestore.Timestamp.now(),
        read: false,
        type: 'text',
        status: 'sent'
      }
    ];

    // Seed messages
    for (const message of messages) {
      await db.collection('chatRooms').doc(message.chatRoomId).collection('messages').doc(message.id).set(message);
      console.log(`Created message: ${message.id} in chat: ${message.chatRoomId}`);
    }

    // Create sample bookings
    const bookings = [
      {
        id: 'booking1',
        classId: 'class1',
        userId: userIds['student@example.com'],
        status: 'confirmed',
        createdAt: admin.firestore.Timestamp.now()
      },
      {
        id: 'booking2',
        classId: 'class2',
        userId: userIds['student@example.com'],
        status: 'waitlisted',
        createdAt: admin.firestore.Timestamp.now()
      }
    ];

    // Seed bookings
    console.log('Seeding bookings...');
    for (const booking of bookings) {
      await db.collection('bookings').doc(booking.id).set(booking);
      
      // Update class participant count for confirmed bookings
      if (booking.status === 'confirmed') {
        const classRef = db.collection('classes').doc(booking.classId);
        await classRef.update({
          currentParticipants: admin.firestore.FieldValue.increment(1)
        });
      }
      
      console.log(`Created booking: ${booking.id} (${booking.status})`);
    }

    console.log('Seed data written successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding data:', error);
    process.exit(1);
  }
}

seedData(); 