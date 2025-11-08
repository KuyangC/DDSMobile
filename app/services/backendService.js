import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword } from 'firebase/auth';
import { db } from '../config/firebaseConfig';
import { 
  ref, 
  push, 
  set, 
  query, 
  orderByChild, 
  equalTo, 
  get,
  update 
} from 'firebase/database';

const auth = getAuth();

// Helper function to get user by email from Firebase
export const getUserByEmail = async (email) => {
  try {
    const usersRef = ref(db, 'users');
    const userQuery = query(
      usersRef, 
      orderByChild('email'), 
      equalTo(email.toLowerCase())
    );
    
    const snapshot = await get(userQuery);
    
    if (snapshot.exists()) {
      const users = snapshot.val();
      const userId = Object.keys(users)[0];
      return { id: userId, ...users[userId] };
    }
    return null;
  } catch (error) {
    console.error('Error getting user by email:', error);
    throw error;
  }
};

// Register user
export const registerUser = async (userData) => {
  try {
    const { email, password, role, name } = userData;

    // Validation
    if (!email || !password || !role || !name) {
      return {
        success: false,
        message: 'All fields are required'
      };
    }

    // Create user with Firebase Auth
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    // Create user data in Realtime Database
    const newUserData = {
      email: email.toLowerCase(),
      role,
      name,
      isActive: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    // Save to Firebase Realtime Database
    const usersRef = ref(db, `users/${user.uid}`);
    await set(usersRef, newUserData);

    // Generate token
    const token = await user.getIdToken();

    return {
      success: true,
      data: {
        user: {
          id: user.uid,
          ...newUserData
        },
        token
      }
    };

  } catch (error) {
    console.error('Register error:', error);
    return {
      success: false,
      message: 'Server error during registration: ' + error.message
    };
  }
};

// Login user
export const loginUser = async (credentials) => {
  try {
    const { email, password } = credentials;

    // Validation
    if (!email || !password) {
      return {
        success: false,
        message: 'Email and password are required'
      };
    }

    // Sign in with Firebase Auth
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    // Get user data from Realtime Database
    const userProfile = await getUserProfile(user.uid);
    if (!userProfile.success) {
      return {
        success: false,
        message: 'User profile not found.'
      };
    }

    // Generate token
    const token = await user.getIdToken();

    return {
      success: true,
      data: {
        user: userProfile.data.user,
        token
      }
    };

  } catch (error) {
    console.error('Login error:', error);
    return {
      success: false,
      message: 'Server error during login: ' + error.message
    };
  }
};

// Get user profile
export const getUserProfile = async (userId) => {
  try {
    const userRef = ref(db, `users/${userId}`);
    const snapshot = await get(userRef);
    
    if (!snapshot.exists()) {
      return {
        success: false,
        message: 'User not found'
      };
    }

    const user = snapshot.val();
    // Remove password from response
    const userWithoutPassword = { ...user };
    delete userWithoutPassword.password;

    return {
      success: true,
      data: { 
        user: {
          id: userId,
          ...userWithoutPassword
        } 
      }
    };

  } catch (error) {
    console.error('Get profile error:', error);
    return {
      success: false,
      message: 'Server error: ' + error.message
    };
  }
};

// Update user profile
export const updateUserProfile = async (userId, updates) => {
  try {
    const userRef = ref(db, `users/${userId}`);
    
    // Get current user data
    const snapshot = await get(userRef);
    if (!snapshot.exists()) {
      return {
        success: false,
        message: 'User not found'
      };
    }

    // Update user data
    const updateData = {
      ...updates,
      updatedAt: new Date().toISOString()
    };

    await update(userRef, updateData);

    // Get updated user data
    const updatedSnapshot = await get(userRef);
    const updatedUser = updatedSnapshot.val();
    const userWithoutPassword = { ...updatedUser };
    delete userWithoutPassword.password;

    return {
      success: true,
      data: { 
        user: {
          id: userId,
          ...userWithoutPassword
        } 
      }
    };

  } catch (error) {
    console.error('Update profile error:', error);
    return {
      success: false,
      message: 'Server error: ' + error.message
    };
  }
};