# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Inneal is a native iOS/iPadOS LLM roleplay chatbot client built with SwiftUI and SwiftData that connects to the AI Horde service. The app allows users to create and import character cards, engage in multi-character chats, and manage conversations with AI characters.

## Development Setup

1. Clone the repository: `git clone https://github.com/amiantos/inneal.git`
2. Open `Inneal.xcodeproj` in Xcode 15.3 or higher
3. Build and run the project

No package manager dependencies - uses only built-in SwiftUI and SwiftData frameworks.

## Architecture

### Core Data Models (SwiftData)
- **Character**: Represents AI characters with personality, descriptions, and conversation history
- **Chat**: Container for conversations with one or more characters
- **ChatMessage**: Individual messages in conversations with support for alternates/swipes
- **ContentAlternate**: Alternative versions of messages (swipe feature)
- **UserSettings**: Global user preferences and default character
- **APIConfiguration**: Service configuration data (currently Horde-focused)

### Key Architecture Patterns
- **SwiftData with CloudKit**: Data persistence with automatic iCloud syncing across devices
- **ModelContainer**: Shared container pattern initialized in `InnealApp.swift:20-26`
- **MVVM**: Views use `@Query` and `@Environment(\.modelContext)` for data access
- **External API Layer**: Separated API implementations in `External APIs/` folder

### View Hierarchy
- `ContentView` → `ChatsView` (main entry point)
- Tabbed navigation between Chats, Characters, and Settings
- Modal presentations for chat creation, character editing, and settings

### Character System
Characters support Tavern Card v2 format with:
- Basic character data (name, description, personality, first message)
- Advanced features (system prompts, example messages, alternate greetings)
- PNG/JSON import/export capabilities
- Avatar image storage with `@Attribute(.externalStorage)`

### Chat System
- Multi-character conversations supported
- Message swipe/alternate generation via `ContentAlternate` model
- User persona support through `userCharacter` relationship
- Auto-mode for simplified AI Horde usage

## External Services

### AI Horde Integration
Primary service located in `External APIs/Horde API/`:
- `HordeAPI.swift`: Core API client with worker/model discovery
- `HordeModels.swift`: Response data structures
- `HordeDefaults.swift`: Default configuration values

### Supported Services Framework
While currently Horde-focused, the codebase supports multiple services via `Services` enum:
- AI Horde (primary)
- OpenAI, Anthropic, Google, Cohere, OpenRouter, KoboldAI (infrastructure exists)

## Key Files

- `InnealApp.swift`: App entry point with ModelContainer setup
- `SwiftDataModels.swift`: All core data models and relationships
- `Views/Chat/ChatView.swift`: Main conversation interface
- `Views/Chat/ViewModel.swift`: Chat logic and API integration
- `Utils/Logging.swift`: Centralized logging system
- `External APIs/Horde API/`: AI Horde service integration