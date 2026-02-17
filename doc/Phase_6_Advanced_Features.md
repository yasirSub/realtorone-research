# ⚙️ PHASE 6 — ADVANCED FEATURES & INTEGRATIONS

> ### 🟡 STATUS: **~20% COMPLETE**
> Profile, settings, and subscription UI are built. Reports page exists. Missing: real payment gateway, push notifications, team meetings, offline mode, weekly review dashboard.

**Timeline:** 3-4 Weeks | **Priority:** 🟡 Medium | **Depends on:** Phase 1-5

---

## 📌 What We Build

1. Weekly Review Dashboard
2. Push Notifications (full system)
3. Team Meetings Integration
4. Offline Mode
5. Payment Integration (Stripe + PayFort)
6. Profile & Settings
7. Sharing & Referrals
8. Monthly Revenue Intelligence Reports

---

## 6.1 — Weekly Review Dashboard

Auto-generated every Sunday:
- Average Momentum Score this week
- Total Calls Logged
- Deals Closed
- Income Generated (AED)
- Streak Status (maintained/broken)
- **Personal Best vs This Week** (no comparison with others)
- Consistency % (days_active / 7)
- AI Weekly Strategy (Start/Stop/Double Down)

### Message Examples
- *"You scored 15% higher than your personal average this week. Keep going!"*
- *"This was your best week in 4 weeks. Momentum compounds."*

---

## 6.2 — Push Notification System

| Trigger | Time | Message |
|---------|------|---------|
| Morning reminder | 8 AM | "Your momentum clock starts now. Log your first activity." |
| Streak at risk | 6 PM | "Your {N}-day streak needs {X} more activities!" |
| Streak maintained | 10 PM | "🔥 Streak: {N} days! Consistency compounds." |
| Weekly review ready | Sunday 9 PM | "Your weekly review is ready. See how you performed." |
| Badge earned | Real-time | "🏆 Badge unlocked: {badge_name}!" |
| Meeting reminder | 15 min before | "Team meeting starts in 15 minutes." |
| AI daily priority | 6 AM | "Today's priority: {AI recommendation}" |
| Belief cycle complete | Real-time | "7-Day Belief Cycle complete! Identity reinforced." |

### Tech Stack
- Firebase Cloud Messaging (FCM)
- Flutter Local Notifications
- Laravel queue + scheduled jobs

---

## 6.3 — Team Meetings Integration

- Google Meet / Zoom integration
- In-app calendar widget (table_calendar)
- One-tap join button
- Meeting reminders (15 min before)
- Attendance tracking (attended/missed → affects badges)
- Meeting history stored in backend

### API Endpoints
```
GET    /api/meetings/upcoming    → List upcoming meetings
GET    /api/meetings/history     → Meeting attendance history
POST   /api/meetings/attend      → Mark attendance
```

---

## 6.4 — Offline Mode

- SQLite local storage for:
  - Today's activities
  - Current streak
  - Score cache
  - Pending activity logs
- Auto-sync to cloud on reconnect
- Connectivity detection (connectivity_plus)
- Queue pending API calls
- Show "Offline Mode" indicator

---

## 6.5 — Payment Integration

### Stripe Integration
- Subscription checkout flow
- Recurring payments (monthly)
- Webhook for payment status updates
- Trial period support (7 days free)
- Upgrade/downgrade/cancel flows

### PayFort (UAE Gateway)
- Alternative payment method for UAE users
- AED currency support
- Same webhook pattern

### Pricing
| Tier | Monthly | Annual (15% off) |
|------|---------|------------------|
| Consultant | FREE | FREE |
| Rainmaker | 210 AED | 2,142 AED |
| Titan – GOLD | 420 AED | 4,284 AED |

---

## 6.6 — Profile & Settings

### Profile Screen
- Avatar upload
- Name, email, phone
- Area of focus
- Income goal (editable)
- Membership tier badge
- Current streak display
- All earned badges grid
- Dirham Points balance
- Referral code
- Account settings

### Settings
- Notification preferences
- Dark/Light mode
- Language (English, Arabic)
- Data export
- Delete account
- Privacy policy / Terms

---

## 6.7 — Monthly Revenue Intelligence (From Master Diagram)

### Reports Include
- Monthly Revenue Impact by channel
- Commission breakdown
- Deal Sources & Conversion Ratios
- Badges & Status: Momentum Builder, Market Operator, Deal Maker
- Consistency Leaders ranking
- Momentum Climbers (week vs last week)
- Personal best comparison

---

## 6.8 — Phase 6 Checklist

| # | Deliverable | Status |
|---|------------|--------|
| 1 | Weekly Review Dashboard | ❌ Missing |
| 2 | Full push notification system | ❌ Missing |
| 3 | Team Meetings integration | ❌ Missing |
| 4 | Offline mode with sync | ❌ Missing |
| 5 | Stripe subscription flow | 🟡 Partial (subscription UI exists, no real Stripe) |
| 6 | PayFort integration | ❌ Missing |
| 7 | Profile screen with badges | ✅ Done (profile_page.dart + edit_profile_page.dart) |
| 8 | Settings screen | ✅ Done (settings_page.dart) |
| 9 | Monthly Revenue Intelligence report | 🟡 Partial (reports_page.dart exists) |
| 10 | Sharing & referral system | ❌ Missing |

---

> **Previous:** [Phase 5](./Phase_5_AI_Intelligence_Layer.md) | **Next:** [Phase 7](./Phase_7_Polish_Launch.md)
