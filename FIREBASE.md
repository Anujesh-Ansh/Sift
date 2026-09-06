# Project Sift — Firebase Backend & Security Architecture

Project Sift leverages **Firebase Authentication**, **Cloud Firestore**, and **Firebase Cloud Storage** to deliver a secure, scalable, and isolated data foundation.

---

## 🔐 Security Principles & User Isolation

Every user's screenshots, thumbnails, and metadata are strictly isolated under user-scoped paths:
```text
Firestore:  /users/{userId}/screenshots/{screenshotId}
Storage:    /users/{userId}/screenshots/{screenshotId}/...
```

No user can read, create, modify, or delete another user's media or metadata.

---

## 🗄️ Cloud Firestore Data Model

### Collection Path
`users/{userId}/screenshots/{screenshotId}`

### Field Schema
| Field Name | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | Unique identifier (e.g. `sc_7f8a91b2c3d4`) |
| `title` | `String` | Descriptive, AI-generated title |
| `primary_category` | `String` | One of the 15 canonical categories |
| `tags` | `List<String>` | 3-8 micro-tags for deep search indexing |
| `extracted_text` | `String` | Full transcription of visible OCR text |
| `user_note` | `String?` | Optional user-provided context note |
| `needs_human_context`| `bool` | `true` if AI classification is ambiguous or requires user review |
| `review_status` | `String` | `pending`, `approved`, `corrected`, or `skipped` |
| `storage_path` | `String` | Relative path to compressed full image in Cloud Storage |
| `thumbnail_storage_path` | `String` | Relative path to 250px thumbnail in Cloud Storage |
| `source_asset_id` | `String` | Local device gallery asset identifier |
| `content_hash` | `String` | SHA-256 fingerprint for deduplication |
| `source_created_at` | `Timestamp` | Original capture timestamp from device metadata |
| `indexed_at` | `Timestamp` | When Sift ingested the screenshot |
| `updated_at` | `Timestamp` | Last modification timestamp |
| `image_width` | `int` | Compressed image width (px) |
| `image_height` | `int` | Compressed image height (px) |
| `thumbnail_width` | `int` | Thumbnail width (px) |
| `thumbnail_height`| `int` | Thumbnail height (px) |
| `file_size_bytes` | `int` | Size of compressed full image in bytes |
| `processing_status`| `String` | Pipeline state (e.g. `completed`, `indexed`, `failed_retryable`) |
| `model_version` | `String` | AI model used (e.g. `gemini-1.5-flash`) |
| `schema_version` | `int` | Version of the metadata schema (`1`) |

---

## 🛡️ Firestore Security Rules (`firestore.rules`)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User root matching
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Screenshot subcollection
      match /screenshots/{screenshotId} {
        allow read: if request.auth != null && request.auth.uid == userId;
        
        allow create: if request.auth != null 
          && request.auth.uid == userId
          && request.resource.data.schema_version == 1
          && request.resource.data.processing_status is string;
          
        allow update: if request.auth != null 
          && request.auth.uid == userId;
          
        allow delete: if request.auth != null 
          && request.auth.uid == userId;
      }
    }
  }
}
```

### Security Guarantees:
- **Authentication Required**: Anonymous or federated users must have an authenticated UID.
- **Strict Data Segregation**: `request.auth.uid == userId` ensures zero cross-tenant contamination.
- **Payload Validation**: Disallows creation if `schema_version != 1` or if `processing_status` is missing.

---

## 📦 Cloud Storage Architecture & Rules (`storage.rules`)

### Storage Paths
```text
users/{userId}/screenshots/{screenshotId}/image.jpg
users/{userId}/screenshots/{screenshotId}/thumbnail.jpg
```

### Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/screenshots/{screenshotId}/{fileName} {
      allow read: if request.auth != null && request.auth.uid == userId;
      
      allow write: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024 // 5MB max payload
        && request.resource.contentType.matches('image/.*');
        
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Storage Optimizations:
1. **No Original Camera Bloat**: High-resolution 8-15MB captures are downscaled on the device to max 1024px, saving >90% bandwidth and storage costs.
2. **Dedicated Fast Thumbnails**: Thumbnails are resized to ~250px (~15KB) for instantaneous grid rendering without downloading full images.
3. **MIME Type Enforcement**: Strict `image/*` validation blocks malicious binary uploads.
4. **Size Caps**: Maximum 5MB per upload prevents denial-of-wallet attacks.

---

## ⚡ Firestore Indexes (`firestore.indexes.json`)

Compound queries require composite indexes for optimal latency:

```json
{
  "indexes": [
    {
      "collectionGroup": "screenshots",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "primary_category", "order": "ASCENDING" },
        { "fieldPath": "source_created_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "screenshots",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "review_status", "order": "ASCENDING" },
        { "fieldPath": "source_created_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "screenshots",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "needs_human_context", "order": "ASCENDING" },
        { "fieldPath": "source_created_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "screenshots",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "content_hash", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## 🧹 Deletion Reconciliation Flow

To prevent "ghost" records when users delete photos from their device gallery:
1. `DeletionReconciliationService` scans active local asset IDs against indexed Firestore documents.
2. For any remote document whose `source_asset_id` no longer exists locally:
   - Deletes `users/{userId}/screenshots/{screenshotId}/image.jpg` from Cloud Storage.
   - Deletes `users/{userId}/screenshots/{screenshotId}/thumbnail.jpg` from Cloud Storage.
   - Deletes the Firestore document `users/{userId}/screenshots/{screenshotId}`.
   - Evicts the asset from the client `DeduplicationService` hash cache.
