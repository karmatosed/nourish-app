# Sustenance

A calm daily meal companion for people managing chronic illness, neurodiversity, allergies, intolerances, low energy, and food decision fatigue.

**Bundle ID:** `com.draftandform.sustenance`

## MVP focus

> What can I safely make today, with the energy I have, from what I already have?

## Open in Xcode

1. Open `Sustenance/Sustenance.xcodeproj`
2. Select an iPhone simulator (e.g. iPhone 17)
3. Run the **Sustenance** scheme (**⌘R**)

The app appears on the home screen as **Sustenance**. First launch seeds local demo recipes and pantry data via SwiftData.

## Run tests

```bash
cd Sustenance
xcodebuild -scheme Sustenance -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test
```

## Tabs

| Tab | What it does |
|-----|----------------|
| **Today** | Energy selector + top 3 ranked suggestions |
| **Safe Meals** | Trusted safe/comfort fallback list |
| **Pantry** | Add, edit, remove items; filter by location; search |
| **Recipes** | Browse, search, filter, add/edit/delete recipes; import from Markdown |
| **List** | Shopping list — add missing ingredients from recipes or type items manually |
| **Calendar** | Meal log history with day picker |
| **Settings** | Allergies, intolerances, sensory avoids, diet preferences, default energy |

## Import recipes from Markdown

In **Recipes**, tap **Import** and choose a `.md` or plain-text file:

```markdown
# Soft Scrambled Eggs
Time: 10 min
Energy: low

## Ingredients
- eggs — 2
- salt

## Steps
1. Whisk eggs with salt.
2. Cook gently and serve.

## Notes
Gentle protein for low-energy days.
```

Supported metadata keys: `Time`, `Prep`, `Energy`, `Safe`, `Comfort`.

## Project layout

```
Sustenance/
├── Sustenance/
│   ├── App/              # App entry + SwiftData container
│   ├── Models/           # SwiftData models + snapshots
│   ├── Services/         # SuggestionEngine, filters
│   ├── Data/             # Seed data + first-launch seeder
│   ├── Views/            # SwiftUI screens
│   └── Theme/            # Mono palette tokens
└── SustenanceTests/         # XCTest coverage for ranking + safety
```

## Regenerate Xcode project

If you add new source files:

```bash
python3 scripts/generate_xcode_project.py
```

Signing is stored locally in `Sustenance/Signing.local.xcconfig` (copy from `Signing.local.xcconfig.example` and set your Team ID). Regenerating the project reads this file so Archive keeps working.

## TestFlight / App Store Connect

Suggested listing:

- **Name:** Sustenance
- **Subtitle:** Safe meals for your energy and pantry
- **Bundle ID:** `com.draftandform.sustenance`
