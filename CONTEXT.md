# Tajirika — Complete Project Brain Dump
## Master Context Document (paste this into any new chat)

---

## 1. WHO & WHAT

**Project:** Final-year Software Engineering project (ICS Project II)
**App Name:** Tajirika (Swahili for "to become wealthy/prosperous")
**Tagline:** "Spend smarter. Grow wealthier."
**Developer:** Solo student developer
**Submission Deadline:** Late October 2026 (~7-8 weeks from Sep 17 2026)
**Methodology:** Agile-Scrum (app development) + CRISP-DM (ML lifecycle)

---

## 2. THE PROBLEM BEING SOLVED

Consumers in Kenya manage daily commerce via M-Pesa (mobile money). This creates three problems:

```
1. Invisibility     → transactions happen instantly, financial pain is delayed
2. Fragmentation    → money scattered across M-Pesa, bank, cash simultaneously
3. Normalisation    → small frequent spends feel insignificant individually
```

Existing apps use rigid rule-based Regex that breaks when telecom syntax changes, and function purely as reactive historical logs with zero forward-looking capability. This leads to unchecked lifestyle creep.

**Core insight:** M-Pesa SMS is the most honest financial record most Kenyans have. It captures informal economy transactions no bank statement ever would.

---

## 3. THE SOLUTION

A distributed edge-cloud architecture that:
- Parses M-Pesa SMS on-device (privacy-first)
- Categorizes transactions using AI
- Forecasts financial runway in real time
- Detects lifestyle creep automatically
- Gives users one number: **how many days their money lasts**

---

## 4. FULL TECH STACK

### 📱 Mobile Frontend
| Component | Technology |
|---|---|
| Framework | Flutter & Dart |
| Rendering | Impeller Engine |
| State Management | Riverpod |
| Navigation | go_router |
| Charts | fl_chart |
| HTTP Client | Dio |
| SMS Parsing | On-device Regex |
| Local Storage | shared_preferences |
| JSON | json_annotation + json_serializable |

### ⚙️ Backend API
| Component | Technology |
|---|---|
| Framework | FastAPI (Python) |
| Architecture | REST |
| ORM | SQLAlchemy |
| Migrations | Alembic |
| Database | PostgreSQL |
| Config | python-dotenv |
| Validation | Pydantic |

### 🤖 ML Training
| Component | Technology |
|---|---|
| Environment | Google Colab (free tier — sufficient) |
| Known merchant categorization | Scikit-learn (Random Forest / XGBoost) |
| Unknown merchant categorization | FastText embeddings (PyTorch is stretch goal) |
| Forecasting | Prophet (primary) |
| Anomaly detection | Scikit-learn Isolation Forest |
| Pattern clustering | K-Means (behavioural archetypes) |
| Model export | joblib (.pkl), torch.save (.pt) |
| Model storage | Google Drive |

### 🚀 ML Serving
| Component | Technology |
|---|---|
| Method | Load .pkl models into FastAPI on startup |
| Hosting | Render / Railway (no GPU needed for inference) |

### 🛠️ Dev Tools
| Component | Technology |
|---|---|
| Version Control | Git + GitHub |
| API Testing | Postman |
| IDE | VS Code |
| OS | Windows |
| Python version | 3.9.13 |

---

## 5. SYSTEM ARCHITECTURE

```
M-Pesa SMS arrives on phone
         ↓
Flutter reads SMS (on-device, private)
         ↓
Regex parser extracts structured fields
         ↓
JSON payload → FastAPI backend (via Dio)
         ↓
PostgreSQL stores transaction records
         ↓
ML models process data:
  ├── Random Forest → category label
  ├── Prophet → 30-day forecast + runway
  └── Isolation Forest → anomaly flag
         ↓
Insights returned to Flutter UI
         ↓
User sees dashboard, runway, alerts
```

**Training flow (separate):**
```
Google Colab (train) → .pkl file → Google Drive → FastAPI loads on startup
```

---

## 6. ML PIPELINE DETAIL

