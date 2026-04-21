const admin = require('firebase-admin');
const logger = require('../core/utils/logger');

if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY
          ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
          : undefined,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
    });
  } catch (err) {
    if (logger && logger.warn) {
      logger.warn('Firebase admin initialization failed: ' + err.message);
    } else {
      console.warn('Firebase admin initialization failed: ' + err.message);
    }
  }
}

let auth;
try {
  auth = admin.auth();
} catch (err) {
  // If app is not initialized, admin.auth() will format an error
  auth = {
    verifyIdToken: async () => { throw new Error('Firebase not initialized'); }
  };
}

module.exports = { admin, auth };
