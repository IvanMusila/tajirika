# Tajirika

> **"Spend smarter. Grow wealthier."**

Tajirika (*Swahili: to become wealthy/prosperous*) is an AI-powered M-Pesa spending tracker for Android. It parses your M-Pesa SMS on-device, categorizes transactions using machine learning, and tells you the one number that matters: **how many days your money lasts**.

---

## The Problem

Most Kenyans manage money through M-Pesa, but have no clear picture of where it goes. Existing apps use brittle Regex rules and act as passive logs — no forecasting, no pattern detection, no actionable insight.

Tajirika fixes this by turning M-Pesa SMS into a real-time financial intelligence feed.

---

## Features

- **Runway number** — "Your money lasts 11 days" (updates with every transaction)
- **AI categorization** — transactions sorted into 5 Kenyan spending types
- **30-day forecast** — Prophet-powered projection of your spending trajectory
- **What-if sliders** — "What if I cut food spend by 20%? → +4 days runway"
- **Anomaly alerts** — automatic lifestyle creep detection
- **Invisible spend** — tracks M-Pesa fees you never notice

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Riverpod, go_router, fl_chart) |
| Backend | FastAPI + PostgreSQL + SQLAlchemy |
| ML | Scikit-learn, Prophet, FastText |
| Training | Google Colab → .pkl → Google Drive |

---

## Getting Started

### Backend
```bash
cd backend
python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload
```

### Flutter
```bash
cd app
flutter pub get
flutter run
```

> SMS reading requires a physical Android device.

---

## Project Structure

```
tajirika/
├── app/          ← Flutter frontend
├── backend/      ← FastAPI + PostgreSQL
├── notebooks/    ← Google Colab ML training
└── README.md
```

---

## Roadmap

| Milestone | Focus | Target |
|---|---|---|
| M1 | Setup & Infrastructure | Sep 14 |
| M2 | Flutter Frontend | Sep 21 |
| M3 | Backend & Database | Sep 28 |
| M4 | Frontend ↔ Backend | Oct 5 |
| M5 | ML Pipeline | Oct 13 |
| M6 | Model Integration | Oct 20 |
| M7 | Polish & Submission | Oct 27 |

---

*Final-year Software Engineering project — Nairobi, 2026* 🇰🇪****
