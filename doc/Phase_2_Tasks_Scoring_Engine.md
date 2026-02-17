# ⚡ PHASE 2 — TASKS TAB & DAILY SCORING ENGINE

> ### 🟢 STATUS: **~95% COMPLETE**
> Tasks Tab, activity logging, scoring engine, streaks, Results Tracker (hot leads/deals/commission), Follow-up Discipline Guard, and monthly results graphs are all built. Remaining: UX polish (confetti animations, haptic feedback on streaks).

**Timeline:** 3-4 Weeks
**Priority:** 🔴 Critical — This is the HEART of the app
**Depends on:** Phase 1 complete

---

## 📌 What We Build in This Phase

1. Tasks Tab (Daily Performance Engine)
2. Identity Conditioning (Subconscious Activities)
3. Revenue Actions (Conscious Activities)
4. Results Tracker (Hot Leads, Deals, Commission)
5. Daily Score Calculation Engine
6. Streak System
7. Real-time Score Updates on Home Dashboard

---

## 2.1 — Tasks Tab Architecture

The Tasks Tab is the **Daily Performance Engine** — the core behavioral loop of the entire app.

```
TASKS TAB
├── Identity Conditioning Section
│   ├── Manual Identity Activities
│   │   ├── Journaling (+4)
│   │   └── Webinar (+12)
│   └── Verified Identity Activities
│       ├── Visualization (+10)
│       ├── Affirmations (+10)
│       ├── Inner Game Audio (+8)
│       └── Guided Reset (+6)
│
├── Revenue Actions Section
│   ├── Cold Calling (+8)
│   ├── Follow-ups (+8)
│   ├── Content Creation (+8)
│   ├── Client Meeting / Site Visit (+10)
│   ├── Deal Negotiation (+10)
│   └── CRM Update (+5)
│
└── Results Tracker Section
    ├── Hot Leads Added (+2 per lead, Cap 10)
    ├── Deals Closed (+5 per deal, Cap 15)
    └── Commission Earned (No Daily Points)
```

---

## 2.2 — Identity Conditioning (Subconscious — Max 40 Points)

### Minimum Requirement: 2 activities daily

### Manual Identity Activities

| Activity | Points | Type |
|----------|--------|------|
| 📝 Journaling | +4 | Manual (self-reported) |
| 📺 Webinar Attendance | +12 | Manual (self-reported) |

### Verified Identity Activities

| Activity | Points | Type |
|----------|--------|------|
| 🎯 Visualization | +10 | Verified (in-app timer/completion) |
| 🔁 Affirmations | +10 | Verified (in-app playback) |
| 🎧 Inner Game Audio | +8 | Verified (in-app playback) |
| 🧘 Guided Reset | +6 | Verified (in-app timer) |

### Total Identity Score: Capped at 40

### UX Rules
- When **2 activities are completed**, show green glow animation
- Display message: **"Identity locked in. Execution becomes easier."**
- Progress bar at top: `Identity: 16/40`
- Card glows green when completed
- Micro confetti animation on completion
- Haptic feedback on activity completion

### Minimum 2 Check Logic
```
IF identity_activities_count >= 2:
    identity_requirement_met = TRUE
    → Show: "✅ Identity Locked In"
ELSE:
    identity_requirement_met = FALSE
    → Show: "Complete {2 - count} more identity activities"
```

---

## 2.3 — Revenue Actions (Conscious — Max 45 Points)

### Minimum Requirement: 4 activities daily

### Revenue Action Options

| Activity | Points | Notes |
|----------|--------|-------|
| 📞 Cold Calling | +8 | Per session |
| 🤝 Follow-ups | +8 | Hot/warm follow-ups |
| 🎥 Content Creation | +8 | Recording videos/reels |
| 📲 Content Posting | +6 | IG/LinkedIn |
| 🏠 Client Meeting / Site Visit | +10 | Physical or Zoom |
| 📝 Deal Negotiation | +10 | Offers, SPAs |
| 🧾 CRM Update | +5 | Updating pipeline |

### Total Revenue Action Score: Capped at 45

