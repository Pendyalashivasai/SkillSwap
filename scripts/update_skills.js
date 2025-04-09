const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('../service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateSkills() {
  try {
    // Read skills from JSON file
    const jsonContent = fs.readFileSync(
      path.join(__dirname, '../assets/data/predefined_skills.json'), 
      'utf8'
    );
    const jsonData = JSON.parse(jsonContent);
    const skillsData = jsonData.skills;

    // Get existing skills
    const existingSkills = await db.collection('skills').get();
    const existingSkillNames = new Set(
      existingSkills.docs.map(doc => doc.data().name)
    );

    // Create a batch
    const batch = db.batch();

    // Add only new skills
    let newSkillsCount = 0;
    for (const skillData of skillsData) {
      if (!existingSkillNames.has(skillData.name)) {
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
        newSkillsCount++;
        console.log(`Preparing to add new skill: ${skillData.name}`);
      }
    }

    // Update existing skills
    for (const doc of existingSkills.docs) {
      const existingData = doc.data();
      const updatedData = skillsData.find(s => s.name === existingData.name);
      if (updatedData && (
        updatedData.category !== existingData.category ||
        updatedData.description !== existingData.description
      )) {
        batch.update(doc.ref, {
          category: updatedData.category,
          description: updatedData.description
        });
        console.log(`Updating existing skill: ${updatedData.name}`);
      }
    }

    if (newSkillsCount > 0) {
      // Commit the batch
      await batch.commit();
      console.log(`Successfully added ${newSkillsCount} new skills!`);
    } else {
      console.log('No new skills to add.');
    }

  } catch (error) {
    console.error('Error updating skills:', error);
  } finally {
    process.exit();
  }
}

updateSkills();