**Build Plan: Recurring Memory App (iOS Native with SwiftUI)**

**Overview**  
Build a high-quality native iOS app for recurring flashcard-based memory review, with both free and premium features. Prioritize clean code, modern Apple patterns, and a thoughtful, smooth user experience. Use the details below for architecture, features, and flows.

---

**Core Architecture (Requirements)**  
- Use SwiftUI for all UI (iOS 16+ compatible).  
- MVVM architecture; prefer Combine for reactive data flow.  
- Store all user data in Core Data; enable CloudKit sync for premium users.  
- Create an API abstraction layer to integrate with an external LangGraph API (for AI deck features).  
- Testing suite must include unit, integration (Core Data/API), and UI tests (XCTest).

---

**Data Models (Define as Swift structs/classes, Core Data entities):**  
- Deck: name, isSuperset, combinedDeckIds, isPremium  
- Flashcard: question, answer, deckId, metadata  
- ReviewSession: cardId, difficulty, interval, nextReview  
- User: premiumStatus, preferences, algorithmChoice

---

**Feature Breakdown**  
**Free (MUST in v1)**  
- Manual flashcard CRUD (create/read/update/delete).  
- Deck management (create decks, edit, delete).  
- Spaced repetition review with one algorithm (SM-2 only).  
- Daily review session (timeboxed to ~5 minutes per day).  
- Progress tracking (simple stats/history).  
- Allow user to create "superset" decks (combining others).

**Premium (Implement behind paywall, not required in v1):**  
- Decks and reviews sync via CloudKit.  
- Offline storage (persist all user content locally).  
- AI-powered deck generation (LangGraph API).  
- Advanced spaced repetition choices (e.g., SM-18, Fibonacci, custom options).  
- Export/backup decks and progress.  
- Advanced analytics, streaks, and bulk import.

---

**API Integration (abstract with protocol):**  
```swift
protocol FlashcardAPIService {
    func generateDeck(topic: String) async throws -> [Flashcard]
    func enhanceCard(card: Flashcard) async throws -> Flashcard
}
```
- Implement LangGraphAPIService to handle external API calls.

---

**User Flows (MUST be frictionless in v1):**  
1. Onboard new user, set up their first manual deck.  
2. Add/edit/remove flashcards.  
3. Daily: review cards in <5 minutes (spaced repetition algorithm).  
4. Show simple progress/habit tracker (e.g., streaks, completed reviews).  
5. Premium: sync, advanced AI, and additional settings as above.

---

**Testing Strategy**  
- Unit tests for all business and spaced repetition logic.  
- Integration tests: Core Data CRUD, CloudKit sync, API.  
- UI tests: onboarding, card review, deck management.  
- Test with large decks for performance.

---

**Monetization (not blocking for v1 launch):**  
- Basic freemium structure.  
- In-app subscription for AI, sync, analytics, etc.

---

**Technical Must-Haves**  
- iOS 16+  
- Core Data (with NSPersistentCloudKitContainer)  
- CloudKit for premium sync  
- Push notifications for review/habit reminders  
- Async/await where possible  
- Store all data locally for offline access

---

**Success Criteria**  
- User can create a deck and review their cards within 2 minutes.  
- Daily review is smooth, intuitive, and free of crashes or UI jank.  
- Deck and review data is saved offline and (for premium) synced.  
- Superset decks are easy to combine/manage.

---

**Next Steps for Cursor:**  
- Scaffold a SwiftUI+iOS16+ app with Core Data, MVVM structure, and a placeholder LangGraphAPIService.  
- Implement data models and UI for decks, flashcards, and review sessions per the above.  
- Cover at least the Free Features fully, with paywalls/stubs for premium.  
- Add unit/integration/UI test targets.  
- Build out key user flows as above.

---

**If you need to prioritize, always:**  
- Optimize for a delightful, frictionless daily review and deck management experience.  
