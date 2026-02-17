# RealtorOne - Recommended Tech Stack & Requirements

## Frontend (Flutter)

### Core Packages
- **flutter**: Latest stable (3.24+)
- **get/getx** OR **provider/riverpod**: State management (GetX recommended for simplicity)
- **dio**: HTTP client for API calls
- **shared_preferences**: Local storage (settings, tokens)
- **sqflite**: SQLite for offline data (streaks, cache)
- **flutter_local_notifications**: Local push notifications
- **firebase_messaging**: Cloud push notifications
- **cached_network_image**: Image caching
- **flutter_svg**: SVG icons

### UI/UX Packages
- **flutter_screenutil**: Responsive design
- **google_fonts**: Custom fonts
- **flutter_animate**: Animations
- **lottie**: Lottie animations (badges, celebrations)
- **shimmer**: Loading skeletons
- **flutter_spinkit**: Loading indicators
- **fl_chart**: Charts for progress rings
- **syncfusion_flutter_gauges**: Circular progress rings (alternative)

### Video Player
- **video_player**: Core video playback
- **chewie**: Customizable video player UI (recommended)
- **wakelock_plus**: Keep screen on during video
- **flutter_cache_manager**: Video caching

### Authentication & Payments
- **firebase_auth**: Email/phone login (optional)
- **google_sign_in**: Google login
- **flutter_stripe**: Stripe payments
- **in_app_purchase**: App Store / Play Store subscriptions (alternative)

### AI & Voice
- **speech_to_text**: Voice input for AI chat
- **flutter_tts**: Text-to-speech (optional)

### Calendar & Meetings
- **table_calendar**: Calendar widget
- **url_launcher**: Open Google Meet / Zoom links
- **flutter_local_notifications**: Meeting reminders

### Other Utilities
- **connectivity_plus**: Check internet connection
- **package_info_plus**: App version info
- **device_info_plus**: Device info
- **share_plus**: Share results/achievements
- **path_provider**: File paths for downloads
- **permission_handler**: Request permissions

---

## Backend (Laravel)

### Laravel Version
- **Laravel 11** (latest stable)

### Core Packages
- **laravel/sanctum**: API authentication
- **laravel/passport**: OAuth2 (if needed)
- **spatie/laravel-permission**: Role-based permissions
- **spatie/laravel-activitylog**: Activity tracking

### Database
- **MySQL 8.0+** OR **PostgreSQL 14+**
- **Redis**: Caching & sessions
- **Laravel Horizon**: Queue management (for background jobs)

### File Storage & Video
- **AWS S3** (recommended) OR **Cloudflare Stream** OR **Vimeo API**
- **laravel/filesystem**: S3 integration
- **intervention/image**: Image processing (thumbnails)

### Payments
- **laravel/cashier**: Stripe subscriptions
- **laravel/payfort**: PayFort integration (custom package)

### AI Integration
- **openai-php/laravel**: OpenAI GPT integration
- **anthropic/anthropic-sdk-php**: Claude API (alternative)

### Notifications
- **laravel/push-notification**: Push notifications
- **laravel/notifications**: Email/SMS notifications

### API & Documentation
- **spatie/laravel-query-builder**: API filtering/sorting
- **knuckleswtf/scribe**: API documentation

### Other
- **laravel/telescope**: Debugging (dev only)
- **spatie/laravel-backup**: Database backups
- **spatie/laravel-queueable-action**: Queue actions

---

## Third-Party Services & Accounts Needed

### Required Accounts/Services

1. **Firebase** (Free tier available)
   - Firebase Console account
   - Firebase Cloud Messaging (FCM) for push notifications
   - Firebase Analytics (optional)
   - Firebase Storage (optional, for images)

2. **Stripe** (Payment processing)
   - Stripe account
   - API keys (test + live)
   - Webhook endpoint configured

3. **PayFort** (UAE payment gateway)
   - PayFort merchant account
   - API credentials

4. **AWS S3** (Video storage - recommended)
   - AWS account
   - S3 bucket created
   - CloudFront CDN (optional, for faster video delivery)
   - IAM user with S3 permissions

   **OR**

5. **Cloudflare Stream** (Alternative video hosting)
   - Cloudflare account
   - Stream API key

   **OR**

6. **Vimeo Pro** (Alternative video hosting)
   - Vimeo Pro account
   - API access token

