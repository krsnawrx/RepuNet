# RepuNet Lite — Project Context

> **Source of truth:** `RepuNet_Lite_PRD_v2.md`
> **Stack:** Flutter (Dart) · Firebase Auth · Cloud Firestore

---

## Firestore Schema

### `users` collection

| Field        | Type      | Notes                        |
|------------- |---------- |------------------------------|
| userId       | string    | Document ID, matches Auth UID |
| name         | string    |                              |
| cgpa         | double    | 0.0 – 10.0                  |
| teacherScore | double    | 0.0 – 1.0 (normalized)      |
| reputation   | double    | Computed, hybrid score       |
| credibility  | double    | Derived, used as rater weight |
| createdAt    | timestamp |                              |

### `interactions` collection

| Field         | Type      | Notes              |
|-------------- |---------- |--------------------|
| interactionId | auto      | Document ID        |
| fromUser      | string    | Rater's userId     |
| toUser        | string    | Target's userId    |
| rating        | int       | 1 – 5              |
| timestamp     | timestamp |                    |

---

## Reputation Logic

### Step 1 — Weighted Peer Score

```
weightedRating = rating × raterCredibility
peerScore      = weightedAverage(all weightedRatings for target)
```

### Step 2 — Hybrid Formula

```
normalizedCGPA       = cgpa / 10
calculatedReputation = (0.5 × peerScore) + (0.3 × normalizedCGPA) + (0.2 × teacherScore)
```

### Step 3 — Smoothing (prevents review bombing)

```
newReputation = (oldReputation × 0.7) + (calculatedReputation × 0.3)
```

---

## Credibility Model

```
credibility = (0.6 × normalizedCGPA) + (0.4 × normalizedReputation)
credibility = min(credibility, MAX_LIMIT)   // influence cap
```

---

## Manipulation Protections

1. **One rating per pair** — a user can only rate another user once.
2. **Influence cap** — credibility is clamped to `MAX_LIMIT`.
3. **Smoothing** — 70/30 EMA prevents sudden score swings.
4. **Min-raters threshold** — full peer weight only applied after enough unique raters.
5. **CGPA baseline** — academic anchor makes peer-only manipulation insufficient.

---

## State Management — Riverpod

- **Provider**: `reputationProvider` (StateNotifierProvider)
- **Notifier**: `ReputationNotifier` → manages `ReputationState`
- **State**: `ReputationState` holds `peerScore`, `normalizedCGPA`, `teacherScore`, `reputation`, `credibility`, `isLoading`
- **Entry point**: `ProviderScope` wraps `RepuNetApp` in `main.dart`

---

## Theme

- **File**: `lib/theme/app_theme.dart`
- **Palette**: Deep Navy (`#0A1128`) + White, accent blue (`#3A86FF`)
- **Font**: Inter (via `google_fonts`)
- **Reputation tiers**: High ≥ 0.75 (green), Moderate ≥ 0.40 (amber), Low (red)

---

## Glassmorphic UI

- **`GlassmorphicCard`** (`lib/widgets/`): Reusable card with `BackdropFilter` (blur σ=14), semi-transparent white fill, luminous border
- **`AnimatedCounter`**: `TweenAnimationBuilder` that counts up the reputation score on load
- **Dashboard Sections**: Reputation score card → System Stability bar (70/30 smoothing) → Credibility stats → Rater list
---

## Navigation

- **`AppShell`**: 3-tab `BottomAppBar` with `CircularNotchedRectangle` + centre-docked FAB
- **Tabs**: Dashboard (0) / Search (1) / Profile (2) via `IndexedStack`
- **`extendBody: true`** — gradient bleeds under the bottom bar

## Interaction Layer — PRD §9

- **`RatingSheet`** (`lib/widgets/`): Glassmorphic `showModalBottomSheet` with student dropdown, 5-star selector, submit
- **`submitRating()`**: Records interaction → recalculates peerScore → hybrid formula → smoothing → credibility
- **Haptic Feedback**: `selectionClick` on star tap, `lightImpact` on successful submit

## Auth — PRD §10

- **`AuthService`** (`lib/providers/`): Mock auth with StreamController mirroring `FirebaseAuth.authStateChanges()`
- **`AuthGate`** (`main.dart`): Watches `authStateProvider` → LoginScreen or AppShell
- **Switch to Firebase**: Set `flutterfire configure`, swap AuthService internals

---

## Folder Structure

```
lib/
├── models/      # Data classes: User, Interaction
├── providers/   # Riverpod state providers
├── services/    # Firebase auth, Firestore CRUD, reputation engine
├── screens/     # Login, Home, Rate, Profile screens
├── theme/       # App theme and design tokens
├── widgets/     # Reusable UI components
└── utils/       # Constants (weights, limits), helpers
```

---

## Implementation Roadmap (from PRD §10)

1. Firebase setup (Auth + Firestore)
2. Create User and Interaction models
3. Implement rating submission logic
4. Implement reputation calculation function
5. Add smoothing
6. Add influence cap
7. UI display of reputation breakdown
