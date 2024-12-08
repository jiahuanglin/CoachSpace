#!/bin/bash

# Exit on error
set -e

# Check if Firebase emulators are running
if ! curl -s http://localhost:4000 > /dev/null; then
    echo "Error: Firebase emulators are not running"
    echo "Please start the emulators with: firebase emulators:start"
    exit 1
fi

# Initialize test data using Firebase Admin SDK
node << EOF
const admin = require('firebase-admin');

// Initialize admin SDK with emulator
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
admin.initializeApp({
    projectId: 'demo-project'
});

const db = admin.firestore();

async function initializeTestData() {
    // Create test users
    const users = [
        {
            id: 'user1',
            email: 'instructor@test.com',
            displayName: 'Test Instructor',
            role: 'instructor'
        },
        {
            id: 'user2',
            email: 'student@test.com',
            displayName: 'Test Student',
            role: 'student'
        }
    ];

    // Create test chat rooms
    const chatRooms = [
        {
            id: 'chat1',
            participants: ['user1', 'user2'],
            type: 'direct',
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now()
        },
        {
            id: 'chat2',
            participants: ['user1', 'user2'],
            type: 'classGroup',
            classId: 'class1',
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now()
        }
    ];

    // Create test messages
    const messages = [
        {
            id: 'msg1',
            chatRoomId: 'chat1',
            senderId: 'user1',
            receiverId: 'user2',
            content: 'Hello! Welcome to the class.',
            type: 'text',
            status: 'delivered',
            timestamp: admin.firestore.Timestamp.now(),
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now()
        }
    ];

    // Batch write all data
    const batch = db.batch();

    // Add users
    for (const user of users) {
        const ref = db.collection('users').doc(user.id);
        batch.set(ref, user);
    }

    // Add chat rooms
    for (const room of chatRooms) {
        const ref = db.collection('chatRooms').doc(room.id);
        batch.set(ref, room);
    }

    // Add messages
    for (const message of messages) {
        const ref = db.collection('chatRooms')
            .doc(message.chatRoomId)
            .collection('messages')
            .doc(message.id);
        batch.set(ref, message);
    }

    // Commit the batch
    await batch.commit();
    console.log('Test data initialized successfully');
}

initializeTestData()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error('Error initializing test data:', error);
        process.exit(1);
    });
EOF

# Make the script executable
chmod +x scripts/init-test-data.sh 