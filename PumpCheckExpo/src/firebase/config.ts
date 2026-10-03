import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyAoUsPES7HXcU-b_3YWAcOH6-UfmrWRugw",
  authDomain: "pumpcheck-b66a7.firebaseapp.com",
  projectId: "pumpcheck-b66a7",
  storageBucket: "pumpcheck-b66a7.firebasestorage.app",
  messagingSenderId: "880918542376",
  appId: "1:880918542376:ios:34c6711008e7dfc4bd5d1d"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
