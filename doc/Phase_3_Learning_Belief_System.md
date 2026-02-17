# 📚 PHASE 3 — LEARNING TAB & BELIEF SYSTEM

> ### 🟡 STATUS: **~25% COMPLETE**
> Basic Learning Tab UI with module cards and lessons page exists. Subscription tier gating is built on the backend. Missing: Affirmations Engine, Visualization Engine, 7-Day Belief Cycle, white-label video player, and belief areas tracking.

**Timeline:** 3-4 Weeks
**Priority:** 🟠 High — Core retention & identity loop
**Depends on:** Phase 1 & 2 complete

---

## 📌 What We Build in This Phase

1. Learning Tab with subscription-gated modules
2. Affirmations Engine
3. Visualization Engine
4. 7-Day Belief Cycle system
5. 5 Core Belief Areas tracking
6. Progress Feedback loop
7. Auto-integration with Tasks Tab (Identity Conditioning)

---

## 3.1 — Learning Tab Architecture (From Image 2)

```
LEARNING TAB
├── Subscription Tiers
│   ├── Consultant (FREE)
│   ├── Rainmaker (210 AED / Month)
│   └── Titan – GOLD (420 AED / Month)
│
├── Learning Modules
│   ├── Module 1: Invisible Influence — Belief + Identity [FREE]
│   ├── Module 2: Million Dirham Beliefs [Upgrade to Unlock]
│   ├── Module 3: Cold Calling System — Elite Execution [Upgrade to Unlock]
│   └── Coming Soon: Negotiation, Luxury Sales, AI Sales
│
├── Affirmations Engine
│   ├── Identity Declaration
│   └── Revenue Activation
│
├── Visualization Engine
│   ├── 500K / Month visualization
│   └── 1M / Month visualization
│
└── Progress Feedback
    ├── Completion %
    ├── Streaks
    └── Momentum
```

---

## 3.2 — Subscription Tiers

| Tier | Price | Access Level |
|------|-------|-------------|
| **Consultant** | FREE | Module 1 only, Basic affirmations |
| **Rainmaker** | 210 AED/Month | All modules, Full affirmation library, Basic visualization |
| **Titan – GOLD** | 420 AED/Month | All above + Revenue Efficiency Score, Priority AI coaching, Advanced analytics |

### What Each Tier Unlocks

#### Consultant (Free)
- [x] Module 1: Invisible Influence — Belief + Identity
- [x] Basic affirmations (5 tracks)
- [x] Basic guided resets
- [x] Tasks Tab (full access)
- [x] Results Tracker
- [ ] ~~Module 2, 3~~ (locked — upgrade prompt)
- [ ] ~~Full Visualization Engine~~ (locked)
- [ ] ~~Revenue Efficiency Score~~ (locked)

#### Rainmaker (210 AED/Month)
- [x] Everything in Consultant
- [x] Module 2: Million Dirham Beliefs
- [x] Module 3: Cold Calling System
- [x] Full Affirmation Library (20+ tracks)
- [x] Visualization Engine (500K/Month)
- [x] Priority leaderboard placement
- [ ] ~~Revenue Efficiency Score~~ (Titan only)
- [ ] ~~1M/Month visualization~~ (Titan only)

#### Titan – GOLD (420 AED/Month)
- [x] Everything in Rainmaker
- [x] Revenue Efficiency Score on Leaderboard
- [x] 1M/Month Visualization
- [x] Advanced Analytics & Reports
- [x] Priority AI Coaching
- [x] All future courses (auto-unlock)
- [x] Direct mentor access features

---

## 3.3 — Learning Modules

### Module 1: Invisible Influence — Belief + Identity (FREE)

**Purpose:** Foundation of the identity-first system. Teaches realtors that belief drives behavior drives revenue.

**Lessons:**
1. The Invisible Influence Model
2. How Your Beliefs Control Your Income
3. Identity Declaration Workshop
4. Daily Conditioning Protocol
5. Reprogramming Beliefs About Money
6. The Confidence-Action Flywheel

**Format:** White-label video courses (self-hosted, no YouTube branding)
**Duration:** ~2-3 hours total
**Completion Check:** 80% watch time + quiz

### Module 2: Million Dirham Beliefs (Upgrade to Unlock)

**Purpose:** Advanced belief work specifically around earning 1M+ AED/year

**Lessons:**
1. The Million Dirham Identity
2. Abundance vs Scarcity in Real Estate
3. Client-Attracting Energy
4. Negotiation Confidence Framework
5. Revenue Belief Audit
6. Building Unshakeable Authority

**Format:** White-label video courses
**Duration:** ~3-4 hours total
**Unlock:** Rainmaker or Titan tier

### Module 3: Cold Calling System — Elite Execution (Upgrade to Unlock)

**Purpose:** Practical execution system for cold calling mastery

