# TarotMystica

An iOS tarot card reading app with on-device AI interpretation, powered by MLX.

## Features

- 78-card Rider-Waite tarot deck with hand-painted watercolor art
- 17 spread layouts (Celtic Cross, Three Card, Career, Relationship, etc.)
- On-device AI readings via MLX (Qwen 2.5 3B) — no server required
- Follow-up chat for deeper exploration
- Share readings as poster images or animated videos
- Daily card widget (WidgetKit)
- Multi-language support (English, Chinese, Spanish, French)
- Reading journal with SwiftData persistence

## Tech Stack

- **UI**: SwiftUI, iOS 17+
- **AI**: MLX Swift (on-device LLM inference)
- **Data**: SwiftData, JSON resource bundles
- **Video**: AVFoundation + ImageRenderer pipeline
- **Widget**: WidgetKit
- **Analytics**: Firebase (optional)

## Project Structure

```
TarotMystica/
├── Models/          # Data models (TarotCard, AppState, ReadingJournal)
├── Views/           # SwiftUI views (Hero, Question, CardDeck, Result)
├── LLM/             # AI service layer (MLX, API fallback, prompts)
├── Video/           # Video generation (composer, storyboard, scenes)
├── Data/            # Card/spread data loaders
├── Theme/           # Theming and haptics
├── Resources/       # Card images, JSON data, i18n strings
├── i18n/            # Localization manager
└── Analytics/       # Event tracking
```

## Requirements

- Xcode 16+
- iOS 17.0+
- ~2GB free storage (for MLX model download on first launch)

## Build

```bash
open TarotMystica.xcodeproj
# Select TarotMystica scheme → iPhone target → Run
```

## License

MIT License. See [LICENSE](LICENSE) for details.
