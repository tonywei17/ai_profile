import { initializeApp, getApps, applicationDefault } from "firebase-admin/app";
import { getFirestore, Firestore } from "firebase-admin/firestore";

let _db: Firestore | null = null;

/**
 * Lazily initialize the Firebase Admin SDK and return a Firestore singleton.
 *
 * - On Cloud Run: applicationDefault() picks up the attached runtime service
 *   account automatically (no key file needed). That service account must
 *   have roles/datastore.user on the ai-id-photo-prod project.
 * - Locally: set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON
 *   file path, e.g. `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json`.
 */
export function db(): Firestore {
  if (_db) return _db;

  try {
    if (getApps().length === 0) {
      initializeApp({
        credential: applicationDefault(),
      });
    }
    _db = getFirestore();
    return _db;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(
      `[firestore] Failed to initialize Firebase Admin SDK. ` +
        `On Cloud Run this requires a service account with roles/datastore.user; ` +
        `locally set GOOGLE_APPLICATION_CREDENTIALS to a service-account key file. ` +
        `Original error: ${message}`
    );
  }
}
