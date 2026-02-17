**Application Name:** RealtorOne  
**Language/Framework:** Flutter  

**Backend:** Laravel  

**Purpose:**  
- A “fitness-style” diagnostics experience that maps how a realtor’s business is performing across the same 4 pillars promoted on the website: Personal Branding, Lead Generation, Mindset & Belief Work, Community & Mentorship.  
- After the user answers questions (the mobile “Scorecard”), the app:  
  * calculates a score  
  * pinpoints blind spots  
  * produces a custom roadmap  
  * recommends next actions / free courses / join WhatsApp community (mirrors [website flow](research/website-therealtorone-details.md)).  

**Core Flow:**  Diagnostic Quiz → Result Dashboard → Action Plan → Share / Join Community  

**UX VISION – “Realtor Skill-Education Dashboard”**  
Goal:  Give every *licensed real-estate agent / Realtor* an instant answer to:  
"How educated / professional am I in modern real-estate skills?"  

Combine inspiration from:  
- Healthy-fie / Jio / Airtel apps (clear daily metrics, streaks, upgrade prompts)  
- Duolingo / Fitbit (gamified progress, streaks, card stacks)  
- Head-space SOS (30-second interventions)  

**Core FEEL of the dashboard (Realtor-centric):**  
1. One glance *Realtor-Education Ring* (0-100) that answers “How professional / educated am I today?”  
2. Four education clusters merge into the global score:  
   a. Market Knowledge (regulations, RERA, latest Dubai laws, trends)  
   b. Lead Generation (social ads, SEO, referrals, funnels)  
   c. Sales Mastery (objection handling, negotiations, contracts)  
   d. Personal Brand (social posts, content quality, testimonials)  
3. Action cards that flip between:  
   A. *Data snapshot* (last 7 days: leads, listing views, post reach)  
   B. *Coach tip* (“2-minute training: how to answer ‘I’ll think about it’”)  
   C. *Quick win* today (post one Reel with this caption, call 2 expired listings).  

**User Journey Flows Implemented:**  
**Why This Fever?**  
Onboarding: 5-slider pain detector for Realtors – traffic drop, no listings, low closing ratio.  
**Mind-Set Choking?**  
Micro 30-second interventions (confidence script, call-openers) + “Upgrade / Scale” CTAs.  
**Coach Me vs Do It Myself Toggle**  
Every action card has:  
- Auto-play coach video (≤30 s)  
- Script/GIF demo  
- “Mark done – skip” button (tracks completion).  

**Gamification & Retention (Realtor edition):**  
- Daily streak (open the app & complete 1 card).  
- Weekly “Seal the Deal” badge – if 3 cards finished.  
- In-app currency: “Dirham Points” – spend on free courses / unlock Million Dirham Club.  
- Leaderboard among your office-team or friends (opt-in).  

**Upgrade / Scale Prompts:**  
- “Your listing photos score 4/10 – tap to auto-order professional shoot.”  
- “Unlock advanced RERA contract templates – try 7 days free.”  

**Visual Language:**  
- Gradient education rings – teal to red.  
- Dark mode first. Short Realtor slang copy. Emojis.  
- Haptic on badge / ring complete.  

**Navigation Stack (Flutter):**  
1. Splash → Login / Guest  
2. Why This Fever (Realtor-pain detector)  
3. On-boarding (add agency, license number, social links)  
4. Dashboard (Realtor-Edu rings + tips)  
5. Coach Playground (micro-lessons & action cards)  
6. Courses Library (YouTube playlists embedded)  
7. Team Meetings (Google Meet / Zoom calendar + join)  
8. AI Chat Assistant (floating button + dedicated screen)  
9. Upgrade Flow  
10. Profile (license upload, badges, referrals)  

**Membership & Tracking**  
- Freemium tiers: FREE, SILVER (AED 29/mo), GOLD (AED 79/mo).  
- Laravel backend stores:  
  * member tier, renewal date, dirham-points balance  
  * every completed card, streak days, quiz scores, roadmap progress  
- Device-local SQLite for offline streak/cache; sync to cloud on reconnect.  
- Stripe & PayFort for recurring payments; web-hook updates tier in-app immediately.  
- Push-reminders if streak-break risk detected (Flutter Local-Notifications + Firebase Cloud-Messaging).  

**Team Meetings Integration**  
- Google Meet / Zoom integration for scheduled team meetings.  
- Laravel backend stores meeting links, dates, reminders.  
- Flutter in-app calendar widget shows upcoming sessions.  
- One-tap join button opens Meet/Zoom app or web-view.  
- Push notification 15 min before meeting starts.  
- Meeting history tracked (attended/missed) for streak/badges.  

**White-Label Video Courses**  
- Self-hosted video courses (no YouTube branding).  
- Videos stored on Laravel server / AWS S3 / Cloudflare Stream / Vimeo API (white-label).  
- Custom Flutter video player (video_player / chewie / better_player) with RealtorOne branding.  
- Laravel backend stores: video URLs, thumbnails, duration, course metadata, progress per user, completion badges.  
- Course library organized by pillar (Branding, Lead Gen, Sales, Mindset).  
- Watch progress synced across devices (timestamp saved per video).  
- “Continue Watching” card on dashboard.  
- Completion unlocks Dirham Points + badges.  
- Optional: Download for offline viewing (membership tier dependent).  
- Analytics: watch time, drop-off points, completion rates per video (stored in Laravel).  

**AI Chat Assistant**  
- Per-user AI chat for real-time problem-solving (OpenAI GPT / Claude API via Laravel).  
- Context-aware: remembers user’s current score, weak pillars, recent quiz answers.  
- Chat history stored in Laravel DB per user.  
- Quick actions: “Help me write a LinkedIn post”, “How do I handle this objection?”, “Explain RERA rule X”.  
- Voice input support (speech_to_text Flutter plugin).  
- Chat icon floating button on all screens (except during video playback).  