import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
} from 'firebase/auth';
import { auth, db } from '../config/firebaseConfig';
import { ref, set } from 'firebase/database';

export const authService = {
  // Register new user
  register: async (email, password) => {
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // Create user data in Realtime Database
      const newUserData = {
        email: email.toLowerCase(),
        role: 'user', // Default role
        createdAt: new Date().toISOString(),
      };

      // Save to Firebase Realtime Database
      await set(ref(db, `users/${user.uid}`), newUserData);

      return {
        success: true,
        data: user,
      };
    } catch (error) {
      return {
        success: false,
        message: error.message,
      };
    }
  },

  // Login user
  login: async (email, password) => {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      return {
        success: true,
        data: userCredential.user,
      };
    } catch (error) {
      return {
        success: false,
        message: error.message,
      };
    }
  },

  // Logout user
  logout: async () => {
    try {
      await signOut(auth);
    } catch (error) {
      console.error('Sign out error:', error);
    }
  },

  // Listen for auth state changes
  onAuthStateChanged: (callback) => {
    return onAuthStateChanged(auth, callback);
  },
};