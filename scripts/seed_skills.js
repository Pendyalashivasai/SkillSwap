const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('../service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function seedSkills() {
  try {
    // Check if skills already exist
    const existingSkills = await db.collection('skills').limit(1).get();
    if (!existingSkills.empty) {
      console.log('Skills already exist in the database');
      return;
    }

    // Read and parse JSON file
    const jsonContent = fs.readFileSync(
      path.join(__dirname, '../assets/data/predefined_skills.json'), 
      'utf8'
    );
    const jsonData = JSON.parse(jsonContent);
    
    // Ensure we have an array of skills
    const skillsData = Array.isArray(jsonData) ? jsonData : jsonData.skills;

    if (!Array.isArray(skillsData)) {
      throw new Error('Invalid JSON structure. Expected an array of skills.');
    }

    // Create a batch
    const batch = db.batch();

    // Add each skill to the batch
    skillsData.forEach(skillData => {
      const docRef = db.collection('skills').doc();
      batch.set(docRef, {
        id: docRef.id,
        name: skillData.name,
        category: skillData.category,
        description: skillData.description || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isSystemSkill: true,
        averageRating: 0.0,
        usageCount: 0
      });
      console.log(`Preparing to add skill: ${skillData.name}`);
    });

    // Commit the batch
    await batch.commit();
    console.log(`Successfully seeded ${skillsData.length} skills!`);
  } catch (error) {
    console.error('Error seeding skills:', error);
    console.error('JSON content:', fs.readFileSync(
      path.join(__dirname, '../assets/data/skills.json'), 
      'utf8'
    ));
  } finally {
    // Exit the process
    process.exit();
  }
}

seedSkills();