### Model 1 — Expense Categorization
- **Known merchants:** TF-IDF + Random Forest (scikit-learn)
- **Unknown merchants:** FastText pre-trained embeddings (fine-tuned)
- **Merchant memory:** Phone numbers + till numbers stored as user-specific lookup table
- **User labeling:** If AI unsure, user labels manually → AI learns

### Model 2 — Forecasting (Prophet primary)
- Trained on user's historical transaction time series
- Outputs 30-day projected spend
- Calculates runway (days until balance hits zero)
- Handles seasonal spikes (December, end of month)
- LSTM/GRU is a **stretch goal only** — too data-hungry for sparse personal data

### Model 3 — Anomaly Detection (Isolation Forest)
- Runs in background continuously
- Flags sudden uncharacteristic expansions in discretionary spend
- Compares current trajectory vs personal baseline
- Outputs human-readable explanation of what was flagged

### Model 4 — Pattern Clustering (K-Means)
- Groups behavioural archetypes from transaction history
- Temporal patterns (Friday evening spikes, month-end dry spells)
- Merchant relationship patterns (recurring recipients = family/rent)

### Spend Categories (custom, not generic)
```
Necessity spending    → rent, utilities, groceries, transport
Convenience spending  → quick mart, impulse airtime, delivery
Social spending       → sending to family/friends, events
Aspirational spending → salon, clothing, subscriptions
Invisible spending    → transaction fees, micro top-ups
```

---

## 7. DATABASE SCHEMA (planned)

**Tables:**
```
users
  ├── id, created_at, pin_hash

transactions
  ├── id, user_id, mpesa_ref, amount, merchant_name
  ├── merchant_phone, category, transaction_type
  ├── timestamp, balance_after, transaction_cost
  └── raw_sms, confidence_score

categories
  ├── id, name, type (necessity/convenience/social/aspirational/invisible)
  └── icon, color

merchants (user-specific memory)
  ├── id, user_id, identifier (phone/till)
  ├── label, category, frequency, avg_amount
  └── last_seen

anomalies
  ├── id, user_id, detected_at, category
  ├── description, severity
  └── acknowledged

forecasts
  ├── id, user_id, generated_at
  ├── runway_days, projected_monthly_spend
  └── forecast_data (JSON)
```

---

## 8. ALL APP SCREENS (12 total)

### Auth Flow
```
1. Splash Screen       → logo animation, routes based on state
2. Onboarding Screen   → 3 slides, SMS permission request
3. PIN Setup Screen    → 4-digit PIN creation + confirm
4. PIN Entry Screen    → unlock screen for returning users
```

### Main App (Bottom Nav — 5 tabs)
```
5. Dashboard/Home      → runway card, spend chart, categories, anomaly alerts
6. Transactions        → full history, search, filter, label unknowns, sync
7. Categories          → donut chart, category breakdown, drill-down
8. Forecast            → runway, projections, what-if sliders
9. Settings            → SMS sync toggle, PIN change, clear data
```

### Detail Screens
```
10. Transaction Detail  → full merchant info, category, confidence score
11. Category Detail     → drill-in view, trend chart, all transactions
12. Anomaly Detail      → what was flagged, why, comparison, dismiss button
```

### Navigation Flow
```
Splash → Onboarding (first launch) → PIN Setup → Dashboard
Splash → PIN Entry (returning) → Dashboard
Dashboard ↔ Transactions ↔ Categories ↔ Forecast ↔ Settings
Any main screen → Detail screens
```

---

## 9. KEY FEATURES

### The Runway Number (highest priority)
```
"Your money lasts 11 days"
```
Single most important metric. Always visible on dashboard. Updates with every transaction. Converts abstract money into concrete time — proven to change spending behaviour.

### What-If Sliders (Forecast screen)
```
"What if I reduce Food spend by 20%?"
→ Runway extends from 11 → 15 days
→ You save Ksh 840 this month
```
Interactive. Updates live as user drags.

