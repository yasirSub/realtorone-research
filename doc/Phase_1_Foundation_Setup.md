# 🚀 PHASE 1 — FOUNDATION & ONBOARDING

> ### ✅ STATUS: **~90% COMPLETE**
> Most of Phase 1 is built. Flutter app, Laravel backend, auth, splash, onboarding, and dashboard shell are all working.

**Timeline:** 3-4 Weeks
**Priority:** 🔴 Critical — Nothing works without this

---

## 📌 What We Build in This Phase

1. Project scaffolding (Flutter + Laravel)
2. Database schema & migrations
3. User authentication (Login / Register)
4. Splash Screen
5. Onboarding Flow (3 screens)
6. Basic Home Dashboard shell

---

## 1.1 — Project Setup

### Flutter App Setup
- [ ] Initialize Flutter project with latest stable SDK (3.24+)
- [ ] Configure folder structure:
  ```
  lib/
  ├── core/          # Theme, constants, utils
  ├── data/          # Models, repositories, API services
  ├── domain/        # Business logic / use cases
  ├── presentation/  # Screens, widgets, controllers
  └── main.dart
  ```
- [ ] Install core packages:
  - `get` (State management)
  - `dio` (HTTP client)
  - `shared_preferences` (Local storage)
  - `sqflite` (Offline cache)
  - `flutter_screenutil` (Responsive design)
  - `google_fonts` (Typography)
  - `flutter_animate` / `lottie` (Animations)
  - `cached_network_image` (Image caching)
- [ ] Set up dark-mode-first theme system
- [ ] Configure gradient color palette (teal to red education rings)
- [ ] Set up environment configs (dev, staging, prod)

### Laravel Backend Setup
- [ ] Initialize Laravel 11 project
- [ ] Install core packages:
  - `laravel/sanctum` (API auth)
  - `spatie/laravel-permission` (Roles)
  - `spatie/laravel-activitylog` (Tracking)
- [ ] Configure database connection (PostgreSQL / MySQL)
- [ ] Set up Redis for caching & sessions
- [ ] Configure CORS for Flutter app
- [ ] Set up API route structure

---

## 1.2 — Database Schema (Core Tables — Phase 1)

### Users Table
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    password VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    
    -- Onboarding Data
    area_of_focus ENUM('off_plan', 'secondary', 'luxury', 'commercial'),
    income_goal_monthly DECIMAL(12,2) DEFAULT 0,
    baseline_calls_per_day INT DEFAULT 0,
    baseline_monthly_commission DECIMAL(12,2) DEFAULT 0,
    baseline_deals_last_month INT DEFAULT 0,
    
    -- Membership
    membership_tier ENUM('consultant', 'rainmaker', 'titan_gold') DEFAULT 'consultant',
    dirham_points INT DEFAULT 0,
    
    -- Streak
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    last_activity_date DATE,
    
    -- Scores (cached daily)
    today_momentum_score INT DEFAULT 0,
    today_identity_score INT DEFAULT 0,
    today_revenue_action_score INT DEFAULT 0,
    today_results_score INT DEFAULT 0,
    
    -- Meta
    onboarding_completed BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Daily Scores Table
```sql
CREATE TABLE daily_scores (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    date DATE NOT NULL,
    identity_score INT DEFAULT 0,          -- Max 40
    revenue_action_score INT DEFAULT 0,     -- Max 45
    results_score INT DEFAULT 0,            -- Max 15
    total_momentum_score INT DEFAULT 0,     -- Max 100
    identity_activities_count INT DEFAULT 0,
    revenue_activities_count INT DEFAULT 0,
    streak_maintained BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_user_date (user_id, date),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Activity Logs Table
```sql
CREATE TABLE activity_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    date DATE NOT NULL,
    activity_type ENUM('identity', 'revenue_action', 'result'),
    activity_name VARCHAR(255) NOT NULL,
    points_earned INT DEFAULT 0,
    quantity INT DEFAULT 1, -- For things like "calls done: 25"
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## 1.3 — Authentication System

### API Endpoints
```
POST   /api/auth/register       → Register new user
POST   /api/auth/login          → Login (returns Sanctum token)
POST   /api/auth/logout         → Logout (revoke token)
GET    /api/auth/me             → Get current user profile
POST   /api/auth/forgot-password → Forgot password
POST   /api/auth/reset-password  → Reset password
```

### What to Implement
- [ ] Laravel Sanctum token-based auth
- [ ] Email + password registration
- [ ] Google Sign-In (optional for Phase 1)
- [ ] Token storage in Flutter `shared_preferences`
- [ ] Auto-login on app restart if token exists
- [ ] Token refresh logic

---

## 1.4 — Splash Screen

