# Cognition Curator

A beautiful, modern iOS flashcard app built with SwiftUI and Core Data, featuring spaced repetition learning and AI-powered deck generation.

## Features

### Free Features (v1)
- ✅ **Manual Flashcard CRUD**: Create, read, update, and delete flashcards
- ✅ **Deck Management**: Create, edit, and delete decks
- ✅ **Spaced Repetition**: SM-2 algorithm for optimal learning intervals
- ✅ **Daily Review Sessions**: Timeboxed ~5 minute daily reviews
- ✅ **Progress Tracking**: Simple stats and learning history
- ✅ **Superset Decks**: Combine multiple decks into one

### Premium Features (Future)
- 🔒 **CloudKit Sync**: Sync decks and reviews across devices
- 🔒 **AI Deck Generation**: LangGraph API integration
- 🔒 **Advanced Algorithms**: SM-18, Fibonacci, custom options
- 🔒 **Export/Backup**: Export decks and progress data
- 🔒 **Advanced Analytics**: Detailed insights and trends

## Technical Architecture

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local data persistence with CloudKit support
- **MVVM**: Clean architecture pattern
- **Combine**: Reactive data flow
- **Async/Await**: Modern concurrency

### Data Models
- **Deck**: name, isSuperset, combinedDeckIds, isPremium
- **Flashcard**: question, answer, deckId, metadata
- **ReviewSession**: cardId, difficulty, interval, nextReview
- **User**: premiumStatus, preferences, algorithmChoice

### Key Components

#### Views
- `HomeView`: Dashboard with stats and quick actions
- `DecksView`: Deck management with search and filters
- `ReviewView`: Spaced repetition review interface
- `ProgressView`: Learning analytics and trends
- `CreateDeckView`: Deck creation with AI generation
- `AddCardView`: Flashcard creation interface

#### Services
- `SpacedRepetitionService`: SM-2 algorithm implementation
- `FlashcardAPIService`: LangGraph API integration
- `PersistenceController`: Core Data management

## Getting Started

### Prerequisites
- Xcode 16.3+
- iOS 16.0+
- Swift 5.0+

### Installation
1. Clone the repository
2. Open `CognitionCurator.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run the project

### Project Structure
```
CognitionCurator/
├── CognitionCuratorApp.swift          # App entry point
├── ContentView.swift                  # Main tab view
├── PersistenceController.swift        # Core Data setup
├── Views/                             # UI components
│   ├── HomeView.swift
│   ├── DecksView.swift
│   ├── ReviewView.swift
│   ├── ProgressView.swift
│   ├── CreateDeckView.swift
│   ├── AddCardView.swift
│   ├── EditDeckView.swift
│   ├── DeckDetailView.swift
│   └── DeckRowView.swift
├── Services/                          # Business logic
│   ├── SpacedRepetitionService.swift
│   └── FlashcardAPIService.swift
├── Assets.xcassets/                   # App assets
└── CognitionCurator.xcdatamodeld/     # Core Data model
```

## User Flows

### 1. Onboarding
- New user creates their first deck
- Guided through adding initial flashcards
- Introduced to spaced repetition concept

### 2. Daily Review
- User opens app and sees cards due for review
- 5-minute timeboxed review session
- Tap to reveal answers, rate difficulty
- SM-2 algorithm calculates next review date

### 3. Deck Management
- Create new decks manually or with AI
- Add/edit/remove flashcards
- Organize with superset decks
- Search and filter functionality

### 4. Progress Tracking
- View learning statistics
- Track streaks and accuracy
- Monitor study time and trends

## Spaced Repetition Algorithm

The app implements the SM-2 (SuperMemo 2) algorithm:

- **Again (0)**: Reset interval to 1 day
- **Hard (1)**: Multiply interval by 1.2
- **Good (2)**: Multiply interval by ease factor (default 2.5)
- **Easy (3)**: Multiply interval by ease factor × 1.3

## API Integration

The app includes a protocol-based API service for future LangGraph integration:

```swift
protocol FlashcardAPIService {
    func generateDeck(topic: String) async throws -> [Flashcard]
    func enhanceCard(card: Flashcard) async throws -> Flashcard
}
```

## Design Principles

### UI/UX
- **Clean & Modern**: Minimalist design with thoughtful spacing
- **Smooth Animations**: Tasteful transitions and micro-interactions
- **Accessibility**: VoiceOver support and dynamic type
- **Dark Mode**: Full system appearance support

### Code Quality
- **MVVM Architecture**: Separation of concerns
- **Protocol-Oriented**: Testable and extensible
- **Error Handling**: Graceful error states
- **Documentation**: Comprehensive code comments

## Testing Strategy

### Unit Tests
- Business logic (spaced repetition algorithm)
- Data model validation
- Service layer functionality

### Integration Tests
- Core Data operations
- CloudKit sync (premium)
- API integration

### UI Tests
- Onboarding flow
- Card review process
- Deck management

## Performance Considerations

- **Lazy Loading**: Cards loaded on demand
- **Background Processing**: Core Data operations off main thread
- **Memory Management**: Proper cleanup of large datasets
- **Battery Optimization**: Efficient background sync

## Future Enhancements

### Short Term
- [ ] Push notifications for review reminders
- [ ] Offline mode improvements
- [ ] Export functionality
- [ ] Bulk import/export

### Long Term
- [ ] Advanced spaced repetition algorithms
- [ ] Social features (shared decks)
- [ ] Gamification elements
- [ ] Machine learning insights

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue in the GitHub repository or contact the development team.

---

Built with ❤️ using SwiftUI and Core Data 