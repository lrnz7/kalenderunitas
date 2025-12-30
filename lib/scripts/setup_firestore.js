// Script untuk setup initial Firestore structure
const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setupDatabase() {
  // Create collections
  const collections = ['events', 'users', 'settings'];
  
  for (const collection of collections) {
    console.log(`Creating collection: ${collection}`);
  }

  // Add initial events
  const initialEvents = [
    {
      title: "Pra-LDO divisi PSDM",
      date: "2026-01-10",
      division: "PSDM",
      category: "Organisasi",
      description: "Pra-Latihan Dasar Organisasi untuk divisi PSDM",
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      title: "SI Belajar divisi P3M",
      date: "2026-01-13",
      division: "P3M",
      category: "Akademik",
      description: "Sesi belajar bersama divisi P3M",
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      title: "Rapat Divisi Unitas",
      date: "2026-01-20",
      division: "Unitas SI",
      category: "Organisasi",
      description: "Rapat rutin divisi Unitas",
      createdAt: new Date(),
      updatedAt: new Date()
    }
  ];

  for (const event of initialEvents) {
    await db.collection('events').add(event);
    console.log(`Added event: ${event.title}`);
  }

  console.log('✅ Database setup completed!');
}

setupDatabase().catch(console.error);