### Design
- RealtorOne logo (centered, animated fade-in)
- Tagline: **"Track the Work. Control the Income."**
- Premium dark background with subtle gradient
- Auto-navigate after 2 seconds:
  - If token exists → Home Dashboard
  - If no token → Login/Register screen

### UX Details
- Logo scale animation (0.8 → 1.0) with fade
- Tagline appears after 0.5s delay
- Haptic feedback on load (subtle)

---

## 1.5 — Onboarding Flow (3 Screens — New Users Only)

### Screen 1: Identity Setup
**Header:** "Let's Set Up Your Identity"

**Inputs:**
- Name (pre-filled from registration)
- Area of Focus (radio/chip selector):
  - 🏗️ Off-plan
  - 🏠 Secondary
  - 💎 Luxury
  - 🏢 Commercial
- Income Goal This Month (AED) — slider or input

**Footer Message:**
> *"We'll help you build the daily actions that hit this number."*

### Screen 2: Baseline
**Header:** "Your Starting Point"

**Inputs:**
- How many calls per day? (number input)
- Average monthly commission? (AED input)
- Deals closed last month? (number input)

**Footer Message:**
> *"This creates your personal baseline. No judgment — only progress from here."*

### Screen 3: Activate Momentum
**Display:**
- Premium animation (Lottie rocket/fire)
- Text: **"Momentum is built daily. Complete minimum actions to unlock your full score."**
- Large CTA button: **"Start Today"**

**On tap → Set `onboarding_completed = true` → Navigate to Home Dashboard**

### API Endpoint
```
PUT    /api/onboarding/complete  → Save onboarding data
```

---

## 1.6 — Home Dashboard Shell (Basic)

In Phase 1, we build the **layout shell** — full interactivity comes in Phase 2.

### Layout
```
┌─────────────────────────────────────┐
│         MOMENTUM SCORE: 0/100       │
│        [Large Circular Ring]        │
│                                     │
│  Subconscious: 0/40  │  Execution: 0/45  │
│          Results: 0/15              │
│                                     │
│  🔥 Streak: 0 days                  │
│  💰 Month Income: AED 0             │
│  🎯 Goal: AED [from onboarding]     │
│                                     │
├─────────────────────────────────────┤
│  [Tasks] [Learning] [AI] [Board]    │
│       Bottom Navigation Bar         │
└─────────────────────────────────────┘
```

### Color System
| Score Range | Color | Feeling |
|------------|-------|---------|
| 0 – 40 | 🔴 Red | Low momentum |
| 41 – 70 | 🟠 Orange | Building |
| 71 – 100 | 🟢 Green | Full momentum |

### What to Implement
- [ ] Circular progress ring widget (using `fl_chart` or `syncfusion_flutter_gauges`)
- [ ] Score breakdown section
- [ ] Streak display
- [ ] Monthly income display
- [ ] Goal display
- [ ] Bottom navigation bar (5 tabs - placeholder screens for now)
- [ ] Pull-to-refresh
- [ ] Score color transitions

---

## 1.7 — Phase 1 Deliverables Checklist

| # | Deliverable | Status |
|---|------------|--------|
| 1 | Flutter project initialized & structured | ✅ Done |
| 2 | Laravel project initialized with Sanctum | ✅ Done (deployed on Render) |
| 3 | Database schema (users, daily_scores, activity_logs) | ✅ Done (15 migrations) |
| 4 | Registration & Login flow (email + password) | ✅ Done |
| 5 | Splash screen with auto-navigation | ✅ Done (16KB polished) |
| 6 | 3-screen onboarding flow | ✅ Done (onboarding + profile setup) |
| 7 | Home Dashboard shell with score ring | ✅ Done (momentum hub widget) |
| 8 | Bottom navigation with 5 tabs (placeholder) | ✅ Done (main_navigation.dart) |
| 9 | Dark mode theme system | ✅ Done |
| 10 | API error handling & loading states | ✅ Done |

---

## 1.8 — Things Needed Before Starting

| Item | Required? | Notes |
|------|-----------|-------|
| Firebase account | ✅ Yes | For FCM (push notifications setup later) |
| Domain name | ✅ Yes | e.g., api.realtorone.com |
| Server / hosting | ✅ Yes | DigitalOcean / AWS for Laravel |
| SSL certificate | ✅ Yes | Let's Encrypt (free) |
| Design mockups (Figma) | 🟡 Optional | Can build with described specs |
| Lottie animation files | 🟡 Optional | For splash/onboarding |
| RealtorOne logo | ✅ Yes | SVG + PNG formats |

---

> **Previous:** [Phase 0 — System Overview](./Phase_0_System_Overview.md)
> **Next:** [Phase 2 — Tasks Tab & Scoring Engine](./Phase_2_Tasks_Scoring_Engine.md)