**Lessons:**
1. Cold Calling Mindset Reset
2. The Opening Script Framework
3. Objection Handling Playbook
4. Tonality & Energy Control
5. Volume vs Quality — The Math
6. Building a Call System That Scales

**Format:** White-label video courses
**Duration:** ~3-4 hours total
**Unlock:** Rainmaker or Titan tier

### Coming Soon Modules
- 🤝 Negotiation Mastery
- 💎 Luxury Sales Framework
- 🤖 AI Sales — Using Tech for Real Estate

---

## 3.4 — Affirmations Engine

### How It Works

The Affirmations Engine produces **audio/visual content** that conditions the realtor's subconscious mind.

### Two Modes

#### 1. Identity Declaration
- Pre-written identity statements tailored to realtors
- User reads/listens daily
- Examples:
  - *"I am a trusted advisor in Dubai real estate."*
  - *"High-value clients are naturally drawn to my authority."*
  - *"I close deals with confidence and integrity."*
  - *"I am building generational wealth through real estate."*

#### 2. Revenue Activation
- Revenue-specific affirmations tied to the user's income goal
- Dynamically generated based on user's `income_goal_monthly`
- Examples:
  - *"I am on track to earn AED {goal} this month."*
  - *"Every call I make brings me closer to my goal."*
  - *"I am worthy of earning AED {goal} and beyond."*

### Implementation
- [ ] Audio player with RealtorOne branding (no external branding)
- [ ] Tracks stored on AWS S3 / Cloudflare Stream
- [ ] Background playback support (min 5 minutes for scoring)
- [ ] Completion auto-logs to Tasks Tab (+6-10 points based on activity)
- [ ] Track library expandable per subscription tier

---

## 3.5 — Visualization Engine

### How It Works

Guided visualization sessions where realtors mentally rehearse success scenarios.

### Two Visualization Tiers

#### 500K / Month Visualization (Rainmaker+)
- Guided audio session (5-10 minutes)
- Visualization of earning 500K AED/month
- Mental rehearsal of client meetings, closings, commission deposits

#### 1M / Month Visualization (Titan GOLD only)
- Advanced guided session (10-15 minutes)
- Visualization of million-dirham months
- Includes luxury clients, premium properties, leadership scenarios

### Implementation
- [ ] Custom Flutter audio player with timer
- [ ] Background audio support
- [ ] Completion tracking → auto-logs to Identity Conditioning (+10 points)
- [ ] Lock/unlock based on subscription tier
- [ ] "Continue from where you left" feature

---

## 3.6 — 7-Day Belief Cycle (From Master Diagram)

The system runs a **7-Day Belief Cycle** that, when completed:

```
7-Day Belief Cycle Completed
    → Daily Belief Activity Logged
    → Self-Recognition Moment: "Identity Reinforced — I've Improved"
```

### How It Works
1. Each day for 7 days, user completes at least ONE belief/identity activity
2. After 7 consecutive days, a **Self-Recognition Moment** is triggered
3. The moment includes:
   - 🎉 Celebration animation
   - Badge unlock (e.g., "Belief Builder" badge)
   - Message: **"Identity Reinforced — I've Improved"**
4. The cycle then resets for the next 7 days

### 5 Core Belief Areas

From the master diagram, the belief system tracks **5 core areas**:

| Belief Area | Description | Color |
|------------|-------------|-------|
| 💪 Confidence | Self-belief in abilities | Blue |
| 🔄 Consistency | Belief in daily discipline | Green |
| 💰 Abundance | Belief in unlimited earning potential | Gold |
| 👑 Authority | Belief in being a market authority | Purple |
| 🧘 Calm | Inner peace under pressure | Teal |

### Belief Area Tracking
- Each identity activity maps to one or more belief areas
- Progress wheel shows which areas are strongest/weakest
- AI coaching can recommend activities for weaker areas

---

## 3.7 — Progress Feedback Loop

The Learning Tab feeds back into the entire system:

```
Learning Activity Completed
    → Auto Log to Tasks Tab (Identity Conditioning)
    → Update Progress (Completion %, Streaks, Momentum)
    → Identity Reinforced
    → Confidence Spike
    → Action Readiness
    → Higher Quality Actions
    → Stronger Conversions
    → Revenue Growth
```

### Implementation
- [ ] When any learning activity is completed, it auto-logs as an Identity Conditioning activity
- [ ] Points are automatically added to the day's Identity Score
- [ ] Completion percentage shown per module
- [ ] Module streaks tracked (consecutive days of learning)

---

## 3.8 — Video Course Player

### Requirements
- [ ] Custom branded video player (no YouTube/Vimeo branding)
- [ ] Flutter packages: `video_player` + `chewie` (or `better_player`)
- [ ] Features:
  - Play/Pause
  - Seek bar
  - Speed control (0.5x, 1x, 1.5x, 2x)
  - Full-screen mode
  - Picture-in-Picture (optional)
  - Resume from last position
  - Completion tracking (80% = completed)
  - Download for offline (Titan tier only)