### Merchant Memory
```
0712XXXXXX → appears 4x/month → labelled "Mum" → Family Support
Same till number every Tuesday → weekly market run
Paybill 247247 → KCB loan repayment
```
User-specific lookup table. Grows smarter with every transaction.

### Invisible Spend Detection
```
"You spent Ksh 340 in M-Pesa transaction fees this month.
 That's 2.4% of your total spend."
```

### Proactive Notifications
```
Instant: "Ksh 1,200 at Naivas → Groceries. Food total: Ksh 4,200"
Weekly: "Your week in review — spent Ksh 6,400. Runway: 11 days"
Warning: "⚠️ M-Pesa hits zero in 3 days. Rent due in 5."
```

---

## 10. PROJECT FOLDER STRUCTURE

```
tajirika/                          ← GitHub repo root
├── app/                           ← Flutter project
│   └── lib/
│       ├── main.dart
│       ├── app.dart
│       ├── router/
│       │   └── app_router.dart
│       ├── core/
│       │   ├── constants/
│       │   │   ├── app_colors.dart
│       │   │   └── app_text_styles.dart
│       │   └── services/
│       │       └── storage_service.dart
│       ├── features/
│       │   ├── auth/
│       │   │   ├── screens/
│       │   │   │   ├── splash_screen.dart
│       │   │   │   ├── onboarding_screen.dart
│       │   │   │   ├── pin_setup_screen.dart
│       │   │   │   └── pin_entry_screen.dart
│       │   │   └── providers/
│       │   │       └── auth_provider.dart
│       │   ├── dashboard/screens/dashboard_screen.dart
│       │   ├── transactions/screens/transactions_screen.dart
│       │   ├── categories/screens/categories_screen.dart
│       │   ├── forecast/screens/forecast_screen.dart
│       │   └── settings/screens/settings_screen.dart
│       └── shared/
│           └── widgets/
│               └── pin_keypad.dart
├── backend/                       ← FastAPI project
│   ├── venv/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── database.py
│   │   ├── models.py
│   │   ├── schemas.py
│   │   └── routers/
│   │       ├── __init__.py
│       │   └── transactions.py
│   ├── requirements.txt
│   └── .env
├── notebooks/                     ← Google Colab notebooks
├── .gitignore
└── README.md
```

---

## 11. GOOGLE DRIVE STRUCTURE (Colab models)

```
Hesabu/
├── models/
│   ├── categorizer/     ← Random Forest .pkl
│   ├── forecast/        ← Prophet .pkl
│   └── anomaly/         ← Isolation Forest .pkl
├── notebooks/
└── data/
    └── sample_transactions/
```

---

## 12. GITHUB PROJECT SETUP

**7 Milestones:**
```
M1: Project Setup & Infrastructure    → Sep 14 ✅ (in progress)
M2: Flutter Frontend                  → Sep 21
M3: FastAPI Backend & Database        → Sep 28
M4: Frontend ↔ Backend Integration   → Oct 5
M5: ML Pipeline (Colab)              → Oct 13
M6: Model Integration & E2E Testing  → Oct 20
M7: Polish & Submission Prep         → Oct 27
```

**Labels:** feature, ml, bug, chore, frontend, backend, database, blocked

**Kanban columns:** Backlog → This Sprint → In Progress → Review → Done

**51 issues total** across all 7 milestones (full list defined in earlier session)

---

## 13. CURRENT PROGRESS (as of Sep 17 2026)

### ✅ Done
- GitHub repo created (named `tajirika`)
- Project folder structure: `app/`, `backend/`, `notebooks/`
- Flutter project initialized with all dependencies
- FastAPI project structure created
- PostgreSQL installed locally
- `hesabu_db` → renamed to `tajirika_db`
- FastAPI health check running at `localhost:8000`
- Google Drive folder structure created
- Postman collection started

