# Project Sift — Privacy & Data Security Policy

Screenshots frequently contain deeply sensitive personal data: financial statements, medical lab results, private conversations, boarding passes, addresses, and passwords. 

**Project Sift is engineered with Privacy-by-Design and Local-First principles.**

---

## 🛡️ Core Privacy Principles

1. **User Ownership**: You own 100% of your data. We do not sell, rent, monetize, or train shared public models on your personal screenshots.
2. **Local Preprocessing**: Heavy image analysis and deduplication happen locally on your device before network requests are dispatched.
3. **Cryptographic Deduplication**: Fast SHA-256 hashes generated from local thumbnails prevent redundant uploads.
4. **Strict Per-User Isolation**: All cloud assets (Firestore documents and Cloud Storage media) are partitioned under your personal Firebase Authentication UID (`users/{userId}/*`).
5. **No Persistent AI Storage**: Screenshot bytes transmitted to Google Gemini are evaluated ephemerally for categorization and OCR, in accordance with Google API developer terms.
6. **Automatic Deletion Sync**: Deleting a screenshot locally from your phone's photo library automatically removes the associated cloud image, thumbnail, and Firestore metadata on the next sync cycle.

---

## 🔒 Dataflow & Transmission Lifecycle

```text
[Device Gallery]
       │
       ▼
[Local SHA-256 Deduplication] ──(Duplicate)──► [Drop / Do Not Upload]
       │
   (New Item)
       ▼
[Local Compression: 1024px Max, Q60] ──► [Local Thumbnail: 250px]
       │
       ▼
[Firebase Cloud Storage: users/{userId}/screenshots/{id}/image.jpg]
       │
       ▼
[Google Gemini Multimodal API: Ephemeral Inference]
       │
       ▼
[Cloud Firestore: users/{userId}/screenshots/{id}]
```

---

## 🔐 Cloud Security Rules Enforcement

### Cloud Firestore Security
- No public collections exist.
- Access requires a verified Firebase Auth session token.
- `request.auth.uid == userId` is enforced on every document read, query, create, update, and delete.

### Firebase Storage Security
- Media is saved under `/users/{userId}/screenshots/{screenshotId}/*`.
- File sizes are strictly capped at 5MB.
- MIME types must match `image/*`.
- Only the authenticated owner can retrieve download URLs or delete files.

---

## 🧹 Device-to-Cloud Deletion Synchronization

Many cloud photo backups retain deleted photos indefinitely unless manually purged in multiple places. Sift solves this via **Deletion Reconciliation**:

1. The `DeletionReconciliationService` performs periodic differential scans between the device's photo library and the cloud database.
2. If a screenshot was removed or trashed on the physical device, Sift marks it as an orphaned cloud asset.
3. Sift deletes the primary image and thumbnail from Cloud Storage.
4. Sift deletes the document from Cloud Firestore.
5. Sift evicts the content hash from the local cache.

---

## 🚫 Zero Third-Party Trackers

Project Sift contains:
- ❌ No ad networks or advertising SDKs.
- ❌ No third-party behavioral analytics or session recording SDKs.
- ❌ No user fingerprinting across apps or devices.