### Minimum 4 Check Logic
```
IF revenue_activities_count >= 4:
    revenue_requirement_met = TRUE
    → Show: "✅ Execution mode activated. You're ahead of 80% of the market today."
ELSE:
    revenue_requirement_met = FALSE
    → Show: "Complete {4 - count} more revenue actions"
```

---

## 2.4 — Results Tracker (Max 15 Points)

This section is **NOT mandatory daily** but massively boosts motivation.

### Results Input

| Metric | Points | Cap |
|--------|--------|-----|
| 🔥 Hot Leads Added | +2 per lead | Cap at 10 points (5 leads max scoring) |
| 📝 Deals Closed | +5 per deal | Cap at 15 points |
| 💰 Commission Earned | No daily points | Logged for monthly tracking |

### Cap Results Score at 15

### Display Below Results
> **"You've generated AED X this month. Your habits are paying you."**

### Monthly Graph Section
- Total Commission (bar/line chart)
- Deals closed (count)
- Leads generated (count)
- Message: **"Your habits are compounding."**

---

## 2.5 — Daily Score Calculation Engine

### Core Algorithm

```python
# DAILY SCORE CALCULATION
def calculate_daily_score(user_id, date):
    
    # 1. Identity Score (Max 40)
    identity_activities = get_identity_activities(user_id, date)
    identity_score = sum(a.points for a in identity_activities)
    identity_score = min(identity_score, 40)  # Cap at 40
    identity_count = len(identity_activities)
    
    # 2. Revenue Action Score (Max 45)
    revenue_activities = get_revenue_activities(user_id, date)
    revenue_action_score = sum(a.points for a in revenue_activities)
    revenue_action_score = min(revenue_action_score, 45)  # Cap at 45
    revenue_count = len(revenue_activities)
    
    # 3. Results Score (Max 15)
    hot_leads = get_hot_leads_count(user_id, date)
    deals_closed = get_deals_closed_count(user_id, date)
    results_score = (hot_leads * 2) + (deals_closed * 5)
    results_score = min(results_score, 15)  # Cap at 15
    
    # 4. Total Momentum Score
    total_score = identity_score + revenue_action_score + results_score
    total_score = min(total_score, 100)  # Absolute cap
    
    # 5. Save to daily_scores table
    save_daily_score(
        user_id=user_id,
        date=date,
        identity_score=identity_score,
        revenue_action_score=revenue_action_score,
        results_score=results_score,
        total_momentum_score=total_score,
        identity_activities_count=identity_count,
        revenue_activities_count=revenue_count
    )
    
    return total_score
```

### Revenue Momentum Engine (From Master Diagram)

```
REVENUE MOMENTUM ENGINE
├── Identity Score (cap at 40)
│   └── Identity Actions 40
├── Revenue Actions (cap at 45)
│   └── Revenue Actions 45
├── Results (cap at 15)
│   └── Results 15
└── TOTAL = 100
```

---

## 2.6 — Streak System

### Streak Check Logic (From Master Diagram)

```python
# STREAK CHECK
def check_streak(user_id, date):
    identity_count = get_identity_activities_count(user_id, date)
    revenue_count = get_revenue_activities_count(user_id, date)
    
    if identity_count >= 2 AND revenue_count >= 4:
        # Streak maintained!
        user.current_streak += 1
        if user.current_streak > user.longest_streak:
            user.longest_streak = user.current_streak
        return "streak_maintained"
    else:
        # Streak broken — gentle reset
        user.current_streak = 0
        return "streak_reset"
```

### Streak UX

**On streak maintained:**
> 🔥 **"Streak: {N} days! Consistency compounds."**

**On streak broken (gentle messaging — NEVER punishing):**
> **"Streaks reset. Identity doesn't. Let's restart today."**

### Streak Types Tracked
1. 🔥 **Daily Streak** — Overall (identity + revenue minimums met)
2. 🧠 **Subconscious Streak** — Identity activities ≥ 2 consecutive days
3. 📞 **Execution Streak** — Revenue activities ≥ 4 consecutive days