### ✅ Auth Shell — Built
- `app_colors.dart` — dark theme, Tajirika green (#1DB954)
- `app_text_styles.dart` — typography constants
- `storage_service.dart` — SharedPreferences wrapper (PIN, onboarding)
- `auth_provider.dart` — Riverpod StateNotifier (AuthState enum)
- `app_router.dart` — go_router with ShellRoute + bottom nav
- `splash_screen.dart` — fade + scale animation, smart routing
- `pin_setup_screen.dart` — 4-digit PIN creation with confirm step
- `pin_entry_screen.dart` — PIN unlock with attempt tracking
- `pin_keypad.dart` — shared widget (public class, not private)
- `main.dart` + `app.dart` — ProviderScope, MaterialApp.router, dark theme

### ⚠️ Known Fix Applied
- `_PinKeypad` renamed to `PinKeypad` (Dart private class visibility bug)

### 🔲 Not Started Yet
- Onboarding screen
- Dashboard screen (next priority)
- All other feature screens
- Backend routes beyond health check
- PostgreSQL schema + SQLAlchemy models
- All ML notebooks

---

## 14. DESIGN SYSTEM

```dart
// Brand
primary:       #1DB954  (Tajirika green)
primaryDark:   #158A3C
accent:        #00C9A7

// Backgrounds (dark theme)
background:    #0D0D0D  (near black)
surface:       #1A1A1A  (cards)
surfaceLight:  #2A2A2A  (elevated cards)

// Text
textPrimary:   #FFFFFF
textSecondary: #9E9E9E
textHint:      #616161

// Semantic
success:       #1DB954
warning:       #FFB300
error:         #EF5350

// PIN
pinFilled:     #1DB954
pinEmpty:      #2A2A2A
```

---

## 15. WHAT TO BUILD NEXT (in order)

```
Current session stopped at: Auth shell complete, debugging PinKeypad import

Next immediate task:
1. Onboarding screen (3 slides + SMS permission)
2. Dashboard screen (core screen — runway card, chart, categories)
3. Transactions screen
4. Categories screen
5. Forecast screen with what-if sliders
6. Detail screens
7. Settings screen
→ Then move to Milestone 3 (FastAPI backend routes + DB schema)
→ Then Milestone 4 (connect Flutter ↔ FastAPI)
→ Then Milestone 5 (ML notebooks in Colab)
→ Then Milestone 6 (plug models into FastAPI)
```

---

## 16. CRITICAL DECISIONS ALREADY MADE

| Decision | Choice | Reason |
|---|---|---|
| gRPC vs REST | REST | Simpler, sufficient, defensible |
| LSTM vs Prophet | Prophet primary, LSTM dropped | Prophet handles sparse data better |
| PyTorch NLP | Stretch goal only | FastText sufficient, timeline tight |
| Colab tier | Free tier | Dataset small enough, save to Drive |
| Claude Pro | Worth it for deadline | Rate limits disruptive on 8-week build |
| App name | Tajirika | Culturally grounded, strong meaning |
| Theme | Dark, Tajirika green | Consistent throughout |
| Auth method | Local PIN only | No account needed, privacy-first |
| Categories | Custom 5-type taxonomy | More behaviourally meaningful than generic |
| Core metric | Runway number | Highest behaviour change impact |

---

## 17. SCOPE BOUNDARIES (what's NOT in v1)

```
❌ Bank account connection
❌ Manual budget setting
❌ Excel/CSV export
❌ Social/sharing features
❌ Multi-user
❌ LSTM/GRU models
❌ Full PyTorch NLP pipeline
❌ iOS support (Android only, v1)
❌ Cloud GPU (not needed for inference)
```

---

## 18. HOW TO RESUME IN A NEW CHAT

Paste this entire document and say:

> "This is my Tajirika project context. I'm a final-year software engineering student building an AI-driven M-Pesa spending optimization app. We left off at [WHERE YOU ARE]. I need help with [WHAT YOU NEED NEXT]. Act as my expert software architect, ML engineer and technical thought partner."

---

This document captures everything. Save it somewhere safe — Google Docs, Notion, or a `CONTEXT.md` file in your repo root.