- [ ] Video storage: AWS S3 with CloudFront CDN
- [ ] Background bandwidth optimization

---

## 3.9 — Database Tables (Phase 3 Additions)

### Courses Table
```sql
CREATE TABLE courses (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    module_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    video_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    duration_seconds INT DEFAULT 0,
    order_index INT DEFAULT 0,
    min_tier ENUM('consultant', 'rainmaker', 'titan_gold') DEFAULT 'consultant',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Course Progress Table
```sql
CREATE TABLE course_progress (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    course_id BIGINT NOT NULL,
    watch_time_seconds INT DEFAULT 0,
    total_duration_seconds INT DEFAULT 0,
    progress_percent DECIMAL(5,2) DEFAULT 0,
    last_position_seconds INT DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_user_course (user_id, course_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);
```

### Belief Cycle Table
```sql
CREATE TABLE belief_cycles (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    cycle_start_date DATE NOT NULL,
    days_completed INT DEFAULT 0,
    cycle_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP NULL,
    belief_areas JSON, -- {"confidence": 3, "consistency": 2, "abundance": 1, ...}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Memberships Table
```sql
CREATE TABLE memberships (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    tier ENUM('consultant', 'rainmaker', 'titan_gold') DEFAULT 'consultant',
    start_date DATE NOT NULL,
    end_date DATE,
    status ENUM('active', 'expired', 'cancelled') DEFAULT 'active',
    payment_method VARCHAR(50),
    stripe_subscription_id VARCHAR(255),
    amount_aed DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## 3.10 — API Endpoints (Phase 3)

### Learning
```
GET    /api/learning/modules                → Get all modules (respects tier)
GET    /api/learning/modules/{id}/courses   → Get courses in a module
GET    /api/learning/courses/{id}           → Get course detail + video URL
POST   /api/learning/courses/{id}/progress  → Update watch progress
GET    /api/learning/progress               → Get overall learning progress
```

### Affirmations
```
GET    /api/affirmations/tracks             → Get affirmation track list
POST   /api/affirmations/complete           → Log affirmation session complete
```

### Belief Cycle
```
GET    /api/belief-cycle/current            → Get current 7-day cycle status
POST   /api/belief-cycle/log                → Log daily belief activity
GET    /api/belief-cycle/history            → Get past completed cycles
```

### Membership
```
GET    /api/membership/current              → Get current membership tier
POST   /api/membership/upgrade              → Initiate upgrade flow
POST   /api/membership/webhook              → Stripe/PayFort webhook
```

---

## 3.11 — Phase 3 Deliverables Checklist

| # | Deliverable | Status |
|---|------------|--------|
| 1 | Learning Tab UI with module cards | ✅ Done (learning_page.dart + lessons_page.dart) |
| 2 | Module 1 content loaded (video courses) | ❌ Missing — no actual video content |
| 3 | Subscription tier gating (lock/unlock modules) | ✅ Done (backend tier check on courses) |
| 4 | Custom branded video player | ❌ Missing |
| 5 | Watch progress tracking & resume | ❌ Missing |
| 6 | Affirmations Engine (audio player + tracks) | ❌ Missing |
| 7 | Visualization Engine (guided sessions) | ❌ Missing |
| 8 | 7-Day Belief Cycle with celebration | ❌ Missing (belief_rewiring_page exists but no cycle) |
| 9 | 5 Core Belief Areas tracking | ❌ Missing |
| 10 | Auto-integration: Learning → Tasks Tab scoring | ❌ Missing |
| 11 | Membership/upgrade flow (Stripe integration) | 🟡 Partial (subscription UI exists, no real gateway) |
| 12 | "Continue Watching" card on dashboard | ❌ Missing |

---

## 3.12 — Things Needed for This Phase

| Item | Required? | Notes |
|------|-----------|-------|
| Video content (Module 1) | ✅ Yes | Need actual recorded courses |
| Affirmation audio tracks | ✅ Yes | Pre-recorded audio files |
| Visualization audio scripts | ✅ Yes | Guided session recordings |
| AWS S3 bucket setup | ✅ Yes | For video/audio storage |
| CloudFront CDN | 🟡 Recommended | For faster video delivery |
| Stripe account + API keys | ✅ Yes | For subscription payments |
| PayFort merchant account | 🟡 Optional | UAE-specific gateway |

---

> **Previous:** [Phase 2 — Tasks Tab & Scoring Engine](./Phase_2_Tasks_Scoring_Engine.md)
> **Next:** [Phase 4 — Leaderboard & Gamification](./Phase_4_Leaderboard_Gamification.md)
