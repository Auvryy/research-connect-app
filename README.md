# 📱 Inquira (Research Connect)

A survey-based social platform built with **Flutter**.
Users can create, share, and take surveys — making research more engaging and accessible.

---

## 🚀 Features

* 🏠 **Home Feed** — browse surveys, filter by tags
* 👤 **Profile Page** — view your own created surveys
* ➕ **Add Survey** — form for creating surveys (WIP)
* ⚙️ **Settings** — account preferences, future dark mode

---

## 🏗 Tech Stack

* **Frontend:** Flutter, Dart
* **State:** StatefulWidgets (future → Provider/Bloc)
* **Backend (Planned):** Firebase / Supabase
* **Design:** Material + custom theming

---

## 📂 Structure

```
lib/
 ├─ models/         # Survey & Question models
 ├─ screens/        # Home, Profile, AddSurvey, Settings
 ├─ widgets/        # Reusable UI components (SurveyCard, Chips, etc.)
 └─ constants/      # Theme colors & app constants
```

---

## ▶️ Getting Started

```bash
git clone https://github.com/Auvryy/research-connect-app.git
cd research-connect-app
flutter pub get
flutter run
```

---

## 📌 Roadmap

* Survey detail & "Take Survey" flow
* Results & analytics for creators
* Firebase integration for persistence
* Authentication (accounts & avatars)
* Dark / Light mode

---
