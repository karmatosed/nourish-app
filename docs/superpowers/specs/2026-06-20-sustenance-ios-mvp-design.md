# Sustenance iOS MVP — Foundation Design

Date: 2026-06-20

## Goal

Build a native iPhone app that answers one question well: **What can I safely make today, with the energy I have, from what I already have?**

## Architecture

- **SwiftUI** for UI, **SwiftData** for local persistence
- **Value-type snapshots** (`RecipeSnapshot`, `PantrySnapshot`, `SafetyProfileSnapshot`) feed a pure Swift **`SuggestionEngine`** so ranking logic is testable without SwiftUI/SwiftData
- **First launch** seeds demo data through `DataSeeder` — no onboarding wall

## Data models

| Model | Role |
|-------|------|
| `SafetyProfile` | Allergies (exclude), intolerances (caution), sensory avoids (caution/deprioritize), default energy |
| `PantryItem` | Name, location, category |
| `Recipe` | Ingredients, steps, time, energy required, safe/comfort flags |
| `MealLogEntry` | Optional "mark as made" history |
| `SuggestionScore` | Computed ranking result with classified ingredients |

## Suggestion engine rules

1. Exclude recipes containing allergy matches
2. Prioritize safe/comfort meals on low energy days
3. Reward pantry ingredient matches; penalize missing items
4. Intolerances → caution + score penalty (not hard exclusion)
5. Sensory avoids → caution + score penalty
6. Match energy level; penalize mismatches
7. Prefer shorter recipes on low-energy days
8. Return top 3 for Today; separate safe-meals fallback list

## Ingredient matching

Normalized token matching between pantry items and recipe ingredients. Negated phrases (`lactose-free`, `gluten-free`, `no onion`) prevent false positives against intolerance/allergy terms.

## MVP screen order (after foundation)

1. Today (energy selector + top 3 suggestions)
2. Recipe detail (grouped ingredients + steps)
3. Safe Meals fallback
4. Pantry editing
5. Recipe editing
6. Settings / safety profile

## Exclusions (MVP)

No accounts, cloud sync, AI, OCR, barcode scanning, shopping lists, calendar, subscriptions, or push notifications.

## Visual direction

Calm, warm, native utility — clear safety colors, large tap targets, supportive copy, VoiceOver-friendly labels. No streak pressure or wellness marketing tone.