7. **OpenAI** OR **Anthropic Claude** (AI chat)
   - OpenAI API account + API key
   - OR Anthropic Claude API account + key
   - Budget set (pay-per-use)

8. **Google Cloud** (Optional - for Google Meet API)
   - Google Cloud account
   - Google Meet API enabled (if using API)

9. **Zoom** (Optional - for Zoom API)
   - Zoom developer account
   - OAuth app credentials (if using API)

10. **Email Service** (For notifications)
    - **Mailgun** OR **SendGrid** OR **AWS SES**
    - API credentials

11. **SMS Service** (Optional - for OTP/notifications)
    - **Twilio** OR **AWS SNS**
    - Account + API credentials

---

## Server Requirements

### Laravel Server (Production)
- **PHP 8.2+**
- **MySQL 8.0+** OR **PostgreSQL 14+**
- **Redis** (for caching)
- **Nginx** OR **Apache**
- **SSL Certificate** (Let's Encrypt free)
- **Domain name** (e.g., api.realtorone.com)

### Recommended Hosting
- **DigitalOcean** (Droplet $12-24/mo)
- **AWS EC2** (t3.medium ~$30/mo)
- **Laravel Forge** (Server management)
- **Laravel Vapor** (Serverless - advanced)

---

## Development Tools Needed

### Flutter Development
- **Android Studio** OR **VS Code**
- **Flutter SDK** installed
- **Android SDK** (for Android builds)
- **Xcode** (for iOS builds - Mac only)
- **Android Emulator** OR **iOS Simulator**

### Laravel Development
- **PHP 8.2+** installed locally
- **Composer** (PHP package manager)
- **MySQL/PostgreSQL** installed locally
- **Redis** installed locally
- **Postman** OR **Insomnia** (API testing)

### Design Tools
- **Figma** (UI/UX design)
- **Adobe XD** (Alternative)

---

## Database Schema Overview

### Core Tables Needed
1. **users** (id, email, name, membership_tier, dirham_points, etc.)
2. **memberships** (id, user_id, tier, start_date, end_date, status)
3. **quiz_responses** (id, user_id, question_id, answer, score)
4. **user_scores** (id, user_id, pillar, score, updated_at)
5. **streaks** (id, user_id, current_streak, longest_streak, last_activity)
6. **courses** (id, title, pillar, video_url, thumbnail, duration)
7. **course_progress** (id, user_id, course_id, progress_percent, last_position)
8. **meetings** (id, title, link, date_time, type, user_ids)
9. **meeting_attendance** (id, meeting_id, user_id, attended)
10. **ai_chat_history** (id, user_id, message, response, context)
11. **badges** (id, user_id, badge_type, earned_at)
12. **action_cards** (id, user_id, card_type, completed, completed_at)

---

## Estimated Monthly Costs (Production)

- **Server (DigitalOcean)**: $24/mo
- **AWS S3 Storage (100GB videos)**: ~$2-5/mo
- **CloudFront CDN**: ~$5-10/mo
- **Stripe Fees**: 2.9% + $0.30 per transaction
- **PayFort Fees**: Check with PayFort
- **OpenAI API**: ~$20-50/mo (depends on usage)
- **Firebase**: Free tier usually sufficient
- **Email Service**: ~$10-20/mo (Mailgun/SendGrid)
- **Domain + SSL**: ~$12/year

**Total**: ~$70-120/mo (excluding payment processing fees)

---

## Development Phases

### Phase 1: MVP (2-3 months)
- Flutter app setup
- Laravel API setup
- User authentication
- Basic dashboard with rings
- Diagnostic quiz
- Score calculation

### Phase 2: Core Features (2-3 months)
- Video courses integration
- AI chat assistant
- Streaks & badges
- Push notifications
- Membership tiers

### Phase 3: Advanced (1-2 months)
- Team meetings integration
- Advanced analytics
- Leaderboard
- Offline mode
- Payment integration

---

## Next Steps

1. ✅ Set up Firebase account
2. ✅ Set up Stripe account
3. ✅ Set up AWS S3 (or Cloudflare Stream)
4. ✅ Set up OpenAI API account
5. ✅ Buy domain name
6. ✅ Set up Laravel server
7. ✅ Create Flutter project
8. ✅ Design database schema
9. ✅ Start development
