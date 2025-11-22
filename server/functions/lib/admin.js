import { getApps, initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
export function db() {
    if (!getApps().length) {
        initializeApp({ credential: applicationDefault() });
    }
    return getFirestore();
}
//# sourceMappingURL=admin.js.map