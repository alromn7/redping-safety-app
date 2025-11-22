'use client'
import React from 'react'
import { getAuth, GoogleAuthProvider, signInWithPopup } from 'firebase/auth'
import { getClientDb } from '@/lib/firebase/client'

/**
 * Minimal Google sign-in button using Firebase Web Auth.
 * Requirements:
 * - Firebase project config set via NEXT_PUBLIC_FIREBASE_* env vars
 * - Firebase Auth > Sign-in method > Google enabled
 * - Authorized domains include your site domains
 * - firebase (npm) installed in the web project
 */
export default function SignInWithGoogleButton() {
  const onClick = async () => {
    try {
      // Ensure Firebase app is initialized (no-op if already)
      getClientDb()
      const auth = getAuth()
      const provider = new GoogleAuthProvider()
      // Optional: force account selection each time
      provider.setCustomParameters({ prompt: 'select_account' })
      const res = await signInWithPopup(auth, provider)
      console.log('✅ Signed in (web) as uid =', res.user?.uid)
    } catch (e: any) {
      // Common causes:
      // - Auth domain not authorized in Firebase
      // - Popup blocked by browser
      // - Missing NEXT_PUBLIC_FIREBASE_* env vars / wrong project
      console.error('❌ Google sign-in failed:', e?.message || e)
    }
  }
  return (
    <button
      type="button"
      onClick={onClick}
      style={{ padding: '8px 12px', border: '1px solid #444', borderRadius: 6 }}
    >
      Sign in with Google
    </button>
  )
}
