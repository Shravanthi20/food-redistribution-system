const admin = require("firebase-admin");

// Use application default credentials (from firebase login)
admin.initializeApp({
  projectId: "food-redistribution-plat-86785"
});

const db = admin.firestore();

async function setUserAsAdmin(email) {
  try {
    // Find user by email
    const usersSnapshot = await db.collection("users")
      .where("email", "==", email)
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      console.log(`No user found with email: ${email}`);
      console.log("Checking by authentication...");
      
      // Try to find by auth
      const userRecord = await admin.auth().getUserByEmail(email);
      console.log(`Found auth user with UID: ${userRecord.uid}`);
      
      // Update or create user document
      await db.collection("users").doc(userRecord.uid).set({
        email: email,
        role: "admin",
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      
      console.log(`Successfully set ${email} as admin (created/updated user doc)`);
      return;
    }

    const userDoc = usersSnapshot.docs[0];
    console.log(`Found user: ${userDoc.id}`);
    
    // Update role to admin
    await userDoc.ref.update({
      role: "admin",
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Successfully set ${email} as admin!`);
  } catch (error) {
    console.error("Error setting admin:", error.message);
  } finally {
    process.exit();
  }
}

// Run with the specified email
setUserAsAdmin("sisirreddy11@gmail.com");