---

## 2.7 — API Endpoints (Phase 2)

### Activity Logging
```
POST   /api/activities/log              → Log an activity
GET    /api/activities/today            → Get today's logged activities
DELETE /api/activities/{id}             → Remove a logged activity
```

### Scores
```
GET    /api/scores/today               → Get today's score breakdown
GET    /api/scores/weekly              → Get this week's scores
GET    /api/scores/monthly             → Get monthly score history
```

### Results
```
POST   /api/results/hot-lead           → Log a hot lead
POST   /api/results/deal-closed        → Log a deal closed
POST   /api/results/commission         → Log commission earned
GET    /api/results/monthly-summary    → Get monthly results summary
```

### Streaks
```
GET    /api/streaks/current            → Get current streak info
GET    /api/streaks/history            → Get streak history
```

---

## 2.8 — Database Tables (Phase 2 Additions)

### Results Table
```sql
CREATE TABLE results (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    date DATE NOT NULL,
    result_type ENUM('hot_lead', 'deal_closed', 'commission'),
    value DECIMAL(12,2) DEFAULT 0,     -- For commission amount
    quantity INT DEFAULT 1,             -- For leads/deals count
    points_earned INT DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Weekly Scores Table
```sql
CREATE TABLE weekly_scores (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    week_start DATE NOT NULL,
    week_end DATE NOT NULL,
    avg_momentum_score DECIMAL(5,2) DEFAULT 0,
    total_deals INT DEFAULT 0,
    total_leads INT DEFAULT 0,
    total_commission DECIMAL(12,2) DEFAULT 0,
    days_active INT DEFAULT 0,
    consistency_percentage DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## 2.9 — Follow-up Discipline Guard

From the master diagram, there's a **Follow-up Discipline Guard** that monitors:

- Missed follow-up alerts
- If a user logs follow-ups inconsistently, the system generates:
  - **Notification:** "You have {N} follow-ups pending. Don't lose momentum."
  - **Dashboard alert:** Highlighted missed follow-up card

### Implementation
- [ ] Track follow-up activities specifically
- [ ] If no follow-up logged in 48 hours after a lead was added → trigger alert
- [ ] Show on Home Dashboard as a priority card

---

## 2.10 — Home Dashboard Updates (Phase 2)

Now the dashboard becomes **LIVE** with real data:

- [ ] Circular ring updates in real-time as activities are logged
- [ ] Score breakdown shows live numbers
- [ ] Streak counter updates on each qualifying day
- [ ] Monthly income updates when commission is logged
- [ ] Color transitions (red → orange → green) based on score
- [ ] Pull-to-refresh recalculates score
- [ ] Show "Minimum activities remaining" counter

---

## 2.11 — Phase 2 Deliverables Checklist

| # | Deliverable | Status |
|---|------------|--------|
| 1 | Tasks Tab with Identity Conditioning section | ✅ Done (activities_page.dart — 42KB) |
| 2 | Tasks Tab with Revenue Actions section | ✅ Done (conscious category in activity types) |
| 3 | Results Tracker (leads, deals, commission) | ✅ Done (results_tracker_page.dart + POST/GET /results API) |
| 4 | Daily Score Calculation Engine (backend) | ✅ Done (performance_metrics table + results table integration) |
| 5 | Real-time score ring updates | ✅ Done (momentum_hub_widget.dart) |
| 6 | Streak system with gentle messaging | ✅ Done (basic — needs gentle messaging UX) |
| 7 | Activity logging API endpoints | ✅ Done |
| 8 | Follow-up Discipline Guard alerts | ✅ Done (follow_ups table + overdue alerts + guard_alert) |
| 9 | Monthly results graph | ✅ Done (6-month trends tab + commission bar chart) |
| 10 | Score color system (red/orange/green) | ✅ Done |

---

> **Previous:** [Phase 1 — Foundation & Onboarding](./Phase_1_Foundation_Setup.md)
> **Next:** [Phase 3 — Learning Tab & Belief System](./Phase_3_Learning_Belief_System.md)
