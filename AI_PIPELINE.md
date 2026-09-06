# Project Sift — Gemini Multimodal AI Pipeline

This document details the artificial intelligence architecture powering Project Sift: prompt design, canonical taxonomies, JSON repair engines, Human-in-the-Loop (HITL) routing, and failure resilience.

---

## 🧠 System Architecture

```text
[Compressed Image Bytes (1024px, Q60)]
                 │
                 ▼
     [Gemini Multimodal Prompt]
                 │
                 ▼
 [google_generative_ai GenerativeModel]
                 │
                 ▼
       [Raw Model Response]
                 │
                 ▼
       [AiResponseParser]
  ┌──────────────┴──────────────┐
  │ 1. Strip ```json code fences│
  │ 2. Find outermost { ... }   │
  │ 3. Repair trailing commas   │
  │ 4. Validate required schema │
  └──────────────┬──────────────┘
                 │
                 ▼
       [CategoryClassifier]
  ┌──────────────┴──────────────┐
  │ 1. Match 15 canonical names │
  │ 2. Apply synonym heuristics │
  │ 3. Fallback: "Other" + HITL │
  └──────────────┬──────────────┘
                 │
                 ▼
        [AnalysisResult]
        (Ready for Firestore)
```

---

## 🏷️ Canonical Taxonomy (15 Broad Categories)

Screenshots span arbitrary apps and contexts. Sift standardizes all classifications into **15 mutually exclusive canonical categories**:

| Category | Description & Examples |
| :--- | :--- |
| **Finance** | Bank statements, UPI receipts, crypto balances, invoices, expense tracking |
| **Shopping** | Product listings, Amazon cart, price comparisons, tracking numbers, promo codes |
| **Work** | Slack threads, Jira tickets, email correspondence, spreadsheets, presentations |
| **Communication**| WhatsApp/iMessage chats, DM snippets, social comments, text conversations |
| **Travel** | Flight tickets, boarding passes, hotel reservations, Google Maps routes |
| **Food** | Restaurant menus, recipes, meal delivery orders (DoorDash/UberEats/Zomato) |
| **Entertainment**| Movie tickets, Spotify playlists, Netflix recommendations, gaming achievements |
| **Education** | Lecture slides, homework problems, textbook diagrams, educational articles |
| **Technology** | Code snippets, terminal errors, system settings, developer documentation |
| **Health** | Lab test results, fitness tracker summaries, workout routines, medicine prescriptions |
| **Documents** | ID cards, passports, contracts, PDF previews, government forms |
| **Social** | Instagram reels/posts, Twitter/X threads, LinkedIn posts, memes |
| **Reference** | Wi-Fi passwords, address notes, serial numbers, book highlights |
| **Aesthetic** | Interior design ideas, fashion moodboards, wallpapers, artistic photography |
| **Other** | Catch-all for ambiguous, corrupted, or unclassifiable captures |

### Fuzzy Keyword Matching
When the AI outputs non-standard synonyms (e.g., `"Money"`, `"Gym"`, `"Coding"`), `CategoryClassifier` maps them into canonical categories before persistence:
- `money`, `crypto`, `bill` ➔ **Finance**
- `e-commerce`, `store`, `cart` ➔ **Shopping**
- `programming`, `software`, `bug` ➔ **Technology**
- `fitness`, `medical`, `workout` ➔ **Health**
- `chat`, `message`, `sms` ➔ **Communication**
- `moodboard`, `style`, `inspiration` ➔ **Aesthetic**

---

## 📜 Gemini Multimodal Prompt Specification

The vision model receives compressed JPEG bytes alongside the system prompt:

```text
You are an expert mobile screenshot intelligence analyzer for Project Sift.
Analyze the provided screenshot image with high precision and return a valid JSON object matching this exact schema:

{
  "title": "Concise, descriptive title (3-7 words) summarizing what this screenshot depicts",
  "primary_category": "Exactly one of: Finance, Shopping, Work, Communication, Travel, Food, Entertainment, Education, Technology, Health, Documents, Social, Reference, Aesthetic, Other",
  "tags": ["3 to 8 lowercase micro-tags for fast searching, e.g. receipt, flight, react, burger"],
  "extracted_text": "Accurate verbatim transcription of visible text, headings, numbers, and key information",
  "needs_human_context": true or false
}

Classification & Review Guidelines:
- Set 'needs_human_context' to true if the screenshot is:
  1. Ambiguous or subjective (e.g. fashion outfit, aesthetic wallpaper, personal photo).
  2. Missing context (e.g. random cropped text without clear app origin).
  3. Classified as 'Other'.
- Set 'needs_human_context' to false for structured, unambiguous items like receipts, boarding passes, error stack traces, and order confirmations.
- Always output raw JSON only. Do not wrap in commentary.
```

---

## 🛡️ Resilient JSON Parsing & Fault Recovery

AI outputs from LLMs occasionally suffer from formatting defects (markdown backticks, unescaped quotes, trailing commas, or truncated output). The `AiResponseParser` implements a 4-tier self-healing pipeline:

1. **Markdown Fence Stripping**:
   ```dart
   cleaned = rawResponse.replaceAll(RegExp(r'^```json\s*', multiLine: true), '');
   cleaned = cleaned.replaceAll(RegExp(r'^```\s*', multiLine: true), '');
   ```
2. **Substring Boundary Isolation**: Extracts content between the first `{` and the last `}` to discard any preceding or trailing text.
3. **Trailing Comma Repair**:
   ```dart
   cleaned = cleaned.replaceAll(RegExp(r',\s*([\]}])'), r'$1');
   ```
4. **Fallback Safety Net**: If JSON parsing fails completely, `AiResponseParser` generates a safe, non-throwing default object:
   - `title`: `"Screenshot (AI Processing)"`
   - `primary_category`: `"Other"`
   - `needs_human_context`: `true` (automatically queued for user review)
   - `tags`: `["unclassified"]`

---

## 🚦 Human-in-the-Loop (HITL) Fast Triage

Ambiguous screenshots are never misfiled invisibly. Sift's routing logic:
- **`needs_human_context == false`**: Displayed directly in the main Screenshot Library under its category.
- **`needs_human_context == true`**: Flagged with `review_status = "pending"` and routed to the **Human Review Queue**.
- In the Review Queue:
  - **Swipe Right**: Approves AI recommendation (`review_status = "approved"`).
  - **Change Category / Edit Tags**: Updates Firestore (`review_status = "corrected"`).
  - **Swipe Left**: Skips review temporarily (`review_status = "skipped"`).
