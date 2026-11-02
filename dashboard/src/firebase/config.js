import { initializeApp, getApps, getApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

/**
 * Real Firebase Configuration for Şafak Sayar.
 * Extracted directly from project credentials (safak-sayar-4e1cd).
 */
const firebaseConfig = {
  apiKey: "AIzaSyAb8KkrNa-yAs6d9nude-iFE_gJQgW1Pb4",
  authDomain: "safak-sayar-4e1cd.firebaseapp.com",
  projectId: "safak-sayar-4e1cd",
  storageBucket: "safak-sayar-4e1cd.firebasestorage.app",
  messagingSenderId: "965631010355",
  appId: "1:965631010355:web:safaksayar-dashboard",
};

export const app = !getApps().length ? initializeApp(firebaseConfig) : getApp();
export const db = getFirestore(app);
