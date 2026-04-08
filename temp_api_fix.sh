cat << 'EOF' > /var/www/html/routes/api.php
<?php

use App\Http\Controllers\Admin\NotificationBroadcastController;
use App\Support\ClientMeetingFlow;
use App\Support\ColdCallingFlow;
use App\Support\CrmPipeline;
use App\Support\DealClosureFlow;
use App\Support\DealNegotiationFlow;
use App\Support\FollowUpFlow;
use App\Models\LegalDocument;
use App\Models\User;
use App\Models\UserPushToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Str;

// Helper function to get authenticated user
function getAuthUser(Request $request)
{
    $token = $request->bearerToken();
    if (! $token) {
        return null;
    }

    return User::where('remember_token', $token)->first();
}

function seedDefaultActivityTypes()
{
    $identityKeys = [
        'visualization',
        'affirmations',
        'gratitude_journaling',
        'mindset_training',
        'audio_reprogramming',
        'webinar_attendance',
        'belief_exercise',
        'calm_reset',
        'identity_statement',
        'morning_focus_ritual',
    ];
    \App\Models\ActivityType::where('category', 'subconscious')->whereNotIn('type_key', $identityKeys)->delete();

    $types = [
        ['name' => 'Visualization', 'points' => 8, 'category' => 'subconscious', 'section_title' => 'Mindset & Inner Strength', 'section_order' => 1, 'item_order' => 1, 'type_key' => 'visualization', 'icon' => 'Eye'],
        ['name' => 'Affirmations', 'points' => 6, 'category' => 'subconscious', 'section_title' => 'Mindset & Inner Strength', 'section_order' => 1, 'item_order' => 2, 'type_key' => 'affirmations', 'icon' => 'Repeat'],
        ['name' => 'Belief Exercise', 'points' => 8, 'category' => 'subconscious', 'section_title' => 'Mindset & Inner Strength', 'section_order' => 1, 'item_order' => 3, 'type_key' => 'belief_exercise', 'icon' => 'BookOpen'],
        ['name' => 'Identity Statement', 'points' => 5, 'category' => 'subconscious', 'section_title' => 'Mindset & Inner Strength', 'section_order' => 1, 'item_order' => 4, 'type_key' => 'identity_statement', 'icon' => 'ShieldCheck'],
        ['name' => 'Gratitude Journaling', 'points' => 6, 'category' => 'subconscious', 'section_title' => 'Mindset & Inner Strength', 'section_order' => 1, 'item_order' => 5, 'type_key' => 'gratitude_journaling', 'icon' => 'BookHeart'],
        ['name' => 'Calm Reset', 'points' => 5, 'category' => 'subconscious', 'section_title' => 'Mindset & Inner Strength', 'section_order' => 1, 'item_order' => 6, 'type_key' => 'calm_reset', 'icon' => 'Wind'],
        ['name' => 'Audio Reprogramming', 'points' => 6, 'category' => 'subconscious', 'section_title' => 'Mindset & Inner Strength', 'section_order' => 1, 'item_order' => 7, 'type_key' => 'audio_reprogramming', 'icon' => 'Headphones'],
        ['name' => 'Morning Focus Ritual', 'points' => 6, 'category' => 'subconscious', 'section_title' => 'Growth & Daily Performance', 'section_order' => 2, 'item_order' => 1, 'type_key' => 'morning_focus_ritual', 'icon' => 'Sunrise'],
        ['name' => 'Mindset Training', 'points' => 8, 'category' => 'subconscious', 'section_title' => 'Growth & Daily Performance', 'section_order' => 2, 'item_order' => 2, 'type_key' => 'mindset_training', 'icon' => 'Brain'],
        ['name' => 'Webinar Attendance', 'points' => 10, 'category' => 'subconscious', 'section_title' => 'Growth & Daily Performance', 'section_order' => 2, 'item_order' => 3, 'type_key' => 'webinar_attendance', 'icon' => 'Video'],

        ['name' => 'Cold Calling Block', 'points' => 6, 'category' => 'conscious', 'section_title' => 'Lead Generation', 'section_order' => 1, 'item_order' => 1, 'type_key' => 'cold_calling_block', 'icon' => 'Phone'],
        ['name' => 'Follow-Up Block', 'points' => 8, 'category' => 'conscious', 'section_title' => 'Lead Generation', 'section_order' => 1, 'item_order' => 2, 'type_key' => 'follow_up_block', 'icon' => 'RefreshCw'],
        ['name' => 'Prospecting Session', 'points' => 7, 'category' => 'conscious', 'section_title' => 'Lead Generation', 'section_order' => 1, 'item_order' => 3, 'type_key' => 'prospecting_session', 'icon' => 'Search'],
        ['name' => 'Referral Ask', 'points' => 6, 'category' => 'conscious', 'section_title' => 'Lead Generation', 'section_order' => 1, 'item_order' => 4, 'type_key' => 'referral_ask', 'icon' => 'UserPlus'],
        ['name' => 'Network Event', 'points' => 10, 'category' => 'conscious', 'section_title' => 'Lead Generation', 'section_order' => 1, 'item_order' => 5, 'type_key' => 'network_event', 'icon' => 'Network'],
        ['name' => 'Client Meeting', 'points' => 12, 'category' => 'conscious', 'section_title' => 'Client Conversion', 'section_order' => 2, 'item_order' => 1, 'type_key' => 'client_meeting', 'icon' => 'Users'],
        ['name' => 'Site Visit', 'points' => 15, 'category' => 'conscious', 'section_title' => 'Client Conversion', 'section_order' => 2, 'item_order' => 2, 'type_key' => 'site_visit', 'icon' => 'MapPin'],
        ['name' => 'Deal Negotiation', 'points' => 18, 'category' => 'conscious', 'section_title' => 'Client Conversion', 'section_order' => 2, 'item_order' => 3, 'type_key' => 'deal_negotiation', 'icon' => 'Briefcase'],
        ['name' => 'Proposal Sent', 'points' => 14, 'category' => 'conscious', 'section_title' => 'Client Conversion', 'section_order' => 2, 'item_order' => 4, 'type_key' => 'proposal_sent', 'icon' => 'FileText'],
        ['name' => 'Deal Closed', 'points' => 40, 'category' => 'conscious', 'section_title' => 'Client Conversion', 'section_order' => 2, 'item_order' => 5, 'type_key' => 'deal_closed', 'icon' => 'BadgeDollarSign'],
        ['name' => 'Content Creation', 'points' => 4, 'category' => 'conscious', 'section_title' => 'Brand & Visibility', 'section_order' => 3, 'item_order' => 1, 'type_key' => 'content_creation', 'icon' => 'Camera'],
        ['name' => 'Content Posting', 'points' => 3, 'category' => 'conscious', 'section_title' => 'Brand & Visibility', 'section_order' => 3, 'item_order' => 2, 'type_key' => 'content_posting', 'icon' => 'Share2'],
        ['name' => 'CRM Update', 'points' => 2, 'category' => 'conscious', 'section_title' => 'Operations & Pipeline', 'section_order' => 4, 'item_order' => 1, 'type_key' => 'crm_update', 'icon' => 'Database'],
    ];

    foreach ($types as $type) {
        \App\Models\ActivityType::updateOrCreate(
            ['type_key' => $type['type_key']],
            array_merge($type, ['is_global' => true])
        );
    }
}

Route::get('/health', function () {
    $dbOk = true;
    $dbError = null;

    try {
        DB::connection()->getPdo();
    } catch (\Throwable $error) {
        $dbOk = false;
        $dbError = $error->getMessage();
    }

    return response()->json([
        'status' => 'ok',
        'app' => config('app.name'),
        'environment' => config('app.env'),
        'db' => [
            'ok' => $dbOk,
            'error' => $dbError,
        ],
        'timestamp' => now()->toIso8601String(),
    ]);
});

/** Public legal documents (mobile WebView + website). */
Route::get('/legal-documents/{slug}', function (string $slug) {
    if (! in_array($slug, ['privacy', 'terms'], true)) {
        return response()->json(['success' => false, 'message' => 'Not found'], 404);
    }
    $doc = LegalDocument::query()->where('slug', $slug)->first();
    if (! $doc) {
        return response()->json(['success' => false, 'message' => 'Not found'], 404);
    }

    return response()->json([
        'success' => true,
        'slug' => $doc->slug,
        'title' => $doc->title,
        'html' => $doc->body_html,
        'updated_at' => $doc->updated_at?->toIso8601String(),
    ]);
});

Route::get('/admin/legal-documents', function (Request $request) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }
    $rows = LegalDocument::query()
        ->orderBy('slug')
        ->get(['slug', 'title', 'updated_at']);

    return response()->json(['success' => true, 'data' => $rows]);
});

Route::get('/admin/legal-documents/{slug}', function (Request $request, string $slug) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }
    if (! in_array($slug, ['privacy', 'terms'], true)) {
        return response()->json(['success' => false, 'message' => 'Invalid slug'], 404);
    }
    $doc = LegalDocument::query()->where('slug', $slug)->firstOrFail();

    return response()->json([
        'success' => true,
        'data' => [
            'slug' => $doc->slug,
            'title' => $doc->title,
            'body_html' => $doc->body_html,
            'updated_at' => $doc->updated_at?->toIso8601String(),
        ],
    ]);
});

Route::put('/admin/legal-documents/{slug}', function (Request $request, string $slug) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }
    if (! in_array($slug, ['privacy', 'terms'], true)) {
        return response()->json(['success' => false, 'message' => 'Invalid slug'], 404);
    }
    $data = $request->validate([
        'title' => ['sometimes', 'string', 'max:255'],
        'body_html' => ['required', 'string', 'max:500000'],
    ]);
    $html = $data['body_html'];
    $html = preg_replace('#<\s*script\b[^>]*>.*?<\s*/\s*script\s*>#is', '', $html) ?? $html;
    $doc = LegalDocument::query()->where('slug', $slug)->firstOrFail();
    $doc->title = $data['title'] ?? $doc->title;
    $doc->body_html = $html;
    $doc->save();

    return response()->json([
        'success' => true,
        'message' => 'Legal document updated.',
        'data' => [
            'slug' => $doc->slug,
            'title' => $doc->title,
            'updated_at' => $doc->updated_at?->toIso8601String(),
        ],
    ]);
});

// Reven chatbot
Route::post('/chat', [\App\Http\Controllers\ChatController::class, 'send']);
Route::get('/chat/history', [\App\Http\Controllers\ChatController::class, 'history']);
Route::get('/chat/history/{sessionId}', [\App\Http\Controllers\ChatController::class, 'history']);
Route::delete('/chat/history/{sessionId}', [\App\Http\Controllers\ChatController::class, 'deleteSession']);

// Admin: Reven AI inbox (monitor all user chat sessions/messages)
Route::get('/admin/ai/users', function (Request $request) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $todayStart = now()->startOfDay();

    $users = \App\Models\User::query()
        ->where('email', '!=', 'admin@realtorone.com')
        ->orderByDesc('created_at')
        ->limit(200)
        ->get(['id', 'name', 'email', 'membership_tier', 'is_premium']);

    // Usage: sum assistant message tokens for last 24h + total.
    foreach ($users as $u) {
        $todayAgg = DB::table('chat_messages')
            ->join('chat_sessions', 'chat_sessions.id', '=', 'chat_messages.chat_session_id')
            ->where('chat_sessions.user_id', $u->id)
            ->where('chat_messages.role', 'assistant')
            ->where('chat_messages.created_at', '>=', $todayStart)
            ->selectRaw('COALESCE(SUM(chat_messages.total_tokens), 0) as total_tokens, COUNT(*) as ai_calls')
            ->first();

        $totalAgg = DB::table('chat_messages')
            ->join('chat_sessions', 'chat_sessions.id', '=', 'chat_messages.chat_session_id')
            ->where('chat_sessions.user_id', $u->id)
            ->where('chat_messages.role', 'assistant')
            ->selectRaw('COALESCE(SUM(chat_messages.total_tokens), 0) as total_tokens, COUNT(*) as ai_calls')
            ->first();

        $u->ai_tokens_today = (int) ($todayAgg->total_tokens ?? 0);
        $u->ai_calls_today = (int) ($todayAgg->ai_calls ?? 0);
        $u->ai_tokens_total = (int) ($totalAgg->total_tokens ?? 0);
        $u->ai_calls_total = (int) ($totalAgg->ai_calls ?? 0);
    }

    return response()->json(['success' => true, 'data' => $users]);
});

// Admin: AI runtime settings (API key + custom knowledge base text)
Route::get('/admin/ai/settings', function (Request $request) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $apiKey = (string) cache('ai_openai_api_key', '');
    $knowledgeBase = (string) cache('ai_custom_knowledge_base', '');
    $kbBlocksRaw = (string) cache('ai_kb_blocks', '[]');
    $kbBlocks = json_decode($kbBlocksRaw, true);
    if (! is_array($kbBlocks)) {
        $kbBlocks = [];
    }
    $behavior = (string) cache('ai_behavior_instructions', '');
    $provider = (string) cache('ai_provider', 'openai');
    $model = (string) cache('ai_openai_model', 'gpt-4o-mini');
    $baseUrl = (string) cache('ai_openai_base_url', '');
    $useCustomKb = (bool) cache('ai_use_custom_kb', true);
    $useCourseKb = (bool) cache('ai_use_course_kb', true);
    $allowConsultant = (bool) cache('ai_allow_consultant', true);
    $allowRainmaker = (bool) cache('ai_allow_rainmaker', true);
    $allowTitan = (bool) cache('ai_allow_titan', true);

    return response()->json([
        'success' => true,
        'data' => [
            'provider' => $provider,
            'model' => $model,
            'base_url' => $baseUrl,
            'api_key' => $apiKey,
            'has_api_key' => $apiKey !== '',
            'knowledge_base' => $knowledgeBase,
            'kb_blocks' => $kbBlocks,
            'behavior' => $behavior,
            'kb_sources' => [
                'custom' => $useCustomKb,
                'courses' => $useCourseKb,
            ],
            'tier_allow' => [
                'Consultant' => $allowConsultant,
                'Rainmaker' => $allowRainmaker,
                'Titan' => $allowTitan,
            ],
        ],
    ]);
});

Route::post('/admin/ai/settings', function (Request $request) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $validated = $request->validate([
        'provider' => 'nullable|string|in:openai,openrouter,groq,together,deepseek,mistral,fireworks,xai,disabled',
        'model' => 'nullable|string|max:80',
        'base_url' => 'nullable|string|max:300',
        'api_key' => 'nullable|string|max:500',
        'knowledge_base' => 'nullable|string|max:200000',
        'kb_blocks' => 'nullable|array',
        'kb_blocks.*.id' => 'nullable|string|max:60',
        'kb_blocks.*.title' => 'nullable|string|max:120',
        'kb_blocks.*.content' => 'nullable|string|max:200000',
        'kb_blocks.*.enabled' => 'nullable|boolean',
        'behavior' => 'nullable|string|max:20000',
        'kb_sources' => 'nullable|array',
        'kb_sources.custom' => 'nullable|boolean',
        'kb_sources.courses' => 'nullable|boolean',
        'tier_allow' => 'nullable|array',
        'tier_allow.Consultant' => 'nullable|boolean',
        'tier_allow.Rainmaker' => 'nullable|boolean',
        'tier_allow.Titan' => 'nullable|boolean',
    ]);

    $provider = trim((string) ($validated['provider'] ?? 'openai'));
    if ($provider === '') {
        $provider = 'openai';
    }
    $model = trim((string) ($validated['model'] ?? 'gpt-4o-mini'));
    if ($model === '') {
        $model = 'gpt-4o-mini';
    }
    $baseUrl = trim((string) ($validated['base_url'] ?? ''));
    $apiKey = trim((string) ($validated['api_key'] ?? ''));
    $knowledgeBase = trim((string) ($validated['knowledge_base'] ?? ''));
    $behavior = trim((string) ($validated['behavior'] ?? ''));
    $kbBlocks = is_array($validated['kb_blocks'] ?? null) ? $validated['kb_blocks'] : null;
    $kbSources = is_array($validated['kb_sources'] ?? null) ? $validated['kb_sources'] : [];
    $tierAllow = is_array($validated['tier_allow'] ?? null) ? $validated['tier_allow'] : [];

    cache(['ai_provider' => $provider], now()->addYears(5));
    cache(['ai_openai_model' => $model], now()->addYears(5));
    cache(['ai_openai_base_url' => $baseUrl], now()->addYears(5));
    cache(['ai_openai_api_key' => $apiKey], now()->addYears(5));
    cache(['ai_custom_knowledge_base' => $knowledgeBase], now()->addYears(5));
    cache(['ai_behavior_instructions' => $behavior], now()->addYears(5));
    if ($kbBlocks !== null) {
        // Keep the payload small/safe. Only store expected keys.
        $clean = [];
        foreach ($kbBlocks as $b) {
            if (! is_array($b)) continue;
            $id = trim((string) ($b['id'] ?? ''));
            $title = trim((string) ($b['title'] ?? ''));
            $content = trim((string) ($b['content'] ?? ''));
            $enabled = (bool) ($b['enabled'] ?? true);
            if ($id === '') {
                $id = (string) \Illuminate\Support\Str::uuid();
            }
            if ($title === '' && $content === '') continue;
            $clean[] = [
                'id' => mb_substr($id, 0, 60),
                'title' => mb_substr($title, 0, 120),
                'content' => mb_substr($content, 0, 200000),
                'enabled' => $enabled,
            ];
        }
        cache(['ai_kb_blocks' => json_encode($clean)], now()->addYears(5));
    }
    if (array_key_exists('custom', $kbSources)) {
        cache(['ai_use_custom_kb' => (bool) $kbSources['custom']], now()->addYears(5));
    }
    if (array_key_exists('courses', $kbSources)) {
        cache(['ai_use_course_kb' => (bool) $kbSources['courses']], now()->addYears(5));
    }
    if (array_key_exists('Consultant', $tierAllow)) {
        cache(['ai_allow_consultant' => (bool) $tierAllow['Consultant']], now()->addYears(5));
    }
    if (array_key_exists('Rainmaker', $tierAllow)) {
        cache(['ai_allow_rainmaker' => (bool) $tierAllow['Rainmaker']], now()->addYears(5));
    }
    if (array_key_exists('Titan', $tierAllow)) {
        cache(['ai_allow_titan' => (bool) $tierAllow['Titan']], now()->addYears(5));
    }

    return response()->json([
        'success' => true,
        'message' => 'AI inbox settings updated.',
        'data' => [
            'provider' => $provider,
            'model' => $model,
            'base_url' => $baseUrl,
            'has_api_key' => $apiKey !== '',
            'knowledge_base' => $knowledgeBase,
            'kb_blocks' => json_decode((string) cache('ai_kb_blocks', '[]'), true) ?: [],
            'behavior' => (string) cache('ai_behavior_instructions', ''),
            'kb_sources' => [
                'custom' => (bool) cache('ai_use_custom_kb', true),
                'courses' => (bool) cache('ai_use_course_kb', true),
            ],
            'tier_allow' => [
                'Consultant' => (bool) cache('ai_allow_consultant', true),
                'Rainmaker' => (bool) cache('ai_allow_rainmaker', true),
                'Titan' => (bool) cache('ai_allow_titan', true),
            ],
        ],
    ]);
});

Route::post('/admin/ai/settings/knowledge-base-pdf', function (Request $request) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $validated = $request->validate([
        'pdf' => 'required|file|mimetypes:application/pdf|max:10240',
        'mode' => 'nullable|string|in:append,replace',
        'title' => 'nullable|string|max:120',
    ]);

    $mode = (string) ($validated['mode'] ?? 'append');
    $file = $request->file('pdf');
    if (! $file) {
        return response()->json(['success' => false, 'message' => 'Missing file'], 422);
    }

    try {
        $parser = new \Smalot\PdfParser\Parser();
        $pdf = $parser->parseFile($file->getRealPath());
        $text = trim((string) $pdf->getText());
        $text = preg_replace('/[ \t]+/', ' ', $text);
        $text = preg_replace("/\n{3,}/", "\n\n", $text);
        $text = trim((string) $text);
    } catch (\Throwable $e) {
        \Illuminate\Support\Facades\Log::error('KB PDF parse failed', ['error' => $e->getMessage()]);
        return response()->json(['success' => false, 'message' => 'Could not parse PDF.'], 422);
    }

    if ($text === '') {
        return response()->json(['success' => false, 'message' => 'PDF text was empty.'], 422);
    }

    // Safety cap: keep KB within route validation limit.
    $text = mb_substr($text, 0, 160000);
    $filename = (string) ($file->getClientOriginalName() ?: 'knowledge.pdf');
    $title = trim((string) ($validated['title'] ?? ''));
    if ($title === '') {
        $title = $filename;
    }
    $block = "PDF KB Source: {$filename}\n\n".$text;

    $existing = trim((string) cache('ai_custom_knowledge_base', ''));
    $next = $mode === 'replace' ? $block : trim($existing."\n\n---\n\n".$block);
    if (mb_strlen($next) > 200000) {
        $next = mb_substr($next, 0, 200000);
    }

    cache(['ai_custom_knowledge_base' => $next], now()->addYears(5));

    // Also store as a separate KB block so admin can manage many datasets.
    $kbBlocksRaw = (string) cache('ai_kb_blocks', '[]');
    $kbBlocks = json_decode($kbBlocksRaw, true);
    if (! is_array($kbBlocks)) {
        $kbBlocks = [];
    }
    if ($mode === 'replace') {
        $kbBlocks = [];
    }
    $kbBlocks[] = [
        'id' => (string) \Illuminate\Support\Str::uuid(),
        'title' => mb_substr($title, 0, 120),
        'content' => mb_substr($block, 0, 200000),
        'enabled' => true,
    ];
    cache(['ai_kb_blocks' => json_encode($kbBlocks)], now()->addYears(5));

    return response()->json([
        'success' => true,
        'message' => 'Knowledge base updated from PDF.',
        'data' => [
            'knowledge_base' => $next,
            'kb_blocks' => $kbBlocks,
        ],
    ]);
});

Route::post('/admin/ai/settings/kb-block/{blockId}/pdf', function (Request $request, string $blockId) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $validated = $request->validate([
        'pdf' => 'required|file|mimetypes:application/pdf|max:10240',
        'title' => 'nullable|string|max:120',
    ]);

    $file = $request->file('pdf');
    if (! $file) {
        return response()->json(['success' => false, 'message' => 'Missing file'], 422);
    }

    try {
        $parser = new \Smalot\PdfParser\Parser();
        $pdf = $parser->parseFile($file->getRealPath());
        $text = trim((string) $pdf->getText());
        $text = preg_replace('/[ \t]+/', ' ', $text);
        $text = preg_replace("/\n{3,}/", "\n\n", $text);
        $text = trim((string) $text);
    } catch (\Throwable $e) {
        \Illuminate\Support\Facades\Log::error('KB block PDF parse failed', ['error' => $e->getMessage()]);
        return response()->json(['success' => false, 'message' => 'Could not parse PDF.'], 422);
    }

    if ($text === '') {
        return response()->json(['success' => false, 'message' => 'PDF text was empty.'], 422);
    }

    $text = mb_substr($text, 0, 160000);
    $filename = (string) ($file->getClientOriginalName() ?: 'knowledge.pdf');
    $title = trim((string) ($validated['title'] ?? ''));
    if ($title === '') {
        $title = $filename;
    }
    $blockContent = "PDF KB Source: {$filename}\n\n".$text;

    $kbBlocksRaw = (string) cache('ai_kb_blocks', '[]');
    $kbBlocks = json_decode($kbBlocksRaw, true);
    if (! is_array($kbBlocks)) {
        $kbBlocks = [];
    }

    $found = false;
    foreach ($kbBlocks as &$b) {
        if (! is_array($b)) continue;
        if ((string) ($b['id'] ?? '') !== $blockId) continue;
        $b['title'] = mb_substr($title, 0, 120);
        $b['content'] = mb_substr($blockContent, 0, 200000);
        $b['enabled'] = (bool) ($b['enabled'] ?? true);
        $found = true;
        break;
    }
    unset($b);

    if (! $found) {
        return response()->json(['success' => false, 'message' => 'Dataset not found'], 404);
    }

    cache(['ai_kb_blocks' => json_encode($kbBlocks)], now()->addYears(5));

    return response()->json([
        'success' => true,
        'message' => 'Dataset updated from PDF.',
        'data' => [
            'kb_blocks' => $kbBlocks,
        ],
    ]);
});

Route::delete('/admin/ai/settings/kb-block/{blockId}', function (Request $request, string $blockId) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $kbBlocksRaw = (string) cache('ai_kb_blocks', '[]');
    $kbBlocks = json_decode($kbBlocksRaw, true);
    if (! is_array($kbBlocks)) {
        $kbBlocks = [];
    }

    $before = count($kbBlocks);
    $kbBlocks = array_values(array_filter($kbBlocks, fn ($b) => ! (is_array($b) && (string) ($b['id'] ?? '') === $blockId)));
    $after = count($kbBlocks);

    if ($after === $before) {
        return response()->json(['success' => false, 'message' => 'Dataset not found'], 404);
    }

    cache(['ai_kb_blocks' => json_encode($kbBlocks)], now()->addYears(5));

    return response()->json([
        'success' => true,
        'message' => 'Dataset deleted.',
        'data' => [
            'kb_blocks' => $kbBlocks,
        ],
    ]);
});

Route::get('/admin/ai/users/{userId}/sessions', function (Request $request, int $userId) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $sessions = \App\Models\ChatSession::query()
        ->where('user_id', $userId)
        ->orderByDesc('updated_at')
        ->limit(100)
        ->get(['id', 'title', 'created_at', 'updated_at']);

    return response()->json(['success' => true, 'data' => $sessions]);
});

Route::get('/admin/ai/users/{userId}/usage', function (Request $request, int $userId) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $todayStart = now()->startOfDay();

    $todayAgg = DB::table('chat_messages')
        ->join('chat_sessions', 'chat_sessions.id', '=', 'chat_messages.chat_session_id')
        ->where('chat_sessions.user_id', $userId)
        ->where('chat_messages.role', 'assistant')
        ->where('chat_messages.created_at', '>=', $todayStart)
        ->selectRaw('COALESCE(SUM(chat_messages.total_tokens), 0) as total_tokens, COUNT(*) as ai_calls')
        ->first();

    $totalAgg = DB::table('chat_messages')
        ->join('chat_sessions', 'chat_sessions.id', '=', 'chat_messages.chat_session_id')
        ->where('chat_sessions.user_id', $userId)
        ->where('chat_messages.role', 'assistant')
        ->selectRaw('COALESCE(SUM(chat_messages.total_tokens), 0) as total_tokens, COUNT(*) as ai_calls')
        ->first();

    return response()->json([
        'success' => true,
        'data' => [
            'ai_tokens_today' => (int) ($todayAgg->total_tokens ?? 0),
            'ai_calls_today' => (int) ($todayAgg->ai_calls ?? 0),
            'ai_tokens_total' => (int) ($totalAgg->total_tokens ?? 0),
            'ai_calls_total' => (int) ($totalAgg->ai_calls ?? 0),
        ],
    ]);
});

Route::get('/admin/ai/sessions/{sessionId}/messages', function (Request $request, int $sessionId) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $messages = \App\Models\ChatMessage::query()
        ->where('chat_session_id', $sessionId)
        ->orderBy('id')
        ->get(['id', 'role', 'content', 'prompt_tokens', 'completion_tokens', 'total_tokens', 'model', 'created_at']);

    return response()->json(['success' => true, 'data' => $messages]);
});

// Admin: send a message as a user (for testing / replying from the center panel)
Route::post('/admin/ai/users/{userId}/send', [\App\Http\Controllers\ChatController::class, 'adminSendForUser']);

// Admin: enabled AI KB courses for a user (based on user's membership tier)
Route::get('/admin/ai/users/{userId}/kb', function (Request $request, int $userId) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $user = \App\Models\User::query()->find($userId);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'User not found'], 404);
    }

    $tier = $user->membership_tier ?: 'Consultant';

    $courses = \App\Models\Course::query()
        ->whereIn('id', function ($q) use ($tier) {
            $q->select('course_id')
                ->from('ai_course_knowledge_base')
                ->where('tier', $tier)
                ->where('is_enabled', true);
        })
        ->orderBy('module_number')
        ->orderBy('sequence')
        ->get(['id', 'title', 'description', 'module_number', 'sequence']);

    return response()->json(['success' => true, 'data' => ['tier' => $tier, 'courses' => $courses]]);
});

// Admin: human handoff tickets
Route::post('/admin/ai/tickets', function (Request $request) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $validated = $request->validate([
        'user_id' => 'required|integer|exists:users,id',
        'chat_session_id' => 'nullable|integer|exists:chat_sessions,id',
        'request_message' => 'required|string|max:4000',
    ]);

    $ticket = \App\Models\AiHumanTicket::query()->create([
        'user_id' => $validated['user_id'],
        'chat_session_id' => $validated['chat_session_id'] ?? null,
        'request_message' => $validated['request_message'],
        'status' => 'open',
    ]);

    return response()->json(['success' => true, 'data' => $ticket]);
});

Route::get('/admin/ai/tickets', function (Request $request) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $tickets = \App\Models\AiHumanTicket::query()
        ->orderByDesc('created_at')
        ->limit(200)
        ->get();

    return response()->json(['success' => true, 'data' => $tickets]);
});

Route::post('/admin/ai/tickets/{ticketId}/resolve', function (Request $request, int $ticketId) {
    $admin = getAuthUser($request);
    if (! $admin || $admin->email !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $validated = $request->validate([
        'admin_resolution' => 'required|string|max:4000',
    ]);

    $ticket = \App\Models\AiHumanTicket::query()->find($ticketId);
    if (! $ticket) {
        return response()->json(['success' => false, 'message' => 'Ticket not found'], 404);
    }

    $ticket->admin_resolution = $validated['admin_resolution'];
    $ticket->status = 'resolved';
    $ticket->resolved_at = \Illuminate\Support\Carbon::now();
    $ticket->save();

    return response()->json(['success' => true, 'data' => $ticket]);
});

Route::get('/admin/stats', function () {
    try {
        $userCount = \App\Models\User::count();
        // Check activities table safely
        $activityCount = 0;
        $activeToday = 0;
        try {
            $activityCount = \Illuminate\Support\Facades\DB::table('activities')->count();
            $activeToday = \Illuminate\Support\Facades\DB::table('activities')->whereDate('created_at', now()->toDateString())->count();
        } catch (\Throwable $e) {
        }

        $pendingDeletion = 0;
        try {
            $pendingDeletion = \App\Models\User::whereNotNull('deletion_requested_at')->count();
        } catch (\Throwable $e) {
        }

        return response()->json([
            'total_users' => $userCount,
            'active_today' => $activeToday,
            'total_activities' => $activityCount,
            'db_connected' => true,
            'pending_deletion_requests' => $pendingDeletion,
        ]);
    } catch (\Throwable $e) {
        return response()->json([
            'total_users' => 0,
            'total_activities' => 0,
            'db_connected' => false,
            'pending_deletion_requests' => 0,
            'error' => $e->getMessage(),
        ]);
    }
});

Route::get('/admin/users', function () {
    $users = \App\Models\User::orderBy('created_at', 'desc')->get();

    // Attach momentum data to each user
    $today = now()->toDateString();
    $users->each(function ($user) use ($today) {
        $metric = \App\Models\PerformanceMetric::where('user_id', $user->id)
            ->where('date', $today)
            ->first();

        $user->daily_score = $metric ? $metric->total_momentum_score : 0;
        $user->today_subconscious = $metric ? $metric->subconscious_score : 0;
        $user->today_conscious = $metric ? $metric->conscious_score : 0;

        // Rank badge based on streak
        $streak = $user->current_streak ?? 0;
        if ($streak >= 30) {
            $user->momentum_badge = 'Market Operator';
            $user->badge_color = '#f59e0b';
        } elseif ($streak >= 14) {
            $user->momentum_badge = 'Momentum Builder';
            $user->badge_color = '#6d28d9';
        } elseif ($streak >= 7) {
            $user->momentum_badge = 'Rising Agent';
            $user->badge_color = '#10b981';
        } elseif ($streak >= 3) {
            $user->momentum_badge = 'Getting Started';
            $user->badge_color = '#3b82f6';
        } else {
            $user->momentum_badge = 'Inactive';
            $user->badge_color = '#6b7280';
        }
    });

    return response()->json($users);
});

Route::post('/admin/users/{id}/toggle-status', function ($id) {
    $user = \App\Models\User::findOrFail($id);
    $newStatus = ($user->status === 'inactive') ? 'active' : 'inactive';
    $user->status = $newStatus;
    if ($newStatus === 'active') {
        $user->deletion_requested_at = null;
    }
    $user->save();

    return response()->json(['status' => 'ok', 'new_status' => $user->status]);
});

Route::get('/admin/users/{id}/performance', function ($id) {
    $metrics = \App\Models\PerformanceMetric::where('user_id', $id)
        ->orderBy('date', 'desc')
        ->limit(60) // Increased limit to support monthly/weekly views
        ->get();

    return response()->json(['success' => true, 'data' => $metrics]);
});

Route::get('/admin/users/{id}/activities', function ($id) {
    $activities = \App\Models\Activity::where('user_id', $id)
        ->orderBy('scheduled_at', 'desc')
        ->limit(150)
        ->get();

    return response()->json(['success' => true, 'data' => $activities]);
});

Route::delete('/admin/users/{id}', function ($id) {
    $user = \App\Models\User::findOrFail($id);
    $user->delete();

    return response()->json(['status' => 'ok']);
});

// Admin: Revenue metrics for a specific user (Key Metrics - Hot Leads, Deals Closed, Commission, Top Source)
Route::get('/admin/users/{id}/revenue-metrics', function ($id) {
    $user = \App\Models\User::findOrFail($id);

    $hotLeads = \App\Models\Result::where('user_id', $user->id)
        ->where('type', 'hot_lead')
        ->whereNotNull('client_name')
        ->count();

    $dealsClosed = \App\Models\Result::where('user_id', $user->id)
        ->where('type', 'deal_closed')
        ->count();

    $commissionFromDeals = \App\Models\Result::where('user_id', $user->id)
        ->where('type', 'deal_closed')
        ->get()
        ->sum(function ($r) {
            $notes = is_string($r->notes) ? json_decode($r->notes, true) : $r->notes;

            return is_array($notes) ? (float) ($notes['commission'] ?? 0) : 0;
        });
    $commissionFromType = (float) \App\Models\Result::where('user_id', $user->id)
        ->where('type', 'commission')
        ->sum('value');
    $totalCommission = $commissionFromDeals + $commissionFromType;

    $topSourceRow = \App\Models\Result::where('user_id', $user->id)
        ->where('type', 'hot_lead')
        ->whereNotNull('source')
        ->where('source', '!=', '')
        ->selectRaw('source, COUNT(*) as cnt')
        ->groupBy('source')
        ->orderByDesc('cnt')
        ->first();
    $topSource = $topSourceRow ? $topSourceRow->source : null;

    $recentActivity = \App\Models\Result::where('user_id', $user->id)
        ->orderByDesc('created_at')
        ->limit(10)
        ->get(['id', 'type', 'client_name', 'value', 'source', 'date', 'created_at', 'notes']);

    return response()->json([
        'success' => true,
        'data' => [
            'hot_leads' => $hotLeads,
            'deals_closed' => $dealsClosed,
            'total_commission' => $totalCommission,
            'top_source' => $topSource,
            'recent_activity' => $recentActivity,
        ],
    ]);
});

/** Admin: upload Deal Room–format .xlsx for a practitioner’s account (hot_lead upserts). */
Route::post('/admin/users/{userId}/import-excel', function (Request $request, $userId) {
    $auth = getAuthUser($request);
    if (! $auth) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }
    if (strtolower((string) $auth->email) !== 'admin@realtorone.com') {
        return response()->json(['success' => false, 'message' => 'Admin access required'], 403);
    }

    $target = User::findOrFail((int) $userId);

    $request->validate([
        'file' => ['required', 'file', 'max:15360'],
    ]);

    $file = $request->file('file');
    $ext = strtolower($file->getClientOriginalExtension() ?? '');
    if ($ext !== 'xlsx') {
        return response()->json(['success' => false, 'message' => 'Please upload an Excel .xlsx file.'], 422);
    }

    $path = $file->getRealPath();
    if (! $path || ! is_readable($path)) {
        return response()->json(['success' => false, 'message' => 'Could not read the uploaded file.'], 422);
    }

    try {
        $stats = \App\Support\DealRoomExcelImport::importFromFilePath($target->id, $path);
    } catch (\Throwable $e) {
        Log::error('admin/users/import-excel failed', [
            'admin_id' => $auth->id,
            'target_user_id' => $target->id,
            'error' => $e->getMessage(),
        ]);

        return response()->json([
            'success' => false,
            'message' => 'Could not read this spreadsheet. Use the Deal Room template and try again.',
        ], 422);
    }

    $msg = sprintf(
        'Added %d client(s), updated %d for %s.',
        $stats['created'],
        $stats['updated'],
        $target->name ?? ('user #'.$target->id)
    );
    if ($stats['skipped'] > 0) {
        $msg .= sprintf(' Skipped %d row(s) with no name.', $stats['skipped']);
    }
    $msg = \App\Support\DealRoomExcelImport::appendNoRowsHint($msg, $stats);

    return response()->json([
        'success' => true,
        'message' => $msg,
        'created' => $stats['created'],
        'updated' => $stats['updated'],
        'skipped' => $stats['skipped'],
    ]);
});

// Admin: Results list for a user (Hot Leads, Deals Closed, filtered by source)
Route::get('/admin/users/{id}/results', function (Request $request, $id) {
    $user = \App\Models\User::findOrFail($id);

    $query = \App\Models\Result::where('user_id', $user->id);

    if ($request->has('type')) {
        $query->where('type', $request->type);
    }
    if ($request->has('source') && $request->query('type') === 'hot_lead') {
        $query->where('source', $request->source);
    }

    $results = $query->orderByDesc('date')->orderByDesc('created_at')->get();

    return response()->json(['success' => true, 'data' => $results]);
});

// Subscription Packages
Route::get('/admin/packages', function () {
    return response()->json(['success' => true, 'data' => \App\Models\SubscriptionPackage::orderBy('tier_level', 'asc')->get()]);
});

Route::post('/admin/packages', function (Request $request) {
    $data = $request->validate([
        'name' => 'required|string',
        'tier_level' => 'required|integer',
        'price_monthly' => 'required|numeric',
        'description' => 'nullable|string',
        'features' => 'nullable|array',
    ]);
    $package = \App\Models\SubscriptionPackage::create($data);

    return response()->json(['success' => true, 'data' => $package]);
});

Route::put('/admin/packages/{id}', function (Request $request, $id) {
    $package = \App\Models\SubscriptionPackage::findOrFail($id);
    $data = $request->validate([
        'name' => 'sometimes|string',
        'tier_level' => 'sometimes|integer',
        'price_monthly' => 'sometimes|numeric',
        'description' => 'nullable|string',
        'features' => 'nullable|array',
        'is_active' => 'sometimes|boolean',
    ]);
    $package->update($data);

    return response()->json(['success' => true, 'data' => $package]);
});

Route::delete('/admin/packages/{id}', function ($id) {
    $package = \App\Models\SubscriptionPackage::findOrFail($id);
    $package->delete();

    return response()->json(['success' => true]);
});

// User Subscriptions (History & Active)
Route::get('/admin/subscriptions', function () {
    $subs = \App\Models\UserSubscription::with(['user', 'package', 'coupon'])
        ->orderBy('created_at', 'desc')
        ->get();

    return response()->json(['success' => true, 'data' => $subs]);
});

// Coupons Management
Route::get('/admin/coupons', function () {
    return response()->json(['success' => true, 'data' => \App\Models\Coupon::orderBy('created_at', 'desc')->get()]);
});

Route::post('/admin/coupons', function (Request $request) {
    $data = $request->validate([
        'code' => 'required|string|unique:coupons,code',
        'discount_percentage' => 'required|integer|min:1|max:100',
        'expires_at' => 'nullable|date',
        'max_uses' => 'nullable|integer|min:1',
    ]);
    $coupon = \App\Models\Coupon::create($data);

    return response()->json(['success' => true, 'data' => $coupon]);
});

Route::delete('/admin/coupons/{id}', function ($id) {
    $coupon = \App\Models\Coupon::findOrFail($id);
    $coupon->delete();

    return response()->json(['success' => true]);
});

// Courses Management
// Upload route MUST come before resource route to avoid 'upload' being matched as a course ID
Route::post('admin/courses/upload', [\App\Http\Controllers\CourseController::class, 'uploadFile']);
Route::get('admin/system/backup', [\App\Http\Controllers\BackupController::class, 'export']);
Route::post('admin/system/restore', [\App\Http\Controllers\BackupController::class, 'import']);
Route::resource('admin/courses', \App\Http\Controllers\CourseController::class);
Route::post('admin/courses/{id}/modules', [\App\Http\Controllers\CourseController::class, 'storeModule']);
Route::put('admin/modules/{id}', [\App\Http\Controllers\CourseController::class, 'updateModule']);
Route::delete('admin/modules/{id}', [\App\Http\Controllers\CourseController::class, 'destroyModule']);

Route::post('admin/modules/{id}/lessons', [\App\Http\Controllers\CourseController::class, 'storeLesson']);
Route::put('admin/lessons/{id}', [\App\Http\Controllers\CourseController::class, 'updateLesson']);
Route::delete('admin/lessons/{id}', [\App\Http\Controllers\CourseController::class, 'destroyLesson']);

Route::post('admin/lessons/{id}/materials', [\App\Http\Controllers\CourseController::class, 'storeMaterial']);
Route::put('admin/materials/{id}', [\App\Http\Controllers\CourseController::class, 'updateMaterial']);
Route::delete('admin/materials/{id}', [\App\Http\Controllers\CourseController::class, 'destroyMaterial']);

// AI Knowledge Base visibility per course + tier (admin)
Route::get('admin/courses/{id}/ai-visibility', function ($id) {
    $tiers = ['Consultant', 'Rainmaker', 'Titan'];

    $rows = \App\Models\AiCourseKnowledgeBase::query()
        ->where('course_id', $id)
        ->get(['tier', 'is_enabled'])
        ->keyBy('tier');

    $data = [];
    foreach ($tiers as $tier) {
        $row = $rows->get($tier);
        $data[$tier] = $row ? (bool) $row->is_enabled : false;
    }

    return response()->json(['success' => true, 'data' => $data]);
});

Route::post('admin/courses/{id}/ai-visibility', function (Request $request, $id) {
    $validated = $request->validate([
        'tiers' => 'required|array',
        'tiers.Consultant' => 'required|boolean',
        'tiers.Rainmaker' => 'required|boolean',
        'tiers.Titan' => 'required|boolean',
    ]);

    $tiers = ['Consultant', 'Rainmaker', 'Titan'];

    foreach ($tiers as $tier) {
        \App\Models\AiCourseKnowledgeBase::query()->updateOrCreate(
            ['course_id' => $id, 'tier' => $tier],
            ['is_enabled' => (bool) ($validated['tiers'][$tier] ?? false)]
        );
    }

    return response()->json(['success' => true]);
});

Route::get('/admin/notifications', [NotificationBroadcastController::class, 'index']);
Route::post('/admin/notifications', [NotificationBroadcastController::class, 'store']);
Route::post('/admin/notifications/{id}/cancel', [NotificationBroadcastController::class, 'cancel']);
Route::post('/admin/notifications/{id}/send-now', [NotificationBroadcastController::class, 'sendNow']);

// Video streaming with range request support (required for HTML5 video playback)
Route::get('stream/{filename}', function (Request $request, $filename) {
    $path = storage_path('app/public/course-assets/'.$filename);

    if (! file_exists($path)) {
        return response()->json(['error' => 'File not found'], 404);
    }

    $mimeType = mime_content_type($path);
    $fileSize = filesize($path);
    $start = 0;
    $end = $fileSize - 1;
    $statusCode = 200;

    $headers = [
        'Content-Type' => $mimeType,
        'Accept-Ranges' => 'bytes',
        'Access-Control-Allow-Origin' => '*',
        'Cache-Control' => 'public, max-age=86400',
        'Content-Disposition' => 'inline',
    ];

    if ($request->hasHeader('Range')) {
        $range = $request->header('Range');
        preg_match('/bytes=(\d*)-(\d*)/', $range, $matches);
        $start = $matches[1] !== '' ? (int) $matches[1] : 0;
        $end = $matches[2] !== '' ? (int) $matches[2] : $fileSize - 1;
        $end = min($end, $fileSize - 1);
        $headers['Content-Range'] = "bytes {$start}-{$end}/{$fileSize}";
        $statusCode = 206;
    }

    $length = $end - $start + 1;
    $headers['Content-Length'] = $length;

    return response()->stream(function () use ($path, $start, $length) {
        $handle = fopen($path, 'rb');
        fseek($handle, $start);
        $remaining = $length;
        while (! feof($handle) && $remaining > 0) {
            $chunk = min(1024 * 256, $remaining); // 256KB chunks
            echo fread($handle, $chunk);
            $remaining -= $chunk;
            flush();
        }
        fclose($handle);
    }, $statusCode, $headers);
});

// User-facing Courses List
Route::get('/courses', function (Request $request) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    // Get current active subscription to determine tier rank
    $sub = \App\Models\UserSubscription::with('package')
        ->where('user_id', $user->id)
        ->where('status', 'active')
        ->where('expires_at', '>', now())
        ->orderBy('expires_at', 'desc')
        ->first();

    $userTierName = $sub ? $sub->package->name : 'Consultant';

    // Mission Tier Hierarchy
    $tierRanks = [
        'consultant' => 0,
        'rainmaker' => 1,
        'titan' => 2,
    ];

    $userTierKey = strtolower($userTierName);
    $currentRank = $tierRanks[$userTierKey] ?? 0;

    // Get user's course progress
    $userProgress = DB::table('course_progress')
        ->where('user_id', $user->id)
        ->get()
        ->keyBy('course_id');

    // Get all courses ordered by module and sequence
    $allCourses = \App\Models\Course::orderBy('module_number')
        ->orderBy('sequence')
        ->get();

    // Group courses by module
    $modules = [];
    $moduleTierRequirements = [
        1 => 'consultant',  // Module 1: All tiers
        2 => 'rainmaker',   // Module 2: Rainmaker+
        3 => 'titan',        // Module 3: Titan only
    ];

    foreach ($allCourses as $course) {
        $moduleNum = $course->module_number ?? 1;
        $courseRank = $tierRanks[strtolower($course->min_tier)] ?? 0;

        // Check if module is accessible based on tier
        $moduleRequiredTier = $moduleTierRequirements[$moduleNum] ?? 'consultant';
        $moduleRequiredRank = $tierRanks[$moduleRequiredTier] ?? 0;
        $isModuleLocked = $currentRank < $moduleRequiredRank;

        // Check if previous module is completed (for sequential unlocking)
        $isSequentiallyLocked = false;
        if ($moduleNum > 1) {
            $prevModuleNum = $moduleNum - 1;
            $prevModuleCourses = $allCourses->where('module_number', $prevModuleNum);
            $prevModuleCompleted = $prevModuleCourses->every(function ($prevCourse) use ($userProgress) {
                $progress = $userProgress->get($prevCourse->id);

                return $progress && $progress->is_completed;
            });
            $isSequentiallyLocked = ! $prevModuleCompleted && $prevModuleCourses->isNotEmpty();
        }

        // Course is locked if: tier locked OR module locked OR sequentially locked
        $isLocked = ($courseRank > $currentRank) || $isModuleLocked || $isSequentiallyLocked;

        $progress = $userProgress->get($course->id);

        if (! isset($modules[$moduleNum])) {
            $modules[$moduleNum] = [
                'module_number' => $moduleNum,
                'module_name' => "Module $moduleNum",
                'is_locked' => $isModuleLocked || $isSequentiallyLocked,
                'required_tier' => ucfirst($moduleRequiredTier),
                'courses' => [],
            ];
        }

        $modules[$moduleNum]['courses'][] = [
            'id' => $course->id,
            'title' => $course->title,
            'description' => $course->description,
            'thumbnail_url' => $course->thumbnail_url ? url('storage/'.str_replace('course-assets/', '', $course->thumbnail_url)) : null,
            'url' => $course->url,
            'min_tier' => $course->min_tier,
            'module_number' => $moduleNum,
            'sequence' => $course->sequence ?? 0,
            'is_locked' => $isLocked,
            'progress_percent' => $progress ? $progress->progress_percent : 0,
            'is_completed' => $progress ? (bool) $progress->is_completed : false,
        ];
    }

    // Convert to indexed array
    $modulesArray = array_values($modules);

    return response()->json([
        'success' => true,
        'data' => $modulesArray,
        'user_tier' => $userTierName,
    ]);
});

// User-facing Course Details (Curriculum)
Route::get('/courses/{id}', function (Request $request, $id) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $course = \App\Models\Course::with([
        'modules.lessons.materials' => function ($query) {
            $query
                ->orderByRaw("CASE WHEN LOWER(type) = 'video' THEN 0 WHEN LOWER(type) = 'pdf' THEN 1 ELSE 2 END")
                ->orderBy('id');
        },
    ])->findOrFail($id);

    // Check if user has access to this course
    $sub = \App\Models\UserSubscription::with('package')
        ->where('user_id', $user->id)
        ->where('status', 'active')
        ->where('expires_at', '>', now())
        ->orderBy('expires_at', 'desc')
        ->first();

    $userTierName = $sub ? $sub->package->name : 'Consultant';
    $tierRanks = ['consultant' => 0, 'rainmaker' => 1, 'titan' => 2];
    $currentRank = $tierRanks[strtolower($userTierName)] ?? 0;
    $courseRank = $tierRanks[strtolower($course->min_tier)] ?? 0;

    if ($courseRank > $currentRank) {
        return response()->json(['success' => false, 'message' => 'Tier upgrade required', 'required_tier' => $course->min_tier], 403);
    }

    // Attach user progress for materials
    $materialProgress = DB::table('course_material_progress')
        ->where('user_id', $user->id)
        ->get()
        ->keyBy('material_id');

    $course->modules->each(function ($module) use ($materialProgress) {
        $module->lessons->each(function ($lesson) use ($materialProgress) {
            $lesson->materials->each(function ($material) use ($materialProgress) {
                $progress = $materialProgress->get($material->id);
                $material->is_completed = $progress ? (bool) $progress->is_completed : false;
                $material->progress_seconds = $progress ? $progress->progress_seconds : 0;
                $material->completed_at = $progress ? $progress->completed_at : null;
            });
        });
    });

    return response()->json([
        'success' => true,
        'data' => $course,
    ]);
});

// Update course progress
Route::post('/courses/{id}/progress', function (Request $request, $id) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $validated = $request->validate([
        'progress_percent' => 'required|integer|min:0|max:100',
        'is_completed' => 'nullable|boolean',
    ]);

    $progress = DB::table('course_progress')
        ->updateOrInsert(
            ['user_id' => $user->id, 'course_id' => $id],
            [
                'progress_percent' => $validated['progress_percent'],
                'is_completed' => $validated['is_completed'] ?? ($validated['progress_percent'] >= 100),
                'completed_at' => ($validated['is_completed'] ?? ($validated['progress_percent'] >= 100)) ? now() : null,
                'last_accessed_at' => now(),
                'updated_at' => now(),
                'created_at' => DB::raw('COALESCE(created_at, NOW())'),
            ]
        );

    return response()->json(['success' => true, 'message' => 'Progress updated']);
});

// Update material progress
Route::post('/courses/materials/{id}/progress', function (Request $request, $id) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $validated = $request->validate([
        'is_completed' => 'nullable|boolean',
        'progress_seconds' => 'nullable|integer',
    ]);

    $data = ['updated_at' => now()];
    if ($request->has('is_completed')) {
        $data['is_completed'] = $validated['is_completed'];
        $data['completed_at'] = $validated['is_completed'] ? now() : null;
    }
    if ($request->has('progress_seconds')) {
        $data['progress_seconds'] = $validated['progress_seconds'];
    }

    DB::table('course_material_progress')->updateOrInsert(
        ['user_id' => $user->id, 'material_id' => $id],
        array_merge($data, ['created_at' => DB::raw('COALESCE(created_at, NOW())')])
    );

    return response()->json(['success' => true, 'message' => 'Material progress updated']);
});

// --- Course exam (available after course completion) ---
Route::get('/courses/{id}/exam', function (Request $request, $id) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $courseId = (int) $id;
    $progress = DB::table('course_progress')->where('user_id', $user->id)->where('course_id', $courseId)->first();
    if (! $progress || ! $progress->is_completed) {
        return response()->json(['success' => false, 'message' => 'Complete the course first to take the exam'], 403);
    }

    $exam = DB::table('course_exams')->where('course_id', $courseId)->where('is_active', true)->first();
    if (! $exam) {
        return response()->json(['success' => false, 'message' => 'No exam available for this course'], 404);
    }

    $recentAttempts = DB::table('course_exam_attempts')
        ->where('user_id', $user->id)
        ->where('course_exam_id', $exam->id)
        ->where('submitted_at', '>=', now()->subDays(30))
        ->count();
    if ($recentAttempts >= 2) {
        return response()->json(['success' => false, 'message' => 'You have reached the maximum of 2 exam attempts within 30 days. Try again later.'], 403);
    }

    $questions = DB::table('course_exam_questions')
        ->where('course_exam_id', $exam->id)
        ->orderBy('sequence')
        ->orderBy('id')
        ->get()
        ->map(function ($q) {
            return [
                'id' => $q->id,
                'question_text' => $q->question_text,
                'options' => json_decode($q->options, true),
            ];
        });

    return response()->json([
        'success' => true,
        'data' => [
            'exam_id' => $exam->id,
            'title' => $exam->title,
            'passing_percent' => (int) $exam->passing_percent,
            'time_minutes' => $exam->time_minutes ? (int) $exam->time_minutes : null,
            'questions' => $questions,
        ],
    ]);
});

Route::post('/courses/{id}/exam/submit', function (Request $request, $id) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $courseId = (int) $id;
    $progress = DB::table('course_progress')->where('user_id', $user->id)->where('course_id', $courseId)->first();
    if (! $progress || ! $progress->is_completed) {
        return response()->json(['success' => false, 'message' => 'Complete the course first'], 403);
    }

    $exam = DB::table('course_exams')->where('course_id', $courseId)->where('is_active', true)->first();
    if (! $exam) {
        return response()->json(['success' => false, 'message' => 'No exam available'], 404);
    }

    $recentAttempts = DB::table('course_exam_attempts')
        ->where('user_id', $user->id)
        ->where('course_exam_id', $exam->id)
        ->where('submitted_at', '>=', now()->subDays(30))
        ->count();
    if ($recentAttempts >= 2) {
        return response()->json(['success' => false, 'message' => 'You have reached the maximum of 2 exam attempts within 30 days. Try again later.'], 403);
    }

    $validated = $request->validate([
        'answers' => 'required|array',
        'answers.*.question_id' => 'required|integer',
        'answers.*.selected_index' => 'required|integer|min:0',
        'started_at' => 'nullable|string',
    ]);

    $questions = DB::table('course_exam_questions')->where('course_exam_id', $exam->id)->get()->keyBy('id');
    $correct = 0;
    foreach ($validated['answers'] as $a) {
        $q = $questions->get($a['question_id']);
        if ($q && (int) $q->correct_index === (int) $a['selected_index']) {
            $correct++;
        }
    }
    $total = $questions->count();
    $scorePercent = $total > 0 ? (int) round(($correct / $total) * 100) : 0;
    $passed = $scorePercent >= (int) $exam->passing_percent;

    $submittedAt = now();
    $startedAt = isset($validated['started_at'])
        ? \Carbon\Carbon::parse($validated['started_at']) : $submittedAt;
    DB::table('course_exam_attempts')->insert([
        'user_id' => $user->id,
        'course_exam_id' => $exam->id,
        'score_percent' => $scorePercent,
        'passed' => $passed,
        'answers' => json_encode($validated['answers']),
        'started_at' => $startedAt,
        'submitted_at' => $submittedAt,
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    return response()->json([
        'success' => true,
        'data' => [
            'score_percent' => $scorePercent,
            'passed' => $passed,
            'correct' => $correct,
            'total' => $total,
        ],
    ]);
});

// --- Admin: monitor user course progress and exam results ---
Route::get('/admin/course-results', function (Request $request) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false], 401);
    }
    // Optional: add admin role check here

    $courseProgress = DB::table('course_progress')
        ->join('users', 'users.id', '=', 'course_progress.user_id')
        ->join('courses', 'courses.id', '=', 'course_progress.course_id')
        ->select(
            'course_progress.id',
            'course_progress.user_id',
            'users.name as user_name',
            'users.email as user_email',
            'course_progress.course_id',
            'courses.title as course_title',
            'course_progress.progress_percent',
            'course_progress.is_completed',
            'course_progress.completed_at',
            'course_progress.last_accessed_at'
        )
        ->orderBy('course_progress.updated_at', 'desc')
        ->get();

    $attempts = DB::table('course_exam_attempts')
        ->join('users', 'users.id', '=', 'course_exam_attempts.user_id')
        ->join('course_exams', 'course_exams.id', '=', 'course_exam_attempts.course_exam_id')
        ->join('courses', 'courses.id', '=', 'course_exams.course_id')
        ->select(
            'course_exam_attempts.id',
            'course_exam_attempts.user_id',
            'users.name as user_name',
            'users.email as user_email',
            'courses.id as course_id',
            'courses.title as course_title',
            'course_exam_attempts.score_percent',
            'course_exam_attempts.passed',
            'course_exam_attempts.submitted_at'
        )
        ->orderBy('course_exam_attempts.submitted_at', 'desc')
        ->get();

    return response()->json([
        'success' => true,
        'data' => [
            'course_progress' => $courseProgress,
            'exam_attempts' => $attempts,
        ],
    ]);
});

// Admin: get course exam and questions
Route::get('/admin/courses/{id}/exam', function (Request $request, $id) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false], 401);
    }

    $exam = DB::table('course_exams')->where('course_id', (int) $id)->first();
    if (! $exam) {
        return response()->json(['success' => true, 'data' => null]);
    }

    $questions = DB::table('course_exam_questions')
        ->where('course_exam_id', $exam->id)
        ->orderBy('sequence')
        ->orderBy('id')
        ->get()
        ->map(function ($q) {
            return [
                'id' => $q->id,
                'question_text' => $q->question_text,
                'options' => is_string($q->options) ? json_decode($q->options, true) : $q->options,
                'correct_index' => (int) $q->correct_index,
                'sequence' => (int) $q->sequence,
            ];
        });

    return response()->json([
        'success' => true,
        'data' => [
            'id' => $exam->id,
            'title' => $exam->title,
            'passing_percent' => (int) $exam->passing_percent,
            'time_minutes' => $exam->time_minutes ? (int) $exam->time_minutes : null,
            'questions' => $questions,
        ],
    ]);
});

// Admin: create course exam
Route::post('/admin/courses/{id}/exam', function (Request $request, $id) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false], 401);
    }

    $validated = $request->validate([
        'title' => 'required|string',
        'passing_percent' => 'nullable|integer|min:0|max:100',
        'time_minutes' => 'nullable|integer|min:1',
    ]);

    $examId = DB::table('course_exams')->insertGetId([
        'course_id' => (int) $id,
        'title' => $validated['title'],
        'passing_percent' => $validated['passing_percent'] ?? 70,
        'time_minutes' => $validated['time_minutes'] ?? null,
        'is_active' => true,
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    return response()->json(['success' => true, 'data' => ['id' => $examId]]);
});

Route::post('/admin/exams/{examId}/questions', function (Request $request, $examId) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false], 401);
    }

    $validated = $request->validate([
        'question_text' => 'required|string',
        'options' => 'required|array',
        'options.*' => 'string',
        'correct_index' => 'required|integer|min:0',
        'sequence' => 'nullable|integer',
    ]);

    $options = $validated['options'];
    if (($validated['correct_index'] ?? 0) >= count($options)) {
        return response()->json(['success' => false, 'message' => 'correct_index out of range'], 422);
    }

    $qId = DB::table('course_exam_questions')->insertGetId([
        'course_exam_id' => (int) $examId,
        'question_text' => $validated['question_text'],
        'options' => json_encode($options),
        'correct_index' => $validated['correct_index'],
        'sequence' => $validated['sequence'] ?? 0,
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    return response()->json(['success' => true, 'data' => ['id' => $qId]]);
});

Route::get('/admin/users/{userId}/course-detail', function (Request $request, $userId) {
    $auth = getAuthUser($request);
    if (! $auth) {
        return response()->json(['success' => false], 401);
    }

    $userId = (int) $userId;

    // Current subscription / package
    $subscription = DB::table('user_subscriptions')
        ->join('subscription_packages', 'subscription_packages.id', '=', 'user_subscriptions.package_id')
        ->where('user_subscriptions.user_id', $userId)
        ->where('user_subscriptions.status', 'active')
        ->where('user_subscriptions.expires_at', '>', now())
        ->orderBy('user_subscriptions.expires_at', 'desc')
        ->select(
            'user_subscriptions.id',
            'user_subscriptions.expires_at',
            'subscription_packages.name as package_name'
        )
        ->first();

    $progress = DB::table('course_progress')
        ->join('courses', 'courses.id', '=', 'course_progress.course_id')
        ->where('course_progress.user_id', $userId)
        ->select('course_progress.*', 'courses.title as course_title')
        ->get();

    $attempts = DB::table('course_exam_attempts')
        ->join('course_exams', 'course_exams.id', '=', 'course_exam_attempts.course_exam_id')
        ->join('courses', 'courses.id', '=', 'course_exams.course_id')
        ->where('course_exam_attempts.user_id', $userId)
        ->select(
            'course_exam_attempts.id',
            'course_exam_attempts.score_percent',
            'course_exam_attempts.passed',
            'course_exam_attempts.submitted_at',
            'courses.title as course_title'
        )
        ->orderBy('course_exam_attempts.submitted_at', 'desc')
        ->get();

    // Material-level progress: which videos/materials completed or in progress (for "watching" monitoring)
    $materialProgress = DB::table('course_material_progress')
        ->join('course_materials', 'course_materials.id', '=', 'course_material_progress.material_id')
        ->join('course_lessons', 'course_lessons.id', '=', 'course_materials.course_lesson_id')
        ->join('course_modules', 'course_modules.id', '=', 'course_lessons.course_module_id')
        ->join('courses', 'courses.id', '=', 'course_modules.course_id')
        ->where('course_material_progress.user_id', $userId)
        ->select(
            'course_material_progress.material_id',
            'course_material_progress.is_completed',
            'course_material_progress.progress_seconds',
            'course_material_progress.completed_at',
            'course_materials.title as material_title',
            'course_materials.type as material_type',
            'courses.id as course_id',
            'courses.title as course_title',
            'course_modules.title as module_title'
        )
        ->orderBy('courses.title')
        ->orderBy('course_modules.sequence')
        ->orderBy('course_lessons.sequence')
        ->get();

    return response()->json([
        'success' => true,
        'data' => [
            'subscription' => $subscription ? [
                'package_name' => $subscription->package_name,
                'expires_at' => $subscription->expires_at,
            ] : null,
            'course_progress' => $progress,
            'exam_attempts' => $attempts,
            'material_progress' => $materialProgress,
        ],
    ]);
});

// Admin: Force-complete a course for a user (for testing / support)
Route::post('/admin/force-complete-course', function (Request $request) {
    $auth = getAuthUser($request);
    if (! $auth) {
        return response()->json(['success' => false], 401);
    }

    $validated = $request->validate([
        'email' => 'required|email',
        'course_id' => 'required|integer',
    ]);

    $user = User::where('email', $validated['email'])->first();
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'User not found'], 404);
    }

    $course = DB::table('courses')->find($validated['course_id']);
    if (! $course) {
        return response()->json(['success' => false, 'message' => 'Course not found'], 404);
    }

    $materialIds = DB::table('course_materials')
        ->join('course_lessons', 'course_lessons.id', '=', 'course_materials.course_lesson_id')
        ->join('course_modules', 'course_modules.id', '=', 'course_lessons.course_module_id')
        ->where('course_modules.course_id', $validated['course_id'])
        ->pluck('course_materials.id');

    $now = now();
    foreach ($materialIds as $mid) {
        $exists = DB::table('course_material_progress')->where('user_id', $user->id)->where('material_id', $mid)->exists();
        if ($exists) {
            DB::table('course_material_progress')->where('user_id', $user->id)->where('material_id', $mid)
                ->update(['is_completed' => true, 'completed_at' => $now, 'updated_at' => $now]);
        } else {
            DB::table('course_material_progress')->insert([
                'user_id' => $user->id, 'material_id' => $mid, 'progress_seconds' => 0,
                'is_completed' => true, 'completed_at' => $now, 'created_at' => $now, 'updated_at' => $now,
            ]);
        }
    }
    $exists = DB::table('course_progress')->where('user_id', $user->id)->where('course_id', $validated['course_id'])->exists();
    if ($exists) {
        DB::table('course_progress')->where('user_id', $user->id)->where('course_id', $validated['course_id'])
            ->update(['progress_percent' => 100, 'is_completed' => true, 'completed_at' => $now, 'last_accessed_at' => $now, 'updated_at' => $now]);
    } else {
        DB::table('course_progress')->insert([
            'user_id' => $user->id, 'course_id' => $validated['course_id'], 'progress_percent' => 100,
            'is_completed' => true, 'completed_at' => $now, 'last_accessed_at' => $now, 'created_at' => $now, 'updated_at' => $now,
        ]);
    }

    return response()->json(['success' => true, 'message' => "Course marked 100% for {$validated['email']}"]);
});

// Add this to the protected group
Route::get('/user/rewards', function (Request $request) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false], 401);
    }

    $totalPoints = DB::table('activities')
        ->where('user_id', $user->id)
        ->where('is_completed', true)
        ->sum('points');

    $breakdown = DB::table('activities')
        ->where('user_id', $user->id)
        ->where('is_completed', true)
        ->select('category', DB::raw('sum(points) as total'))
        ->groupBy('category')
        ->get();

    return response()->json([
        'success' => true,
        'total_rewards' => (int) $totalPoints,
        'breakdown' => $breakdown,
    ]);
});

// Points history: all completed activities with date, activity name, and points
Route::get('/user/points-history', function (Request $request) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $limit = $request->get('limit', 100); // Default to last 100 entries
    $offset = $request->get('offset', 0);

    $history = DB::table('activities')
        ->where('user_id', $user->id)
        ->where('is_completed', true)
        ->whereNotNull('points')
        ->where('points', '>', 0)
        ->select(
            'id',
            'title',
            'type',
            'category',
            'points',
            DB::raw('DATE(completed_at) as date'),
            'completed_at'
        )
        ->orderBy('completed_at', 'desc')
        ->limit($limit)
        ->offset($offset)
        ->get();

    $totalPoints = DB::table('activities')
        ->where('user_id', $user->id)
        ->where('is_completed', true)
        ->whereNotNull('points')
        ->where('points', '>', 0)
        ->sum('points');

    return response()->json([
        'success' => true,
        'data' => $history,
        'total_points' => (int) $totalPoints,
        'count' => count($history),
    ]);
});

// User-facing packages list (for Flutter app)
Route::get('/packages', function () {
    return response()->json([
        'success' => true,
        'data' => \App\Models\SubscriptionPackage::where('is_active', true)->orderBy('tier_level', 'asc')->get(),
    ]);
});

// User-facing: Get my active subscription
Route::get('/user/subscription', function (Request $request) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $sub = \App\Models\UserSubscription::with('package')
        ->where('user_id', $user->id)
        ->where('status', 'active')
        ->where('expires_at', '>', now())
        ->orderBy('expires_at', 'desc')
        ->first();

    return response()->json([
        'success' => true,
        'data' => $sub,
        'is_premium' => (bool) $sub,
        'membership_tier' => $sub ? $sub->package->name : 'Consultant',
        'expires_at' => $sub ? $sub->expires_at->toIso8601String() : null,
    ]);
});

// User-facing Subscription Routes
Route::post('/subscriptions/validate-coupon', function (Request $request) {
    $code = $request->input('code');
    $coupon = \App\Models\Coupon::where('code', $code)
        ->where('is_active', true)
        ->where(function ($query) {
            $query->whereNull('expires_at')->orWhere('expires_at', '>', now());
        })
        ->first();

    if (! $coupon) {
        return response()->json(['success' => false, 'message' => 'Invalid or expired coupon']);
    }
    if ($coupon->max_uses && $coupon->used_count >= $coupon->max_uses) {
        return response()->json(['success' => false, 'message' => 'Coupon usage limit reached']);
    }

    return response()->json(['success' => true, 'data' => $coupon]);
});

Route::post('/subscriptions/purchase', function (Request $request) {
    // Purchase logic with auth
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }
    $data = $request->validate([
        'package_id' => 'required|exists:subscription_packages,id',
        'months' => 'required|integer|min:1',
        'coupon_id' => 'nullable|exists:coupons,id',
        'payment_id' => 'required|string', // Simulated PayPal ID
    ]);

    $package = \App\Models\SubscriptionPackage::findOrFail($data['package_id']);

    // Calculate amount
    $months = (int) $data['months'];

    // Match the mobile UI duration discounts:
    // - 1 month: no discount
    // - 6 monthly: 10% off (base monthly * 6 * 0.9)
    // - 1 yearly: 20% off (base monthly * 12 * 0.8)
    $durationDiscountFactor = 1.0;
    if ($months === 6) {
        $durationDiscountFactor = 0.9;
    } elseif ($months === 12) {
        $durationDiscountFactor = 0.8;
    }

    $amount = $package->price_monthly * $months * $durationDiscountFactor;
    if ($data['coupon_id']) {
        $coupon = \App\Models\Coupon::find($data['coupon_id']);
        $amount = $amount * (1 - ($coupon->discount_percentage / 100));
        $coupon->increment('used_count');
    }

    // Renewal handling:
    // If user already has an active subscription, extend from its current `expires_at`.
    // Also deactivate the old active subscription to keep only one active record at a time.
    $currentSub = \App\Models\UserSubscription::where('user_id', $user->id)
        ->where('status', 'active')
        ->where('expires_at', '>', now())
        ->orderBy('expires_at', 'desc')
        ->first();

    $baseDate = $currentSub ? $currentSub->expires_at : now();
    $expiresAt = \Carbon\Carbon::parse($baseDate)->addMonths($months);

    if ($currentSub) {
        $currentSub->status = 'cancelled';
        $currentSub->save();
    }

    $sub = \App\Models\UserSubscription::create([
        'user_id' => $user->id,
        'package_id' => $package->id,
        'started_at' => now(),
        'expires_at' => $expiresAt,
        'status' => 'active',
        'payment_method' => 'paypal',
        'payment_id' => $data['payment_id'],
        'amount_paid' => $amount,
        'coupon_id' => $data['coupon_id'],
    ]);

    // Update user tier
    $user->update([
        'membership_tier' => $package->name,
        'is_premium' => true,
        'premium_expires_at' => $sub->expires_at,
    ]);

    return response()->json(['success' => true, 'data' => $sub]);
});

// Admin settings for configurable user activity points
Route::get('/admin/settings/user-activity-points', function () {
    // Default 20 if not set
    $points = cache('user_activity_points', 20);

    return response()->json(['success' => true, 'points' => $points]);
});

Route::post('/admin/settings/user-activity-points', function (Request $request) {
    $data = $request->validate(['points' => 'required|integer|min:1|max:100']);
    cache(['user_activity_points' => $data['points']], now()->addYears(5));

    return response()->json(['success' => true, 'points' => $data['points']]);
});

Route::post('/admin/login', function (Request $request) {
    Log::info('Admin Login Attempt', ['email' => $request->email]);

    // Ensure admin user exists (create/update for initial access)
    \App\Models\User::updateOrCreate(
        ['email' => 'admin@realtorone.com'],
        [
            'name' => 'Admin Operator',
            'password' => \Illuminate\Support\Facades\Hash::make('password123'),
        ]
    );

    $credentials = $request->validate([
        'email' => ['required', 'email'],
        'password' => ['required', 'string'],
    ]);

    $user = \App\Models\User::where('email', $credentials['email'])->first();

    if ($user && \Illuminate\Support\Facades\Hash::check($credentials['password'], $user->password)) {
        $token = bin2hex(random_bytes(32));
        $user->update(['remember_token' => $token]);

        Log::info('Admin Login Success', ['user_id' => $user->id]);

        // Attach momentum data
        $today = now()->toDateString();
        $metric = \App\Models\PerformanceMetric::where('user_id', $user->id)
            ->where('date', $today)
            ->first();

        $user->daily_score = $metric ? $metric->total_momentum_score : 0;

        return response()->json([
            'status' => 'ok',
            'token' => $token,
            'user' => $user,
        ]);
    }

    Log::warning('Admin Login Failed', ['email' => $request->email]);

    return response()->json([
        'message' => 'Credentials mismatch. Error 401: Unauthorized access to system core.',
        'debug_hint' => 'Check if email is admin@realtorone.com',
    ], 401);
});

Route::get('/admin/momentum-leaders', function () {
    $leaders = \App\Models\PerformanceMetric::with('user')
        ->where('date', now()->toDateString())
        ->orderBy('total_momentum_score', 'desc')
        ->limit(10)
        ->get();

    return response()->json($leaders);
});

Route::get('/activity-types', function (Request $request) {
    // Seed defaults only for first-time empty environments.
    // Do not reseed on every request; otherwise admin deletions reappear.
    if (\App\Models\ActivityType::where('is_global', true)->count() === 0) {
        seedDefaultActivityTypes();
    }

    $user = getAuthUser($request);

    $query = \App\Models\ActivityType::where('is_global', true);
    if ($user) {
        $query->orWhere('user_id', $user->id);
    }
    $types = $query
        ->orderBy('category')
        ->orderBy('section_order')
        ->orderBy('item_order')
        ->orderBy('name')
        ->get();

    // Day-aware task content for app popup (falls back to day 1, then base fields).
    // Uses the Day 1..7 hybrid program cycle (program_current_day), not current_streak.
    $dayNumber = 1;
    if ($user) {
        $dayNumber = (int) ($user->program_current_day ?? 1);
        $dayNumber = max(1, min(7, $dayNumber));
    }

    if ($types->isNotEmpty()) {
        $typeIds = $types->pluck('id')->all();
        $requestedDays = array_values(array_unique([$dayNumber, 1]));

        $logs = DB::table('activity_type_daily_logs')
            ->whereIn('activity_type_id', $typeIds)
            ->whereIn('day_number', $requestedDays)
            ->get();

        $logMap = [];
        foreach ($logs as $log) {
            $logMap[$log->activity_type_id][$log->day_number] = $log;
        }

        $types = $types->map(function ($type) use ($logMap, $dayNumber) {
            $exact = $logMap[$type->id][$dayNumber] ?? null;
            $fallbackDay1 = $logMap[$type->id][1] ?? null;
            $selectedLog = $exact ?: $fallbackDay1;

            $type->today_day_number = $dayNumber;
            $type->task_description = $selectedLog->task_description ?? $type->description;
            $type->video_reel_script_idea = $selectedLog->script_idea ?? $type->script_idea;
            $type->daily_feedback = $selectedLog->feedback ?? null;
            $type->daily_audio_url = $selectedLog->audio_url ?? null;
            $type->daily_required_listen_percent = $selectedLog->required_listen_percent ?? 0;
            $type->daily_require_user_response = (bool) ($selectedLog->require_user_response ?? false);
            $type->has_daily_log = $selectedLog !== null;

            return $type;
        });
    }

    return response()->json(['success' => true, 'data' => $types]);
});

Route::post('/activity-types', function (Request $request) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $data = $request->validate([
        'name' => 'required|string|max:255',
        'icon' => 'nullable|string',
        'description' => 'nullable|string',
        'script_idea' => 'nullable|string',
        'section_title' => 'nullable|string|max:255',
        'section_order' => 'nullable|integer|min:0',
        'item_order' => 'nullable|integer|min:0',
    ]);

    // Users can only create subconscious activities with admin-configurable points
    $userPoints = cache('user_activity_points', 20);
    $activityType = \App\Models\ActivityType::create([
        'name' => $data['name'],
        'points' => $userPoints,
        'category' => 'subconscious',
        'type_key' => Str::slug($data['name'], '_'),
        'icon' => $data['icon'] ?? 'Activity',
        'description' => $data['description'] ?? '',
        'script_idea' => $data['script_idea'] ?? '',
        'user_id' => $user->id,
        'is_global' => false,
        'section_title' => $data['section_title'] ?? 'Custom Activities',
        'section_order' => $data['section_order'] ?? 99,
        'item_order' => $data['item_order'] ?? 0,
    ]);

    return response()->json(['success' => true, 'data' => $activityType]);
});

Route::post('/admin/activity-types', function (Request $request) {
    $data = $request->validate([
        'name' => 'required|string|max:255',
        'points' => 'required|integer|min:1',
        'category' => 'required|in:conscious,subconscious',
        'icon' => 'nullable|string',
        'description' => 'nullable|string',
        'script_idea' => 'nullable|string',
        'min_tier' => 'nullable|string',
        'section_title' => 'nullable|string|max:255',
        'section_order' => 'nullable|integer|min:0',
        'item_order' => 'nullable|integer|min:0',
    ]);

    $activityType = \App\Models\ActivityType::create([
        'name' => $data['name'],
        'points' => $data['points'],
        'category' => $data['category'],
        'type_key' => Str::slug($data['name'], '_'),
        'icon' => $data['icon'] ?? 'Activity',
        'description' => $data['description'] ?? '',
        'script_idea' => $data['script_idea'] ?? '',
        'is_global' => true,
        'min_tier' => $data['min_tier'] ?? 'Consultant',
        'section_title' => $data['section_title'] ?? ($data['category'] === 'subconscious' ? 'Day 1' : 'Conscious'),
        'section_order' => $data['section_order'] ?? 0,
        'item_order' => $data['item_order'] ?? 0,
    ]);

    return response()->json(['success' => true, 'data' => $activityType]);
});

Route::put('/admin/activity-types/{id}', function (Request $request, $id) {
    $activityType = \App\Models\ActivityType::findOrFail($id);

    $data = $request->validate([
        'name' => 'sometimes|string|max:255',
        'points' => 'sometimes|integer|min:1',
        'category' => 'sometimes|in:conscious,subconscious',
        'icon' => 'nullable|string',
        'description' => 'nullable|string',
        'script_idea' => 'nullable|string',
        'min_tier' => 'nullable|string',
        'section_title' => 'nullable|string|max:255',
        'section_order' => 'sometimes|integer|min:0',
        'item_order' => 'sometimes|integer|min:0',
    ]);

    $activityType->update($data);
    if (isset($data['name'])) {
        $activityType->update(['type_key' => Str::slug($data['name'], '_')]);
    }

    return response()->json(['success' => true, 'data' => $activityType->fresh()]);
});

Route::post('/admin/activity-types/group-update', function (Request $request) {
    $data = $request->validate([
        'category' => 'required|in:conscious,subconscious',
        'current_section_title' => 'required|string|max:255',
        'section_title' => 'required|string|max:255',
        'section_order' => 'required|integer|min:0',
    ]);

    $query = \App\Models\ActivityType::where('category', $data['category'])
        ->where('section_title', $data['current_section_title']);

    $query->update([
        'section_title' => $data['section_title'],
        'section_order' => $data['section_order'],
    ]);

    $updated = \App\Models\ActivityType::where('category', $data['category'])
        ->where('section_title', $data['section_title'])
        ->orderBy('item_order')
        ->orderBy('name')
        ->get();

    return response()->json([
        'success' => true,
        'data' => $updated,
    ]);
});

Route::get('/admin/activity-types/{id}/daily-logs', function (Request $request, $id) {
    $activityType = \App\Models\ActivityType::findOrFail($id);

    $data = $request->validate([
        'from_day' => 'nullable|integer|min:1|max:365',
        'to_day' => 'nullable|integer|min:1|max:365',
    ]);

    $fromDay = $data['from_day'] ?? 1;
    $toDay = $data['to_day'] ?? 60;
    if ($toDay < $fromDay) {
        [$fromDay, $toDay] = [$toDay, $fromDay];
    }

    $logs = DB::table('activity_type_daily_logs')
        ->where('activity_type_id', $activityType->id)
        ->whereBetween('day_number', [$fromDay, $toDay])
        ->orderBy('day_number')
        ->get();

    return response()->json([
        'success' => true,
        'data' => $logs,
    ]);
});

Route::put('/admin/activity-types/{id}/daily-logs/{day}', function (Request $request, $id, $day) {
    $activityType = \App\Models\ActivityType::findOrFail($id);
    $dayNumber = (int) $day;
    if ($dayNumber < 1 || $dayNumber > 365) {
        return response()->json(['success' => false, 'message' => 'Invalid day number'], 422);
    }

    $data = $request->validate([
        'task_description' => 'nullable|string',
        'script_idea' => 'nullable|string',
        'feedback' => 'nullable|string',
        'audio_url' => 'nullable|string|max:2048',
        'required_listen_percent' => 'nullable|integer|min:0|max:100',
        'require_user_response' => 'nullable|boolean',
    ]);

    DB::table('activity_type_daily_logs')->updateOrInsert(
        [
            'activity_type_id' => $activityType->id,
            'day_number' => $dayNumber,
        ],
        [
            'task_description' => $data['task_description'] ?? null,
            'script_idea' => $data['script_idea'] ?? null,
            'feedback' => $data['feedback'] ?? null,
            'audio_url' => $data['audio_url'] ?? null,
            'required_listen_percent' => isset($data['required_listen_percent']) ? (int) $data['required_listen_percent'] : 0,
            'require_user_response' => isset($data['require_user_response']) ? (bool) $data['require_user_response'] : false,
            'updated_at' => now(),
            'created_at' => now(),
        ]
    );

    $saved = DB::table('activity_type_daily_logs')
        ->where('activity_type_id', $activityType->id)
        ->where('day_number', $dayNumber)
        ->first();

    return response()->json([
        'success' => true,
        'data' => $saved,
    ]);
});

Route::delete('/admin/activity-types/{id}/daily-logs/{day}', function ($id, $day) {
    $activityType = \App\Models\ActivityType::findOrFail($id);
    $dayNumber = (int) $day;
    if ($dayNumber < 1 || $dayNumber > 365) {
        return response()->json(['success' => false, 'message' => 'Invalid day number'], 422);
    }

    DB::table('activity_type_daily_logs')
        ->where('activity_type_id', $activityType->id)
        ->where('day_number', $dayNumber)
        ->delete();

    return response()->json([
        'success' => true,
    ]);
});

Route::post('/admin/activity-types/{id}/daily-logs/bulk', function (Request $request, $id) {
    $activityType = \App\Models\ActivityType::findOrFail($id);

    $data = $request->validate([
        'entries' => 'required|array|min:1',
        'entries.*.day_number' => 'required|integer|min:1|max:365',
        'entries.*.task_description' => 'nullable|string',
        'entries.*.script_idea' => 'nullable|string',
        'entries.*.feedback' => 'nullable|string',
        'entries.*.audio_url' => 'nullable|string|max:2048',
        'entries.*.required_listen_percent' => 'nullable|integer|min:0|max:100',
        'entries.*.require_user_response' => 'nullable|boolean',
    ]);

    $now = now();
    $rows = array_map(function ($entry) use ($activityType, $now) {
        return [
            'activity_type_id' => $activityType->id,
            'day_number' => (int) $entry['day_number'],
            'task_description' => $entry['task_description'] ?? null,
            'script_idea' => $entry['script_idea'] ?? null,
            'feedback' => $entry['feedback'] ?? null,
            'audio_url' => $entry['audio_url'] ?? null,
            'required_listen_percent' => isset($entry['required_listen_percent']) ? (int) $entry['required_listen_percent'] : 0,
            'require_user_response' => isset($entry['require_user_response']) ? (bool) $entry['require_user_response'] : false,
            'created_at' => $now,
            'updated_at' => $now,
        ];
    }, $data['entries']);

    DB::table('activity_type_daily_logs')->upsert(
        $rows,
        ['activity_type_id', 'day_number'],
        ['task_description', 'script_idea', 'feedback', 'audio_url', 'required_listen_percent', 'require_user_response', 'updated_at']
    );

    return response()->json([
        'success' => true,
        'count' => count($rows),
    ]);
});

Route::delete('/admin/activity-types/{id}', function ($id) {
    $activityType = \App\Models\ActivityType::findOrFail($id);
    $activityType->delete();

    return response()->json(['success' => true]);
});

Route::post('/register', function (Request $request) {
    $data = $request->validate([
        'name' => ['required', 'string', 'max:255'],
        'email' => ['required', 'email', 'max:255', 'unique:users,email'],
        'password' => ['required', 'string', 'min:6'],
    ]);

    $user = User::create([
        'name' => $data['name'],
        'email' => $data['email'],
        'password' => Hash::make($data['password']),
    ]);

    return response()->json([
        'status' => 'ok',
        'user' => [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
        ],
    ], 201);
});

Route::post('/login', function (Request $request) {
    $data = $request->validate([
        'email' => ['required', 'email'],
        'password' => ['required', 'string'],
    ]);

    $user = User::where('email', $data['email'])->first();

    if (! $user || ! Hash::check($data['password'], $user->password)) {
        return response()->json([
            'status' => 'error',
            'message' => 'Invalid credentials.',
        ], 401);
    }

    if ($user->status === 'inactive') {
        return response()->json([
            'status' => 'error',
            'message' => 'Your account is deactivated. Contact support for recovery.',
        ], 403);
    }

    // Generate token
    $token = bin2hex(random_bytes(32));
    $user->update(['remember_token' => $token]);

    return response()->json([
        'status' => 'ok',
        'token' => $token,
        'user' => [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
        ],
    ]);
});

Route::post('/login/google', function (Request $request) {
    Log::info('[GOOGLE LOGIN] Request received', [
        'has_id_token' => $request->filled('id_token'),
        'email_hint' => $request->input('email'),
    ]);

    $data = $request->validate([
        'id_token' => ['required', 'string'],
        'email' => ['nullable', 'email'],
        'name' => ['nullable', 'string', 'max:255'],
    ]);

    $verify = Http::asForm()
        ->timeout(15)
        ->post('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $data['id_token'],
        ]);

    if (! $verify->ok()) {
        Log::warning('[GOOGLE LOGIN] tokeninfo verify failed', [
            'status' => $verify->status(),
            'body' => $verify->body(),
        ]);
        return response()->json([
            'status' => 'error',
            'message' => 'Invalid Google token.',
        ], 401);
    }

    $payload = $verify->json();
    $googleEmail = strtolower(trim((string) ($payload['email'] ?? '')));
    $emailVerified = (string) ($payload['email_verified'] ?? '') === 'true';
    $audience = trim((string) ($payload['aud'] ?? ''));
    $expectedAudience = trim((string) env('GOOGLE_CLIENT_ID', ''));

    if ($expectedAudience !== '' && $audience !== $expectedAudience) {
        Log::warning('[GOOGLE LOGIN] audience mismatch', [
            'aud' => $audience,
            'expected' => $expectedAudience,
        ]);
        return response()->json([
            'status' => 'error',
            'message' => 'Google token audience mismatch.',
        ], 401);
    }

    if ($googleEmail === '' || ! $emailVerified) {
        Log::warning('[GOOGLE LOGIN] email not verified', [
            'email' => $googleEmail,
            'email_verified' => $emailVerified,
        ]);
        return response()->json([
            'status' => 'error',
            'message' => 'Google account email is not verified.',
        ], 401);
    }

    $name = trim((string) ($payload['name'] ?? ''));
    if ($name === '') {
        $name = trim((string) ($data['name'] ?? ''));
    }
    if ($name === '') {
        $name = Str::before($googleEmail, '@');
    }

    $user = User::whereRaw('LOWER(email) = ?', [$googleEmail])->first();
    if (! $user) {
        $user = User::create([
            'name' => $name,
            'email' => $googleEmail,
            'password' => Hash::make(Str::random(40)),
            'status' => 'active',
        ]);
        $user->email_verified_at = now();
        $user->save();
        Log::info('[GOOGLE LOGIN] user created', ['user_id' => $user->id, 'email' => $user->email]);
    } else {
        if (trim((string) $user->name) === '' && $name !== '') {
            $user->name = $name;
        }
        if (! $user->email_verified_at) {
            $user->email_verified_at = now();
        }
        $user->save();
        Log::info('[GOOGLE LOGIN] existing user login', ['user_id' => $user->id, 'email' => $user->email]);
    }

    if ($user->status === 'inactive') {
        return response()->json([
            'status' => 'error',
            'message' => 'Your account is deactivated. Contact support for recovery.',
        ], 403);
    }

    $token = bin2hex(random_bytes(32));
    $user->update(['remember_token' => $token]);
    Log::info('[GOOGLE LOGIN] success', ['user_id' => $user->id]);

    return response()->json([
        'status' => 'ok',
        'token' => $token,
        'user' => [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
        ],
    ]);
});

Route::post('/user/push-token', function (Request $request) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $data = $request->validate([
        'token' => ['required', 'string', 'max:512'],
        'platform' => ['nullable', 'string', 'max:32'],
    ]);

    UserPushToken::query()->updateOrCreate(
        [
            'user_id' => $user->id,
            'token' => $data['token'],
        ],
        [
            'platform' => $data['platform'] ?? 'android',
        ]
    );

    return response()->json(['success' => true]);
});

Route::delete('/user/push-token', function (Request $request) {
    $user = getAuthUser($request);
    if (! $user) {
        return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $token = $request->input('token');
    if (is_string($token) && $token !== '') {
        UserPushToken::query()->where('user_id', $user->id)->where('token', $token)->delete();
    } else {
        UserPushToken::query()->where('user_id', $user->id)->delete();
    }

    return response()->json(['success' => true]);
});

Route::post('/logout', function (Request $request) {
    $token = $request->bearerToken();

    if ($token) {
        $user = User::where('remember_token', $token)->first();
        if ($user) {
            $user->update(['remember_token' => null]);
        }
    }

    return response()->json([
        'status' => 'ok',
        'message' => 'Logged out successfully',
    ]);
});

Route::post('/password/forgot', function (Request $request) {
    $data = $request->validate([
        'email' => ['required', 'email'],
    ]);

    $user = User::where('email', $data['email'])->first();

    if (! $user) {
        return response()->json([
            'status' => 'error',
            'message' => 'User not found.',
        ], 404);
    }

    // Generate reset token
    $resetToken = bin2hex(random_bytes(32));
    $user->update(['remember_token' => $resetToken]);

    // In production, send email with reset link
    // For now, return token for testing
    return response()->json([
        'status' => 'ok',
        'message' => 'Password reset token generated',
        'reset_token' => $resetToken,
    ]);
});

Route::post('/password/reset', function (Request $request) {
    $data = $request->validate([
        'token' => ['required', 'string'],
        'password' => ['required', 'string', 'min:6'],
    ]);

    $user = User::where('remember_token', $data['token'])->first();

    if (! $user) {
        return response()->json([
            'status' => 'error',
            'message' => 'Invalid or expired token.',
        ], 400);
    }

    $user->update([
        'password' => Hash::make($data['password']),
        'remember_token' => null,
    ]);

    return response()->json([
        'status' => 'ok',
        'message' => 'Password reset successfully',
    ]);
});

Route::post('/email/verify', function (Request $request) {
    $data = $request->validate([
        'email' => ['required', 'email'],
    ]);

    $user = User::where('email', $data['email'])->first();

    if (! $user) {
        return response()->json([
            'status' => 'error',
            'message' => 'User not found.',
        ], 404);
    }

    // Mark email as verified
    $user->update(['email_verified_at' => now()]);

    return response()->json([
        'status' => 'ok',
        'message' => 'Email verified successfully',
    ]);
});

// Protected routes (require authentication)
Route::group(['middleware' => []], function () {

    // ============== USER PROFILE ==============

    Route::get('/user/profile', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'mobile' => $user->mobile,
                'city' => $user->city,
                'brokerage' => $user->brokerage,
                'instagram' => $user->instagram,
                'linkedin' => $user->linkedin,
                'years_experience' => $user->years_experience,
                'current_monthly_income' => $user->current_monthly_income,
                'target_monthly_income' => $user->target_monthly_income,
                'profile_photo' => $user->profile_photo_path ? url('storage/'.$user->profile_photo_path) : null,
                'is_profile_complete' => (bool) $user->is_profile_complete,
                'has_completed_diagnosis' => (bool) $user->has_completed_diagnosis,
                'diagnosis_blocker' => $user->diagnosis_blocker,
                'growth_score' => $user->growth_score ?? 0,
                'execution_rate' => $user->execution_rate ?? 0,
                'mindset_index' => $user->mindset_index ?? 0,
                'rank' => $user->rank,
                'current_streak' => $user->current_streak ?? 0,
                'is_premium' => (bool) $user->is_premium,
                'membership_tier' => $user->membership_tier ?? 'Consultant',
                'onboarding_step' => (int) ($user->onboarding_step ?? 0),
                'total_rewards' => (int) DB::table('activities')
                    ->where('user_id', $user->id)
                    ->where('is_completed', true)
                    ->sum('points'),
                'email_verified_at' => $user->email_verified_at,
                'created_at' => $user->created_at,
            ],
        ]);
    });

    Route::put('/user/profile', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'max:255', 'unique:users,email,'.$user->id],
            'mobile' => ['sometimes', 'nullable', 'string', 'max:20'],
            'city' => ['sometimes', 'nullable', 'string', 'max:100'],
            'brokerage' => ['sometimes', 'nullable', 'string', 'max:255'],
            'instagram' => ['sometimes', 'nullable', 'string', 'max:100'],
            'linkedin' => ['sometimes', 'nullable', 'string', 'max:255'],
            'years_experience' => ['sometimes', 'nullable', 'integer', 'min:0'],
            'current_monthly_income' => ['sometimes', 'nullable', 'numeric', 'min:0'],
            'target_monthly_income' => ['sometimes', 'nullable', 'numeric', 'min:0'],
        ]);

        $user->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
        ]);
    });

    Route::put('/user/profile/setup', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email,'.$user->id],
            'mobile' => ['required', 'string', 'max:20'],
            'city' => ['required', 'string', 'max:100'],
            'brokerage' => ['required', 'string', 'max:255'],
            'instagram' => ['sometimes', 'nullable', 'string', 'max:100'],
            'linkedin' => ['sometimes', 'nullable', 'string', 'max:255'],
            'years_experience' => ['sometimes', 'nullable', 'integer', 'min:0'],
            'current_monthly_income' => ['sometimes', 'nullable', 'numeric', 'min:0'],
            'target_monthly_income' => ['sometimes', 'nullable', 'numeric', 'min:0'],
            'is_profile_complete' => ['sometimes', 'boolean'],
            'onboarding_step' => ['sometimes', 'integer'],
        ]);

        $user->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Profile setup completed',
        ]);
    });

    Route::post('/user/request-deletion', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        // Deactivate user and record timestamp for admin panel / compliance queue
        $user->update([
            'status' => 'inactive',
            'remember_token' => null,
            'deletion_requested_at' => now(),
        ]);
        Log::warning("Account deletion requested from mobile app", [
            'user_id' => $user->id,
            'email' => $user->email,
            'deletion_requested_at' => $user->deletion_requested_at?->toIso8601String(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Account deletion requested successfully.',
        ]);
    });

    Route::post('/user/change-password', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'new_password' => ['required', 'string', 'min:6'],
        ]);

        if (! Hash::check($data['current_password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Current password is incorrect',
            ], 400);
        }

        $user->update([
            'password' => Hash::make($data['new_password']),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password changed successfully',
        ]);
    });

    Route::post('/user/photo', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $request->validate([
            'photo' => ['required', 'image', 'max:2048'],
        ]);

        $path = $request->file('photo')->store('profile-photos', 'public');
        $user->update(['profile_photo_path' => $path]);

        return response()->json([
            'success' => true,
            'message' => 'Photo uploaded successfully',
            'photo_url' => asset('storage/'.$path),
        ]);
    });

    // ============== DIAGNOSIS ==============

    Route::get('/diagnosis/questions', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $questions = DB::table('diagnosis_questions')
            ->where('is_active', true)
            ->orderBy('display_order')
            ->orderBy('id')
            ->get();

        $data = $questions->map(function ($q) {
            return [
                'id' => (int) $q->id,
                'question' => $q->question_text,
                'display_order' => (int) $q->display_order,
                'options' => json_decode($q->options_json, true) ?? [],
            ];
        })->values();

        return response()->json(['success' => true, 'data' => $data]);
    });

    Route::get('/admin/diagnosis/questions', function (Request $request) {
        $admin = getAuthUser($request);
        if (! $admin || $admin->email !== 'admin@realtorone.com') {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $questions = DB::table('diagnosis_questions')
            ->orderBy('display_order')
            ->orderBy('id')
            ->get()
            ->map(function ($q) {
                return [
                    'id' => (int) $q->id,
                    'question_text' => $q->question_text,
                    'display_order' => (int) $q->display_order,
                    'is_active' => (bool) $q->is_active,
                    'options' => json_decode($q->options_json, true) ?? [],
                ];
            })->values();

        return response()->json(['success' => true, 'data' => $questions]);
    });

    Route::post('/admin/diagnosis/questions', function (Request $request) {
        $admin = getAuthUser($request);
        if (! $admin || $admin->email !== 'admin@realtorone.com') {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'question_text' => ['required', 'string', 'max:1000'],
            'display_order' => ['required', 'integer', 'min:1'],
            'is_active' => ['nullable', 'boolean'],
            'options' => ['required', 'array', 'min:2'],
            'options.*.text' => ['required', 'string', 'max:500'],
            'options.*.blocker_type' => ['required', 'string', 'in:leadGeneration,confidence,closing,discipline'],
            'options.*.score' => ['required', 'integer', 'min:0', 'max:10'],
        ]);

        $id = DB::table('diagnosis_questions')->insertGetId([
            'question_text' => $data['question_text'],
            'display_order' => (int) $data['display_order'],
            'is_active' => isset($data['is_active']) ? (bool) $data['is_active'] : true,
            'options_json' => json_encode($data['options']),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['success' => true, 'data' => ['id' => $id]]);
    });

    Route::put('/admin/diagnosis/questions/{id}', function (Request $request, $id) {
        $admin = getAuthUser($request);
        if (! $admin || $admin->email !== 'admin@realtorone.com') {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'question_text' => ['required', 'string', 'max:1000'],
            'display_order' => ['required', 'integer', 'min:1'],
            'is_active' => ['required', 'boolean'],
            'options' => ['required', 'array', 'min:2'],
            'options.*.text' => ['required', 'string', 'max:500'],
            'options.*.blocker_type' => ['required', 'string', 'in:leadGeneration,confidence,closing,discipline'],
            'options.*.score' => ['required', 'integer', 'min:0', 'max:10'],
        ]);

        DB::table('diagnosis_questions')
            ->where('id', $id)
            ->update([
                'question_text' => $data['question_text'],
                'display_order' => (int) $data['display_order'],
                'is_active' => (bool) $data['is_active'],
                'options_json' => json_encode($data['options']),
                'updated_at' => now(),
            ]);

        return response()->json(['success' => true]);
    });

    Route::delete('/admin/diagnosis/questions/{id}', function (Request $request, $id) {
        $admin = getAuthUser($request);
        if (! $admin || $admin->email !== 'admin@realtorone.com') {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        DB::table('diagnosis_questions')->where('id', $id)->delete();
        return response()->json(['success' => true]);
    });

    Route::post('/diagnosis/submit', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'primary_blocker' => ['required', 'string', 'in:leadGeneration,confidence,closing,discipline'],
            'scores' => ['required', 'array'],
        ]);

        $user->update([
            'has_completed_diagnosis' => true,
            'diagnosis_blocker' => $data['primary_blocker'],
            'diagnosis_scores' => json_encode($data['scores']),
            'growth_score' => 50, // Starting score
            'mindset_index' => 50,
            'rank' => 'Starter',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Diagnosis submitted successfully',
            'data' => [
                'primary_blocker' => $data['primary_blocker'],
                'recommended_path' => $this->getRecommendedPath($data['primary_blocker']),
            ],
        ]);
    });

    // ============== ACTIVITIES ==============

    Route::get('/activities', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $date = $request->get('date', now()->toDateString());

        $activities = DB::table('activities')
            ->where('user_id', $user->id)
            ->whereDate('scheduled_at', $date)
            ->orderBy('scheduled_at')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $activities,
        ]);
    });

    Route::post('/activities', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'notes' => ['sometimes', 'nullable', 'string'],
            'type' => ['required', 'string'],
            'category' => ['required', 'string', 'in:conscious,subconscious,task'],
            'duration_minutes' => ['sometimes', 'integer', 'min:1'],
            'scheduled_at' => ['sometimes', 'date'],
        ]);

        $data['user_id'] = $user->id;
        $data['scheduled_at'] = $data['scheduled_at'] ?? now();

        $id = DB::table('activities')->insertGetId($data + [
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Activity created',
            'data' => ['id' => $id],
        ], 201);
    });

    Route::put('/activities/{id}/complete', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $activity = DB::table('activities')
            ->where('id', $id)
            ->where('user_id', $user->id)
            ->first();

        if (! $activity) {
            return response()->json(['success' => false, 'message' => 'Activity not found'], 404);
        }

        // Award points for this activity type when completing
        $service = new \App\Services\PerformanceService;
        $points = $service->getActivityPoints($activity->type);

        DB::table('activities')->where('id', $id)->update([
            'is_completed' => true,
            'completed_at' => now(),
            'points' => $points,
            'updated_at' => now(),
        ]);

        // Hybrid streak + progress day (Day 1..7 cycle).
        // Rules follow (from your corrections):
        // - First time: streak=1 and program day advances.
        // - Same-day YES: counted once; no further changes.
        // - If active on previous day (no gap): streak += 1 and program day advances.
        // - If not active on previous day (gap >= 1 day): streak resets to 1 and program day advances.
        // - Program day never stays the same after a break: always advances to next day in 1..7.
        $lastActivity = $user->last_activity_date; // stored as date (no time)
        $today = now()->toDateString();
        $yesterday = now()->subDay()->toDateString();

        $programDay = (int) ($user->program_current_day ?? 1);
        $newProgramDay = (int) ($user->program_current_day ?? 1);
        $newStreak = (int) ($user->current_streak ?? 0);

        // Prevent double-advancing streak/day if user completes multiple activities on the same date.
        $shouldAdvance = $lastActivity !== $today;

        if ($lastActivity === null) {
            // Step 2: first-time user
            $newStreak = 1;
            $newProgramDay = $programDay >= 7 ? 1 : ($programDay + 1);
        } elseif ($shouldAdvance) {
            // Same-day YES is ignored by $shouldAdvance; this ensures only first YES counts.
            $newProgramDay = $programDay >= 7 ? 1 : ($programDay + 1); // always advance after a counted YES

            if ($lastActivity === $yesterday) {
                // No gap
                $newStreak = $newStreak + 1;
            } else {
                // Not active on previous day (gap >= 1 day)
                $newStreak = 1;
            }
        }

        $newLongestStreak = max((int) ($user->longest_streak ?? 0), $newStreak);

        $user->update([
            'current_streak' => $newStreak,
            'longest_streak' => $newLongestStreak,
            'program_current_day' => $newProgramDay,
            'last_activity_date' => $today,
            'execution_rate' => min(100, (int) ($user->execution_rate ?? 0) + 2),
        ]);

        // Recalculate daily score and award badges (keeps dashboard in sync)
        $metric = $service->calculateDailyScore($user);
        $badgeService = new \App\Services\BadgeService;
        $newBadges = $badgeService->checkAndAwardBadges($user);

        return response()->json([
            'success' => true,
            'message' => 'Activity completed',
            'current_streak' => $user->current_streak,
            'points_awarded' => $points,
            'daily_score' => $metric->total_momentum_score,
            'new_badges' => $newBadges,
        ]);
    });

    Route::get('/activities/progress', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $today = now()->toDateString();

        $tasksTotal = DB::table('activities')
            ->where('user_id', $user->id)
            ->whereDate('scheduled_at', $today)
            ->where('category', 'task')
            ->count();

        $tasksCompleted = DB::table('activities')
            ->where('user_id', $user->id)
            ->whereDate('scheduled_at', $today)
            ->where('category', 'task')
            ->where('is_completed', true)
            ->count();

        $subconsciousTotal = DB::table('activities')
            ->where('user_id', $user->id)
            ->whereDate('scheduled_at', $today)
            ->where('category', 'subconscious')
            ->count();

        $subconsciousCompleted = DB::table('activities')
            ->where('user_id', $user->id)
            ->whereDate('scheduled_at', $today)
            ->where('category', 'subconscious')
            ->where('is_completed', true)
            ->count();

        return response()->json([
            'success' => true,
            'data' => [
                'date' => $today,
                'tasks_total' => $tasksTotal,
                'tasks_completed' => $tasksCompleted,
                'subconscious_total' => $subconsciousTotal,
                'subconscious_completed' => $subconsciousCompleted,
                'current_streak' => $user->current_streak,
                'program_current_day' => max(1, min(7, (int) ($user->program_current_day ?? 1))),
            ],
        ]);
    });

    Route::post('/activities/log', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'type' => ['required', 'string'],
            'category' => ['required', 'string', 'in:task,subconscious,conscious'],
            'quantity' => ['sometimes', 'integer', 'min:1'],
            'value' => ['sometimes', 'numeric'],
            'notes' => ['sometimes', 'nullable', 'string'],
        ]);

        $service = new \App\Services\PerformanceService;
        $points = $service->getActivityPoints($data['type']);

        $activity = \App\Models\Activity::create([
            'user_id' => $user->id,
            'title' => ucwords(str_replace('_', ' ', $data['type'])),
            'type' => $data['type'],
            'category' => $data['category'],
            'points' => $points,
            'quantity' => $data['quantity'] ?? 1,
            'value' => $data['value'] ?? 0,
            'is_completed' => true,
            'completed_at' => now(),
            'notes' => $data['notes'] ?? null,
        ]);

        // Keep streak/progress in sync with the hybrid Day 1..7 rules.
        $lastActivity = $user->last_activity_date;
        $today = now()->toDateString();
        $yesterday = now()->subDay()->toDateString();

        $programDay = (int) ($user->program_current_day ?? 1);
        $newProgramDay = (int) ($user->program_current_day ?? 1);
        $newStreak = (int) ($user->current_streak ?? 0);
        $shouldAdvance = $lastActivity !== $today;

        if ($lastActivity === null) {
            $newStreak = 1;
            $newProgramDay = $programDay >= 7 ? 1 : ($programDay + 1);
        } elseif ($shouldAdvance) {
            // Same-day YES is ignored by $shouldAdvance; only first YES counts.
            $newProgramDay = $programDay >= 7 ? 1 : ($programDay + 1); // always advance after a counted YES

            if ($lastActivity === $yesterday) {
                $newStreak = $newStreak + 1; // active previous day => streak continues
            } else {
                $newStreak = 1; // not active on previous day => break => reset
            }
        }

        $newLongestStreak = max((int) ($user->longest_streak ?? 0), $newStreak);

        $user->update([
            'current_streak' => $newStreak,
            'longest_streak' => $newLongestStreak,
            'program_current_day' => $newProgramDay,
            'last_activity_date' => $today,
            'execution_rate' => min(100, (int) ($user->execution_rate ?? 0) + 2),
        ]);
        $metric = $service->calculateDailyScore($user);

        // Check and award badges
        $badgeService = new \App\Services\BadgeService;
        $newBadges = $badgeService->checkAndAwardBadges($user);

        return response()->json([
            'success' => true,
            'message' => 'Activity logged successfully',
            'data' => [
                'activity' => $activity,
                'daily_score' => $metric->total_momentum_score,
                'streak' => $user->current_streak,
                'new_badges' => $newBadges,
            ],
        ]);
    });

    Route::get('/dashboard/momentum', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $service = new \App\Services\PerformanceService;
        $metric = $service->calculateDailyScore($user);

        return response()->json([
            'success' => true,
            'data' => [
                'momentum_score' => $metric->total_momentum_score,
                'subconscious' => $metric->subconscious_score,
                'conscious' => $metric->conscious_score,
                'results' => $metric->results_score,
                'streak' => $user->current_streak,
                'income_logged' => $metric->commission_earned, // This will be from separate deal logs
            ],
        ]);
    });

    // ============== LEARNING ==============

    Route::get('/learning/categories', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $categories = [
            ['name' => 'marketFundamentals', 'title' => 'Market Fundamentals', 'tier' => 'free'],
            ['name' => 'leadSystems', 'title' => 'Lead Systems', 'tier' => 'free'],
            ['name' => 'communication', 'title' => 'Communication', 'tier' => 'free'],
            ['name' => 'negotiation', 'title' => 'Negotiation', 'tier' => 'free'],
            ['name' => 'hniHandling', 'title' => 'HNI Handling', 'tier' => 'premium'],
            ['name' => 'commissionScaling', 'title' => 'Commission Scaling', 'tier' => 'premium'],
            ['name' => 'dealArchitecture', 'title' => 'Deal Architecture', 'tier' => 'premium'],
            ['name' => 'brandAuthority', 'title' => 'Brand Authority', 'tier' => 'premium'],
        ];

        return response()->json([
            'success' => true,
            'data' => $categories,
        ]);
    });

    Route::get('/learning/content', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $category = $request->get('category');

        $query = DB::table('learning_content')
            ->where('is_active', true);

        if ($category) {
            $query->where('category', $category);
        }

        // If user is not premium, only show free content
        if (! $user->is_premium) {
            $query->where('tier', 'free');
        }

        $content = $query->orderBy('order')->get();

        // Get user progress
        $progress = DB::table('user_learning_progress')
            ->where('user_id', $user->id)
            ->pluck('progress_percent', 'learning_content_id');

        $content = $content->map(function ($item) use ($progress) {
            $item->progress_percent = $progress[$item->id] ?? 0;
            $item->is_completed = ($progress[$item->id] ?? 0) >= 100;

            return $item;
        });

        return response()->json([
            'success' => true,
            'data' => $content,
        ]);
    });

    Route::post('/learning/progress', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'content_id' => ['required', 'integer', 'exists:learning_content,id'],
            'progress_percent' => ['required', 'integer', 'min:0', 'max:100'],
        ]);

        DB::table('user_learning_progress')->updateOrInsert(
            [
                'user_id' => $user->id,
                'learning_content_id' => $data['content_id'],
            ],
            [
                'progress_percent' => $data['progress_percent'],
                'is_completed' => $data['progress_percent'] >= 100,
                'last_accessed_at' => now(),
                'updated_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Progress updated',
        ]);
    });

    // ============== DASHBOARD ==============

    Route::get('/dashboard/stats', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $today = now()->toDateString();
        $weekStart = now()->startOfWeek()->toDateString();

        // Today's progress
        $todayTasks = DB::table('activities')
            ->where('user_id', $user->id)
            ->whereDate('scheduled_at', $today)
            ->selectRaw('COUNT(*) as total, SUM(CASE WHEN is_completed THEN 1 ELSE 0 END) as completed')
            ->first();

        // This week's stats
        $weekStats = DB::table('activities')
            ->where('user_id', $user->id)
            ->whereBetween('scheduled_at', [$weekStart, now()])
            ->where('is_completed', true)
            ->selectRaw("
                SUM(CASE WHEN type = 'leadOutreach' THEN 1 ELSE 0 END) as calls,
                SUM(CASE WHEN type = 'meeting' THEN 1 ELSE 0 END) as meetings,
                SUM(CASE WHEN type = 'followUp' THEN 1 ELSE 0 END) as followups,
                SUM(CASE WHEN type = 'siteVisit' THEN 1 ELSE 0 END) as site_visits
            ")
            ->first();

        return response()->json([
            'success' => true,
            'data' => [
                'growth_score' => $user->growth_score ?? 0,
                'execution_rate' => $user->execution_rate ?? 0,
                'mindset_index' => $user->mindset_index ?? 0,
                'rank' => $user->rank ?? 'Starter',
                'current_streak' => $user->current_streak ?? 0,
                'today' => [
                    'total' => $todayTasks->total ?? 0,
                    'completed' => $todayTasks->completed ?? 0,
                ],
                'this_week' => [
                    'calls' => $weekStats->calls ?? 0,
                    'meetings' => $weekStats->meetings ?? 0,
                    'followups' => $weekStats->followups ?? 0,
                    'site_visits' => $weekStats->site_visits ?? 0,
                ],
            ],
        ]);
    });
    // ============== REPORTS ==============

    Route::get('/reports/growth', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $period = $request->get('period', 'week'); // week, month, year
        $labels = [];
        $data = [];
        $today = now();

        if ($period === 'week') {
            for ($i = 6; $i >= 0; $i--) {
                $date = $today->copy()->subDays($i);
                $dateStr = $date->toDateString();
                $labels[] = $date->format('D'); // Mon, Tue

                $query = DB::table('activities')
                    ->where('user_id', $user->id)
                    ->whereDate('completed_at', $dateStr)
                    ->where('is_completed', true);

                $data[] = $query->count();
                $pointsData[] = (int) $query->sum('points');
            }
        } elseif ($period === 'month') {
            for ($i = 29; $i >= 0; $i--) {
                $date = $today->copy()->subDays($i);
                $dateStr = $date->toDateString();
                $labels[] = $date->format('d'); // 01, 02

                $query = DB::table('activities')
                    ->where('user_id', $user->id)
                    ->whereDate('completed_at', $dateStr)
                    ->where('is_completed', true);

                $data[] = $query->count();
                $pointsData[] = (int) $query->sum('points');
            }
        } elseif ($period === 'year') {
            for ($i = 11; $i >= 0; $i--) {
                $date = $today->copy()->subMonths($i);
                $month = $date->month;
                $year = $date->year;
                $labels[] = $date->format('M'); // Jan, Feb

                $query = DB::table('activities')
                    ->where('user_id', $user->id)
                    ->whereYear('completed_at', $year)
                    ->whereMonth('completed_at', $month)
                    ->where('is_completed', true);

                $data[] = $query->count();
                $pointsData[] = (int) $query->sum('points');
            }
        }

        // Get activity breakdown with points
        $breakdown = DB::table('activities')
            ->where('user_id', $user->id)
            ->where('is_completed', true)
            ->where('completed_at', '>=', $period === 'week' ? now()->subDays(7) : ($period === 'month' ? now()->subDays(30) : now()->subYear()))
            ->select('type', DB::raw('count(*) as count'), DB::raw('sum(points) as total_points'))
            ->groupBy('type')
            ->get();

        return response()->json([
            'success' => true,
            'period' => $period,
            'labels' => $labels,
            'data' => $data,
            'points_data' => $pointsData ?? [],
            'breakdown' => $breakdown,
            'growth_score' => $user->growth_score ?? 0,
            'execution_rate' => $user->execution_rate ?? 0,
            'total_rewards' => (int) DB::table('activities')->where('user_id', $user->id)->where('is_completed', true)->sum('points'),
        ]);
    });

    // ============== TASKS ==============

    Route::get('/tasks/today', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $today = now()->toDateString();

        // Get today's tasks/activities
        $tasks = DB::table('activities')
            ->where('user_id', $user->id)
            ->whereDate('scheduled_at', $today)
            ->select('id', 'title', 'description', 'is_completed', 'type')
            ->orderBy('is_completed', 'asc')
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        // Calculate completion percentage
        $totalTasks = $tasks->count();
        $completedTasks = $tasks->where('is_completed', true)->count();
        $completionRate = $totalTasks > 0 ? round(($completedTasks / $totalTasks) * 100) : 0;

        return response()->json([
            'success' => true,
            'tasks' => $tasks->map(function ($task) {
                return [
                    'id' => $task->id,
                    'title' => $task->title,
                    'description' => $task->description,
                    'is_completed' => (bool) $task->is_completed,
                    'type' => $task->type,
                ];
            }),
            'total' => $totalTasks,
            'completed' => $completedTasks,
            'completion_rate' => $completionRate,
        ]);
    });

    // ============== RESULTS TRACKER (Phase 2) ==============

    // ----- CLIENTS (Results-based) -----
    // Simple wrapper endpoints so the app can ask:
    // 1) "Does this user have any clients yet?"
    // 2) "Create the first client" (stored as a hot_lead result)
    Route::get('/clients/status', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $count = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->whereNotNull('client_name')
            ->count();

        return response()->json([
            'success' => true,
            'has_clients' => $count > 0,
            'clients_count' => $count,
        ]);
    });

    Route::post('/clients', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'client_name' => ['required', 'string', 'max:255'],
            'property_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'source' => ['sometimes', 'nullable', 'string', 'max:255'],
            'value' => ['sometimes', 'numeric', 'min:0'],
            'notes' => ['sometimes', 'nullable', 'string'],
            'status' => ['sometimes', 'string', 'in:active,converted,lost'],
        ]);

        $decoded = [];
        if (! empty($data['notes'])) {
            $decoded = json_decode($data['notes'], true) ?: [];
        }
        if (! isset($decoded['lead_stage']) || $decoded['lead_stage'] === '' || $decoded['lead_stage'] === null) {
            $decoded['lead_stage'] = 'cold calling';
        } else {
            $decoded['lead_stage'] = CrmPipeline::normalizeLeadStageString($decoded['lead_stage']) ?? $decoded['lead_stage'];
        }
        if (! isset($decoded['crm_started_at'])) {
            $decoded['crm_started_at'] = now()->toIso8601String();
        }
        if (! isset($decoded['cold_calling']) || ! is_array($decoded['cold_calling'])) {
            $decoded['cold_calling'] = ColdCallingFlow::defaultState();
        }

        $result = \App\Models\Result::create([
            'user_id' => $user->id,
            'date' => now()->toDateString(),
            'type' => 'hot_lead',
            'client_name' => $data['client_name'],
            'property_name' => $data['property_name'] ?? null,
            'source' => $data['source'] ?? null,
            'value' => $data['value'] ?? 0,
            'status' => $data['status'] ?? 'active',
            'notes' => json_encode($decoded),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Client created',
            'data' => $result,
        ], 201);
    });

    /** Upload Deal Room–format .xlsx; upserts hot_lead clients for the authenticated user. */
    Route::post('/clients/import-excel', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $request->validate([
            'file' => ['required', 'file', 'max:15360'],
        ]);

        $file = $request->file('file');
        $ext = strtolower($file->getClientOriginalExtension() ?? '');
        if ($ext !== 'xlsx') {
            return response()->json(['success' => false, 'message' => 'Please upload an Excel .xlsx file.'], 422);
        }

        $path = $file->getRealPath();
        if (! $path || ! is_readable($path)) {
            return response()->json(['success' => false, 'message' => 'Could not read the uploaded file.'], 422);
        }

        try {
            $stats = \App\Support\DealRoomExcelImport::importFromFilePath($user->id, $path);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('clients/import-excel failed', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Could not read this spreadsheet. Use the app template and try again.',
            ], 422);
        }

        $msg = sprintf(
            'Added %d client(s), updated %d.',
            $stats['created'],
            $stats['updated']
        );
        if ($stats['skipped'] > 0) {
            $msg .= sprintf(' Skipped %d row(s) with no name.', $stats['skipped']);
        }
        $msg = \App\Support\DealRoomExcelImport::appendNoRowsHint($msg, $stats);

        return response()->json([
            'success' => true,
            'message' => $msg,
            'created' => $stats['created'],
            'updated' => $stats['updated'],
            'skipped' => $stats['skipped'],
        ]);
    });

    /**
     * Cold-calling flowchart: log mode (call/whatsapp), result, optional next contact schedule.
     */
    Route::post('/clients/{id}/cold-calling/touch', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'mode' => ['required', 'string', 'in:call,whatsapp'],
            'result' => ['required', 'string', 'in:interested,exploring,not_interested,no_answer,no_reply'],
            'schedule' => ['sometimes', 'string', 'in:tomorrow,plus_2_days,custom'],
            'next_contact_date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
        ]);

        $client = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->findOrFail($id);

        $meta = [];
        if ($client->notes) {
            try {
                $decoded = json_decode($client->notes, true);
                if (is_array($decoded)) {
                    $meta = CrmPipeline::normalizeNotesMeta($decoded);
                }
            } catch (\Throwable $e) {
            }
        }

        try {
            if (($data['mode'] === 'call' && $data['result'] === 'no_reply')
                || ($data['mode'] === 'whatsapp' && $data['result'] === 'no_answer')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Use no_answer for calls and no_reply for WhatsApp.',
                ], 422);
            }

            $out = ColdCallingFlow::applyTouch($meta, $data);
            $meta = $out['meta'];
            if ($out['advanced_to_follow_up']) {
                $meta['follow_up'] = array_merge(
                    FollowUpFlow::defaultState(),
                    is_array($meta['follow_up'] ?? null) ? $meta['follow_up'] : []
                );
            }
            $date = now()->toDateString();

            if ($out['advanced_to_follow_up']) {
                $meta['daily_actions'] = $meta['daily_actions'] ?? [];
                $meta['daily_actions'][$date] = $meta['daily_actions'][$date] ?? [];
                if (! is_array($meta['daily_actions'][$date])) {
                    $meta['daily_actions'][$date] = [];
                }
                $meta['daily_actions'][$date]['cold_calling'] = 'yes';
                $meta['last_activity_date'] = $date;

                $actionLabel = 'Cold Calling';
                $notesPayload = json_encode([
                    'action_key' => 'cold_calling',
                    'action_label' => $actionLabel,
                    'parent_client_id' => (int) $id,
                ]);
                $driver = DB::connection()->getDriverName();
                $base = \App\Models\Result::where('user_id', $user->id)
                    ->where('type', 'revenue_action')
                    ->where('client_name', $client->client_name)
                    ->where('date', $date);
                $exists = $driver === 'mysql'
                    ? $base->whereRaw("JSON_UNQUOTE(JSON_EXTRACT(notes, '$.action_key')) = ?", ['cold_calling'])->exists()
                    : $base->whereRaw("json_extract(notes, '$.action_key') = ?", ['cold_calling'])->exists();
                if (! $exists) {
                    \App\Models\Result::create([
                        'user_id' => $user->id,
                        'type' => 'revenue_action',
                        'client_name' => $client->client_name,
                        'date' => $date,
                        'value' => 0,
                        'notes' => $notesPayload,
                    ]);
                }
            }

            $client->notes = json_encode($meta);
            $client->save();

            return response()->json([
                'success' => true,
                'message' => $out['message'],
                'advanced_to_follow_up' => $out['advanced_to_follow_up'],
                'data' => [
                    'client' => $client->fresh(),
                    'lead_stage' => $meta['lead_stage'] ?? null,
                    'cold_calling' => $meta['cold_calling'] ?? null,
                ],
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 422);
        }
    });

    /** Leads in cold calling due for contact today (schedule empty or date <= today). */
    Route::get('/clients/cold-calling/today', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $leads = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->whereNotNull('notes')
            ->orderByDesc('updated_at')
            ->get();

        $due = [];
        foreach ($leads as $lead) {
            try {
                $decoded = json_decode($lead->notes, true);
                if (! is_array($decoded)) {
                    continue;
                }
                $meta = CrmPipeline::normalizeNotesMeta($decoded);
                if (ColdCallingFlow::isDueForColdCallingToday($meta)) {
                    $due[] = [
                        'id' => $lead->id,
                        'client_name' => $lead->client_name,
                        'notes' => $lead->notes,
                        'created_at' => $lead->created_at?->toIso8601String(),
                        'cold_calling' => $meta['cold_calling'] ?? ColdCallingFlow::defaultState(),
                    ];
                }
            } catch (\Throwable) {
                continue;
            }
        }

        return response()->json([
            'success' => true,
            'count' => count($due),
            'data' => $due,
        ]);
    });

    /**
     * Follow-up stage: log mode (call/whatsapp/email), outcome, optional next contact.
     */
    Route::post('/clients/{id}/follow-up/touch', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'mode' => ['required', 'string', 'in:call,whatsapp,email'],
            'result' => ['required', 'string', 'in:ready_for_meeting,not_interested,continue_touch'],
            'schedule' => ['sometimes', 'string', 'in:tomorrow,plus_2_days,custom'],
            'next_contact_date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
        ]);

        $client = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->findOrFail($id);

        $meta = [];
        if ($client->notes) {
            try {
                $decoded = json_decode($client->notes, true);
                if (is_array($decoded)) {
                    $meta = CrmPipeline::normalizeNotesMeta($decoded);
                }
            } catch (\Throwable $e) {
            }
        }

        try {
            $out = FollowUpFlow::applyTouch($meta, $data);
            $meta = $out['meta'];
            if ($out['advanced_to_client_meeting']) {
                $meta['client_meeting'] = array_merge(
                    ClientMeetingFlow::defaultState(),
                    is_array($meta['client_meeting'] ?? null) ? $meta['client_meeting'] : []
                );
            }
            $date = now()->toDateString();

            if ($out['advanced_to_client_meeting']) {
                $meta['daily_actions'] = $meta['daily_actions'] ?? [];
                $meta['daily_actions'][$date] = $meta['daily_actions'][$date] ?? [];
                if (! is_array($meta['daily_actions'][$date])) {
                    $meta['daily_actions'][$date] = [];
                }
                $meta['daily_actions'][$date]['follow_up_back'] = 'yes';
                $meta['last_activity_date'] = $date;

                $actionLabel = 'Follow-up';
                $notesPayload = json_encode([
                    'action_key' => 'follow_up_back',
                    'action_label' => $actionLabel,
                    'parent_client_id' => (int) $id,
                ]);
                $driver = DB::connection()->getDriverName();
                $base = \App\Models\Result::where('user_id', $user->id)
                    ->where('type', 'revenue_action')
                    ->where('client_name', $client->client_name)
                    ->where('date', $date);
                $exists = $driver === 'mysql'
                    ? $base->whereRaw("JSON_UNQUOTE(JSON_EXTRACT(notes, '$.action_key')) = ?", ['follow_up_back'])->exists()
                    : $base->whereRaw("json_extract(notes, '$.action_key') = ?", ['follow_up_back'])->exists();
                if (! $exists) {
                    \App\Models\Result::create([
                        'user_id' => $user->id,
                        'type' => 'revenue_action',
                        'client_name' => $client->client_name,
                        'date' => $date,
                        'value' => 0,
                        'notes' => $notesPayload,
                    ]);
                }
            }

            $client->notes = json_encode($meta);
            $client->save();

            return response()->json([
                'success' => true,
                'message' => $out['message'],
                'advanced_to_client_meeting' => $out['advanced_to_client_meeting'],
                'data' => [
                    'client' => $client->fresh(),
                    'lead_stage' => $meta['lead_stage'] ?? null,
                    'follow_up' => $meta['follow_up'] ?? null,
                ],
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 422);
        }
    });

    /** Leads in follow-up due for contact today (schedule empty or date <= today; excludes stalled/retargeting). */
    Route::get('/clients/follow-up/today', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $leads = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->whereNotNull('notes')
            ->orderByDesc('updated_at')
            ->get();

        $due = [];
        foreach ($leads as $lead) {
            try {
                $decoded = json_decode($lead->notes, true);
                if (! is_array($decoded)) {
                    continue;
                }
                $meta = CrmPipeline::normalizeNotesMeta($decoded);
                if (FollowUpFlow::isDueForFollowUpToday($meta)) {
                    $due[] = [
                        'id' => $lead->id,
                        'client_name' => $lead->client_name,
                        'notes' => $lead->notes,
                        'created_at' => $lead->created_at?->toIso8601String(),
                        'follow_up' => $meta['follow_up'] ?? FollowUpFlow::defaultState(),
                    ];
                }
            } catch (\Throwable) {
                continue;
            }
        }

        return response()->json([
            'success' => true,
            'count' => count($due),
            'data' => $due,
        ]);
    });

    /**
     * Client Meeting stage: channel, outcome, optional next touch schedule.
     */
    Route::post('/clients/{id}/client-meeting/touch', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'mode' => ['required', 'string', 'in:in_person,video,call,whatsapp'],
            'result' => ['required', 'string', 'in:advance_to_negotiation,not_interested,continue_touch'],
            'schedule' => ['sometimes', 'string', 'in:tomorrow,plus_2_days,custom'],
            'next_contact_date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
        ]);

        $client = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->findOrFail($id);

        $meta = [];
        if ($client->notes) {
            try {
                $decoded = json_decode($client->notes, true);
                if (is_array($decoded)) {
                    $meta = CrmPipeline::normalizeNotesMeta($decoded);
                }
            } catch (\Throwable $e) {
            }
        }

        try {
            $out = ClientMeetingFlow::applyTouch($meta, $data);
            $meta = $out['meta'];
            if ($out['advanced_to_deal_negotiation']) {
                $meta['deal_negotiation'] = array_merge(
                    DealNegotiationFlow::defaultState(),
                    is_array($meta['deal_negotiation'] ?? null) ? $meta['deal_negotiation'] : []
                );
            }
            $date = now()->toDateString();

            if ($out['advanced_to_deal_negotiation']) {
                $meta['daily_actions'] = $meta['daily_actions'] ?? [];
                $meta['daily_actions'][$date] = $meta['daily_actions'][$date] ?? [];
                if (! is_array($meta['daily_actions'][$date])) {
                    $meta['daily_actions'][$date] = [];
                }
                $meta['daily_actions'][$date]['client_meeting'] = 'yes';
                $meta['last_activity_date'] = $date;

                $actionLabel = 'Client Meeting';
                $notesPayload = json_encode([
                    'action_key' => 'client_meeting',
                    'action_label' => $actionLabel,
                    'parent_client_id' => (int) $id,
                ]);
                $driver = DB::connection()->getDriverName();
                $base = \App\Models\Result::where('user_id', $user->id)
                    ->where('type', 'revenue_action')
                    ->where('client_name', $client->client_name)
                    ->where('date', $date);
                $exists = $driver === 'mysql'
                    ? $base->whereRaw("JSON_UNQUOTE(JSON_EXTRACT(notes, '$.action_key')) = ?", ['client_meeting'])->exists()
                    : $base->whereRaw("json_extract(notes, '$.action_key') = ?", ['client_meeting'])->exists();
                if (! $exists) {
                    \App\Models\Result::create([
                        'user_id' => $user->id,
                        'type' => 'revenue_action',
                        'client_name' => $client->client_name,
                        'date' => $date,
                        'value' => 0,
                        'notes' => $notesPayload,
                    ]);
                }
            }

            $client->notes = json_encode($meta);
            $client->save();

            return response()->json([
                'success' => true,
                'message' => $out['message'],
                'advanced_to_deal_negotiation' => $out['advanced_to_deal_negotiation'],
                'data' => [
                    'client' => $client->fresh(),
                    'lead_stage' => $meta['lead_stage'] ?? null,
                    'client_meeting' => $meta['client_meeting'] ?? null,
                ],
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 422);
        }
    });

    Route::get('/clients/client-meeting/today', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $leads = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->whereNotNull('notes')
            ->orderByDesc('updated_at')
            ->get();

        $due = [];
        foreach ($leads as $lead) {
            try {
                $decoded = json_decode($lead->notes, true);
                if (! is_array($decoded)) {
                    continue;
                }
                $meta = CrmPipeline::normalizeNotesMeta($decoded);
                if (ClientMeetingFlow::isDueForClientMeetingToday($meta)) {
                    $due[] = [
                        'id' => $lead->id,
                        'client_name' => $lead->client_name,
                        'notes' => $lead->notes,
                        'created_at' => $lead->created_at?->toIso8601String(),
                        'client_meeting' => $meta['client_meeting'] ?? ClientMeetingFlow::defaultState(),
                    ];
                }
            } catch (\Throwable) {
                continue;
            }
        }

        return response()->json([
            'success' => true,
            'count' => count($due),
            'data' => $due,
        ]);
    });

    /**
     * Deal Negotiation stage.
     */
    Route::post('/clients/{id}/deal-negotiation/touch', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'mode' => ['required', 'string', 'in:in_person,video,call,whatsapp,email'],
            'result' => ['required', 'string', 'in:advance_to_closure,not_interested,continue_touch'],
            'schedule' => ['sometimes', 'string', 'in:tomorrow,plus_2_days,custom'],
            'next_contact_date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
        ]);

        $client = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->findOrFail($id);

        $meta = [];
        if ($client->notes) {
            try {
                $decoded = json_decode($client->notes, true);
                if (is_array($decoded)) {
                    $meta = CrmPipeline::normalizeNotesMeta($decoded);
                }
            } catch (\Throwable $e) {
            }
        }

        try {
            $out = DealNegotiationFlow::applyTouch($meta, $data);
            $meta = $out['meta'];
            if ($out['advanced_to_deal_close']) {
                $meta['deal_closure'] = array_merge(
                    DealClosureFlow::defaultState(),
                    is_array($meta['deal_closure'] ?? null) ? $meta['deal_closure'] : []
                );
            }
            $date = now()->toDateString();

            if ($out['advanced_to_deal_close']) {
                $meta['daily_actions'] = $meta['daily_actions'] ?? [];
                $meta['daily_actions'][$date] = $meta['daily_actions'][$date] ?? [];
                if (! is_array($meta['daily_actions'][$date])) {
                    $meta['daily_actions'][$date] = [];
                }
                $meta['daily_actions'][$date]['deal_negotiation'] = 'yes';
                $meta['last_activity_date'] = $date;

                $actionLabel = 'Deal Negotiation';
                $notesPayload = json_encode([
                    'action_key' => 'deal_negotiation',
                    'action_label' => $actionLabel,
                    'parent_client_id' => (int) $id,
                ]);
                $driver = DB::connection()->getDriverName();
                $base = \App\Models\Result::where('user_id', $user->id)
                    ->where('type', 'revenue_action')
                    ->where('client_name', $client->client_name)
                    ->where('date', $date);
                $exists = $driver === 'mysql'
                    ? $base->whereRaw("JSON_UNQUOTE(JSON_EXTRACT(notes, '$.action_key')) = ?", ['deal_negotiation'])->exists()
                    : $base->whereRaw("json_extract(notes, '$.action_key') = ?", ['deal_negotiation'])->exists();
                if (! $exists) {
                    \App\Models\Result::create([
                        'user_id' => $user->id,
                        'type' => 'revenue_action',
                        'client_name' => $client->client_name,
                        'date' => $date,
                        'value' => 0,
                        'notes' => $notesPayload,
                    ]);
                }
            }

            $client->notes = json_encode($meta);
            $client->save();

            return response()->json([
                'success' => true,
                'message' => $out['message'],
                'advanced_to_deal_close' => $out['advanced_to_deal_close'],
                'data' => [
                    'client' => $client->fresh(),
                    'lead_stage' => $meta['lead_stage'] ?? null,
                    'deal_negotiation' => $meta['deal_negotiation'] ?? null,
                ],
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 422);
        }
    });

    Route::get('/clients/deal-negotiation/today', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $leads = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->whereNotNull('notes')
            ->orderByDesc('updated_at')
            ->get();

        $due = [];
        foreach ($leads as $lead) {
            try {
                $decoded = json_decode($lead->notes, true);
                if (! is_array($decoded)) {
                    continue;
                }
                $meta = CrmPipeline::normalizeNotesMeta($decoded);
                if (DealNegotiationFlow::isDueForNegotiationToday($meta)) {
                    $due[] = [
                        'id' => $lead->id,
                        'client_name' => $lead->client_name,
                        'notes' => $lead->notes,
                        'created_at' => $lead->created_at?->toIso8601String(),
                        'deal_negotiation' => $meta['deal_negotiation'] ?? DealNegotiationFlow::defaultState(),
                    ];
                }
            } catch (\Throwable) {
                continue;
            }
        }

        return response()->json([
            'success' => true,
            'count' => count($due),
            'data' => $due,
        ]);
    });

    /**
     * Deal Closure stage (paperwork follow-up / lost — recording a win still uses action-log deal_closed from the app).
     */
    Route::post('/clients/{id}/deal-closure/touch', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'mode' => ['required', 'string', 'in:call,whatsapp,email'],
            'result' => ['required', 'string', 'in:lost,continue_touch'],
            'schedule' => ['sometimes', 'string', 'in:tomorrow,plus_2_days,custom'],
            'next_contact_date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
        ]);

        $client = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->findOrFail($id);

        $meta = [];
        if ($client->notes) {
            try {
                $decoded = json_decode($client->notes, true);
                if (is_array($decoded)) {
                    $meta = CrmPipeline::normalizeNotesMeta($decoded);
                }
            } catch (\Throwable $e) {
            }
        }

        try {
            $out = DealClosureFlow::applyTouch($meta, $data);
            $meta = $out['meta'];

            $client->notes = json_encode($meta);
            $client->save();

            return response()->json([
                'success' => true,
                'message' => $out['message'],
                'data' => [
                    'client' => $client->fresh(),
                    'lead_stage' => $meta['lead_stage'] ?? null,
                    'deal_closure' => $meta['deal_closure'] ?? null,
                ],
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 422);
        }
    });

    Route::get('/clients/deal-closure/today', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $leads = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->whereNotNull('notes')
            ->orderByDesc('updated_at')
            ->get();

        $due = [];
        foreach ($leads as $lead) {
            try {
                $decoded = json_decode($lead->notes, true);
                if (! is_array($decoded)) {
                    continue;
                }
                $meta = CrmPipeline::normalizeNotesMeta($decoded);
                if (DealClosureFlow::isDueForDealClosureToday($meta)) {
                    $due[] = [
                        'id' => $lead->id,
                        'client_name' => $lead->client_name,
                        'notes' => $lead->notes,
                        'created_at' => $lead->created_at?->toIso8601String(),
                        'deal_closure' => $meta['deal_closure'] ?? DealClosureFlow::defaultState(),
                    ];
                }
            } catch (\Throwable) {
                continue;
            }
        }

        return response()->json([
            'success' => true,
            'count' => count($due),
            'data' => $due,
        ]);
    });

    // Per-client daily execution progress (what % of today's actions are completed)
    Route::get('/clients/{id}/daily-progress', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $client = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->findOrFail($id);

        $date = $request->get('date', now()->toDateString());
        if (! is_string($date) || ! preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            $date = now()->toDateString();
        }

        $meta = [];
        if ($client->notes) {
            try {
                $decoded = json_decode($client->notes, true);
                if (is_array($decoded)) {
                    $meta = CrmPipeline::normalizeNotesMeta($decoded);
                }
            } catch (\Throwable $e) {
            }
        }

        // Same five keys as /clients/{id}/actions (Deal Room pipeline)
        $config = array_column(CrmPipeline::ACTION_CONFIG, 'key');

        $total = count($config);

        $dailyActions = $meta['daily_actions'] ?? [];
        $storedActions = is_array($dailyActions) ? ($dailyActions[$date] ?? []) : [];

        // Backward compatibility: old structure stored in meta['actions'] for "today"
        if (empty($storedActions) && isset($meta['actions']) && is_array($meta['actions']) && $date === now()->toDateString()) {
            $storedActions = $meta['actions'];
        }

        $completed = 0;
        foreach ($config as $key) {
            if (($storedActions[$key] ?? null) === 'yes') {
                $completed++;
            }
        }

        $percentage = $total > 0 ? (int) round(($completed / $total) * 100) : 0;

        $status = $percentage === 0
            ? 'none'
            : ($percentage < 50 ? 'low' : ($percentage < 80 ? 'medium' : 'high'));

        return response()->json([
            'success' => true,
            'data' => [
                'date' => $date,
                'total_actions' => $total,
                'completed_actions' => $completed,
                'percentage' => $percentage,
                'status' => $status,
            ],
        ]);
    });

    // Per-client revenue actions (Cold Call Block, Follow-up Block, etc.)
    Route::get('/clients/{id}/actions', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $client = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->findOrFail($id);

        $date = $request->get('date', now()->toDateString());
        if (! is_string($date) || ! preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            $date = now()->toDateString();
        }

        $meta = [];
        if ($client->notes) {
            try {
                $decoded = json_decode($client->notes, true);
                if (is_array($decoded)) {
                    $meta = CrmPipeline::normalizeNotesMeta($decoded);
                }
            } catch (\Throwable $e) {
            }
        }

        $dailyActions = $meta['daily_actions'] ?? [];
        $storedActions = is_array($dailyActions) ? ($dailyActions[$date] ?? []) : [];

        // Backward compatibility: old structure stored in meta['actions']
        if (empty($storedActions) && isset($meta['actions']) && is_array($meta['actions']) && $date === now()->toDateString()) {
            $storedActions = $meta['actions'];
        }

        $config = CrmPipeline::ACTION_CONFIG;

        $actions = array_map(function ($item) use ($storedActions) {
            $key = $item['key'];
            $status = $storedActions[$key] ?? null;

            return [
                'key' => $key,
                'label' => $item['label'],
                'status' => $status, // 'yes' | 'no' | null
            ];
        }, $config);

        // Backfill: ensure revenue_action records exist for any action marked "yes"
        // (handles actions set before the revenue_action enum was added)
        $actionLabels = CrmPipeline::ACTION_LABELS;
        $driver = DB::connection()->getDriverName();
        foreach ($storedActions as $actionKey => $status) {
            if ($status !== 'yes' || ! is_string($actionKey)) {
                continue;
            }
            $normalizedKey = CrmPipeline::normalizeActionKey($actionKey);
            $actionLabel = $actionLabels[$normalizedKey] ?? $actionLabels[$actionKey] ?? ucfirst(str_replace('_', ' ', $normalizedKey));
            $exists = \App\Models\Result::where('user_id', $user->id)
                ->where('type', 'revenue_action')
                ->where('client_name', $client->client_name)
                ->where('date', $date);
            $exists = $driver === 'mysql'
                ? $exists->where(function ($q) use ($actionKey, $normalizedKey) {
                    $q->whereRaw("JSON_UNQUOTE(JSON_EXTRACT(notes, '$.action_key')) = ?", [$actionKey])
                        ->orWhereRaw("JSON_UNQUOTE(JSON_EXTRACT(notes, '$.action_key')) = ?", [$normalizedKey]);
                })->exists()
                : $exists->where(function ($q) use ($actionKey, $normalizedKey) {
                    $q->whereRaw("json_extract(notes, '$.action_key') = ?", [$actionKey])
                        ->orWhereRaw("json_extract(notes, '$.action_key') = ?", [$normalizedKey]);
                })->exists();
            if (! $exists) {
                try {
                    \App\Models\Result::create([
                        'user_id' => $user->id,
                        'type' => 'revenue_action',
                        'client_name' => $client->client_name,
                        'date' => $date,
                        'value' => 0,
                        'notes' => json_encode([
                            'action_key' => $normalizedKey,
                            'action_label' => $actionLabel,
                            'parent_client_id' => (int) $id,
                        ]),
                    ]);
                } catch (\Throwable $e) {
                }
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'client' => $client,
                'date' => $date,
                'actions' => $actions,
            ],
        ]);
    });

    Route::post('/clients/{id}/actions', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'action_key' => ['required', 'string', 'max:255'],
            'status' => ['required', 'string', 'in:yes,no'],
            'date' => ['sometimes', 'date'],
            'package_status' => ['sometimes', 'string', 'in:hot,nurture,blocker'],
        ]);

        $data['action_key'] = CrmPipeline::normalizeActionKey($data['action_key']);

        $client = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->findOrFail($id);

        $date = $data['date'] ?? now()->toDateString();

        $meta = [];
        if ($client->notes) {
            try {
                $decoded = json_decode($client->notes, true);
                if (is_array($decoded)) {
                    $meta = CrmPipeline::normalizeNotesMeta($decoded);
                }
            } catch (\Throwable $e) {
            }
        }

        $meta['daily_actions'] = $meta['daily_actions'] ?? [];
        if (! is_array($meta['daily_actions'])) {
            $meta['daily_actions'] = [];
        }
        $meta['daily_actions'][$date] = $meta['daily_actions'][$date] ?? [];
        if (! is_array($meta['daily_actions'][$date])) {
            $meta['daily_actions'][$date] = [];
        }
        $previousStatus = $meta['daily_actions'][$date][$data['action_key']] ?? null;
        $meta['daily_actions'][$date][$data['action_key']] = $data['status'];

        if (isset($data['package_status'])) {
            $meta['lead_package'] = $data['package_status'];
        }

        $client->notes = json_encode($meta);
        $client->save();

        Log::info('[DAILY_LOG_DEBUG] POST /clients/'.$id.'/actions', [
            'action_key' => $data['action_key'],
            'status' => $data['status'],
            'date' => $date,
            'previousStatus' => $previousStatus,
        ]);

        // When status is "yes", create a Result so it appears in Activity for this client.
        // Only create if one doesn't exist yet (handles backfill for actions set to Yes before migration).
        if ($data['status'] === 'yes' && $data['action_key'] !== 'update_package') {
            $actionLabels = CrmPipeline::ACTION_LABELS;
            $actionLabel = $actionLabels[$data['action_key']] ?? ucfirst(str_replace('_', ' ', $data['action_key']));
            $notesPayload = json_encode([
                'action_key' => $data['action_key'],
                'action_label' => $actionLabel,
                'parent_client_id' => (int) $id,
            ]);

            // Avoid duplicates: check if we already have this revenue_action for client+date+action_key
            $driver = DB::connection()->getDriverName();
            $base = \App\Models\Result::where('user_id', $user->id)
                ->where('type', 'revenue_action')
                ->where('client_name', $client->client_name)
                ->where('date', $date);
            $exists = $driver === 'mysql'
                ? $base->where(function ($q) use ($data) {
                    $q->whereRaw("JSON_UNQUOTE(JSON_EXTRACT(notes, '$.action_key')) = ?", [$data['action_key']])
                        ->orWhereRaw("JSON_UNQUOTE(JSON_EXTRACT(notes, '$.action_key')) = ?", ['site_visit']);
                })->exists()
                : $base->where(function ($q) use ($data) {
                    $q->whereRaw("json_extract(notes, '$.action_key') = ?", [$data['action_key']])
                        ->orWhereRaw("json_extract(notes, '$.action_key') = ?", ['site_visit']);
                })->exists();

            if (! $exists) {
                try {
                    $result = \App\Models\Result::create([
                        'user_id' => $user->id,
                        'type' => 'revenue_action',
                        'client_name' => $client->client_name,
                        'date' => $date,
                        'value' => 0,
                        'notes' => $notesPayload,
                    ]);
                    Log::info('[DAILY_LOG_DEBUG] Created revenue_action Result', ['id' => $result->id, 'client_name' => $client->client_name, 'action_label' => $actionLabel]);
                } catch (\Throwable $e) {
                    Log::error('[DAILY_LOG_DEBUG] Failed to create Result', ['error' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
                }
            }
        }

        if ($data['status'] === 'yes' && $data['action_key'] !== 'update_package') {
            // Update the lead's current stage in notes
            $currentStage = CrmPipeline::humanStageFromActionKey($data['action_key']);
            $meta['lead_stage'] = $currentStage;
            $meta['last_activity_date'] = $date;

            // Auto-advance if not final stage
            $stages = CrmPipeline::ORDERED_STAGE_STRINGS;
            $currentIndex = array_search($currentStage, $stages, true);
            if ($currentIndex !== false && $currentIndex < count($stages) - 1) {
                $meta['lead_stage'] = $stages[$currentIndex + 1];
            }

            $client->notes = json_encode($meta);
            $client->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Action updated',
            'lead_stage' => $meta['lead_stage'] ?? null,
        ]);
    });

    // ─── Save detailed action log for a client (cold call, site visit, negotiation, referral, deal closed) ───
    Route::post('/clients/{id}/action-log', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'action_type' => ['required', 'string', 'in:cold_call,site_visit,deal_negotiation,deal_closed,referral_ask'],
            'date' => ['sometimes', 'date'],
            'payload' => ['required', 'array'],
        ]);

        $client = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->findOrFail($id);

        $date = $data['date'] ?? now()->toDateString();
        $type = $data['action_type'];
        $payload = $data['payload'];

        $meta = [];
        if ($client->notes) {
            try {
                $decoded = json_decode($client->notes, true);
                if (is_array($decoded)) {
                    $meta = $decoded;
                }
            } catch (\Throwable $e) {
            }
        }

        // Store under action_logs -> date -> type (array of entries for that day)
        $meta['action_logs'] = $meta['action_logs'] ?? [];
        $meta['action_logs'][$date] = $meta['action_logs'][$date] ?? [];
        $meta['action_logs'][$date][$type] = $meta['action_logs'][$date][$type] ?? [];
        $meta['action_logs'][$date][$type][] = array_merge($payload, [
            'logged_at' => now()->toIso8601String(),
        ]);

        // If deal_closed, also create a result record for the performance pipeline
        if ($type === 'deal_closed') {
            $dealValue = floatval($payload['deal_amount'] ?? 0);
            $commission = floatval($payload['commission'] ?? 0);

            if ($dealValue > 0 || $commission > 0) {
                \App\Models\Result::create([
                    'user_id' => $user->id,
                    'type' => 'deal_closed',
                    'client_name' => $client->client_name,
                    'property_name' => $payload['deal_type'] ?? null,
                    'value' => $dealValue,
                    'notes' => json_encode([
                        'deal_type' => $payload['deal_type'] ?? null,
                        'commission' => $commission,
                        'parent_client_id' => $client->id,
                    ]),
                    'date' => $date,
                ]);
            }
        }

        $client->notes = json_encode($meta);
        $client->save();

        return response()->json([
            'success' => true,
            'message' => ucfirst(str_replace('_', ' ', $type)).' logged successfully',
        ]);
    });

    // ─── Get activities for a client (for client-specific activity list) ───
    Route::get('/clients/{id}/activities', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $client = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->findOrFail($id);

        $clientName = $client->client_name;
        $clientIdStr = (string) $id;
        $driver = DB::connection()->getDriverName();

        // Include: (a) by client_name match, (b) revenue_actions linked via parent_client_id in notes
        $activities = \App\Models\Result::where('user_id', $user->id)
            ->where(function ($q) use ($clientName, $clientIdStr, $driver) {
                $q->where('client_name', $clientName);
                if ($driver === 'mysql') {
                    $q->orWhereRaw("type = 'revenue_action' AND JSON_UNQUOTE(JSON_EXTRACT(notes, '$.parent_client_id')) = ?", [$clientIdStr]);
                } else {
                    $q->orWhereRaw("type = 'revenue_action' AND json_extract(notes, '$.parent_client_id') = ?", [$clientIdStr]);
                }
            })
            ->orderByDesc('created_at')
            ->limit(50)
            ->get(['id', 'type', 'client_name', 'value', 'source', 'date', 'created_at', 'notes']);

        return response()->json([
            'success' => true,
            'data' => $activities,
        ]);
    });

    // ─── Get action logs for a client on a specific date ───
    Route::get('/clients/{id}/action-logs', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $client = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->findOrFail($id);

        $date = $request->query('date', now()->toDateString());

        $meta = [];
        if ($client->notes) {
            try {
                $decoded = json_decode($client->notes, true);
                if (is_array($decoded)) {
                    $meta = $decoded;
                }
            } catch (\Throwable $e) {
            }
        }

        $logs = ($meta['action_logs'] ?? [])[$date] ?? [];

        return response()->json([
            'success' => true,
            'data' => [
                'client_id' => $id,
                'date' => $date,
                'logs' => $logs,
            ],
        ]);
    });

    // Log a result (hot lead, deal closed, commission)
    Route::post('/results', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'type' => ['required', 'string', 'in:hot_lead,deal_closed,commission'],
            'client_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'property_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'source' => ['sometimes', 'nullable', 'string', 'in:bayut,property_finder,instagram,referral,cold_call,walk_in,linkedin,other'],
            'value' => ['sometimes', 'numeric', 'min:0'],
            'notes' => ['sometimes', 'nullable', 'string'],
            'date' => ['sometimes', 'date'],
        ]);

        $result = \App\Models\Result::create([
            'user_id' => $user->id,
            'date' => $data['date'] ?? now()->toDateString(),
            'type' => $data['type'],
            'client_name' => $data['client_name'] ?? null,
            'property_name' => $data['property_name'] ?? null,
            'source' => $data['source'] ?? null,
            'value' => $data['value'] ?? 0,
            'notes' => $data['notes'] ?? null,
        ]);

        // Update performance metrics
        $service = new \App\Services\PerformanceService;
        $metric = $service->calculateDailyScore($user);

        // Check badges
        $badgeService = new \App\Services\BadgeService;
        $newBadges = $badgeService->checkAndAwardBadges($user);

        // Update user total commission
        if ($data['type'] === 'commission' || $data['type'] === 'deal_closed') {
            $totalCommission = \App\Models\Result::where('user_id', $user->id)
                ->whereIn('type', ['commission', 'deal_closed'])
                ->sum('value');
            $user->update(['total_commission' => $totalCommission]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Result logged successfully',
            'data' => [
                'result' => $result,
                'daily_score' => $metric->total_momentum_score,
                'results_score' => $metric->results_score,
                'new_badges' => $newBadges,
            ],
        ]);
    });

    // Get results (filterable by type, date range)
    Route::get('/results', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $query = \App\Models\Result::where('user_id', $user->id);

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }
        if ($request->has('source') && $request->query('type') === 'hot_lead') {
            $query->where('source', $request->source);
        }
        if ($request->has('from')) {
            $query->where('date', '>=', $request->from);
        }
        if ($request->has('to')) {
            $query->where('date', '<=', $request->to);
        }

        $results = $query->orderByDesc('date')->orderByDesc('created_at')->get();

        // Attach today's execution progress for hot_leads (used by Deal Room client list)
        if ($request->query('type') === 'hot_lead') {
            $today = $request->query('date', now()->toDateString());

            $configKeys = [
                'cold_call_block',
                'follow_up_block',
                'client_meeting',
                'site_visit',
                'content_creation',
                'content_posting',
                'prospecting_session',
                'deal_negotiation',
                'crm_update',
                'referral_ask',
                'deal_closed',
                'network_event',
                'proposal_sent',
            ];
            $totalActions = count($configKeys);

            $results = $results->map(function ($result) use ($today, $configKeys, $totalActions) {
                $meta = [];
                if ($result->notes) {
                    try {
                        $decoded = json_decode($result->notes, true);
                        if (is_array($decoded)) {
                            $meta = $decoded;
                        }
                    } catch (\Throwable $e) {
                    }
                }

                $dailyActions = $meta['daily_actions'] ?? [];
                $storedActions = is_array($dailyActions) ? ($dailyActions[$today] ?? []) : [];

                // Backward compatibility: old structure stored in meta['actions'] for "today"
                if (empty($storedActions) && isset($meta['actions']) && is_array($meta['actions']) && $today === now()->toDateString()) {
                    $storedActions = $meta['actions'];
                }

                $completed = 0;
                foreach ($configKeys as $key) {
                    if (($storedActions[$key] ?? null) === 'yes') {
                        $completed++;
                    }
                }

                $percentage = $totalActions > 0 ? (int) round(($completed / $totalActions) * 100) : 0;

                $status = $percentage === 0
                    ? 'none'
                    : ($percentage < 50 ? 'low' : ($percentage < 80 ? 'medium' : 'high'));

                $result->today_progress = [
                    'date' => $today,
                    'total_actions' => $totalActions,
                    'completed_actions' => $completed,
                    'percentage' => $percentage,
                    'status' => $status,
                ];

                return $result;
            });
        }

        // Summary
        $monthStart = now()->startOfMonth()->toDateString();
        $summary = [
            'hot_leads' => \App\Models\Result::where('user_id', $user->id)->where('type', 'hot_lead')->where('date', '>=', $monthStart)->count(),
            'deals_closed' => \App\Models\Result::where('user_id', $user->id)->where('type', 'deal_closed')->where('date', '>=', $monthStart)->count(),
            'total_commission' => (float) \App\Models\Result::where('user_id', $user->id)->whereIn('type', ['commission', 'deal_closed'])->where('date', '>=', $monthStart)->sum('value'),
            'conversion_rate' => 0,
        ];

        $totalLeads = \App\Models\Result::where('user_id', $user->id)->where('type', 'hot_lead')->where('date', '>=', $monthStart)->count();
        if ($totalLeads > 0) {
            $summary['conversion_rate'] = round(($summary['deals_closed'] / $totalLeads) * 100, 1);
        }

        return response()->json([
            'success' => true,
            'data' => $results,
            'summary' => $summary,
        ]);
    });

    // ─── Revenue Tracker key metrics (Week / Month / Quarter) ───
    Route::get('/revenue/metrics', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $period = $request->query('period', 'month'); // week | month | quarter
        $now = now();

        switch ($period) {
            case 'week':
                $from = $now->copy()->startOfWeek()->toDateString();
                break;
            case 'quarter':
                $from = $now->copy()->firstOfQuarter()->toDateString();
                break;
            default: // month
                $from = $now->copy()->startOfMonth()->toDateString();
                break;
        }
        $to = $now->toDateString();

        // Key metrics: distinct clients / deals (avoids duplicate rows inflating totals)
        $hotLeads = (int) \App\Models\Result::query()
            ->where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->whereNotNull('client_name')
            ->where('client_name', '!=', '')
            ->selectRaw('COUNT(DISTINCT client_name) as c')
            ->value('c');

        $dealsClosed = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'deal_closed')
            ->whereNotNull('client_name')
            ->where('client_name', '!=', '')
            ->count();

        // Net commission: from type=commission (value) + deal_closed (notes.commission)
        $commissionFromDeals = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'deal_closed')
            ->get()
            ->sum(function ($r) {
                $notes = is_string($r->notes) ? json_decode($r->notes, true) : $r->notes;

                return is_array($notes) ? (float) ($notes['commission'] ?? 0) : 0;
            });
        $commissionFromType = (float) \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'commission')
            ->sum('value');
        $totalCommission = $commissionFromDeals + $commissionFromType;

        // Top source: most common source among all hot_leads (clients)
        $topSourceRow = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->whereNotNull('source')
            ->where('source', '!=', '')
            ->selectRaw('source, COUNT(*) as cnt')
            ->groupBy('source')
            ->orderByDesc('cnt')
            ->first();

        $topSource = $topSourceRow ? $topSourceRow->source : null;

        // Previous period for comparison
        switch ($period) {
            case 'week':
                $prevFrom = $now->copy()->subWeek()->startOfWeek()->toDateString();
                $prevTo = $now->copy()->subWeek()->endOfWeek()->toDateString();
                break;
            case 'quarter':
                $prevFrom = $now->copy()->subQuarter()->firstOfQuarter()->toDateString();
                $prevTo = $now->copy()->subQuarter()->lastOfQuarter()->toDateString();
                break;
            default:
                $prevFrom = $now->copy()->subMonth()->startOfMonth()->toDateString();
                $prevTo = $now->copy()->subMonth()->endOfMonth()->toDateString();
                break;
        }

        // Period-on-period: distinct client names with activity in each window (aligns with CRM client counts)
        $periodLeads = (int) \App\Models\Result::query()
            ->where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->whereBetween('date', [$from, $to])
            ->whereNotNull('client_name')
            ->where('client_name', '!=', '')
            ->selectRaw('COUNT(DISTINCT client_name) as c')
            ->value('c');
        $periodDeals = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'deal_closed')
            ->whereBetween('date', [$from, $to])
            ->whereNotNull('client_name')
            ->where('client_name', '!=', '')
            ->count();
        $prevLeads = (int) \App\Models\Result::query()
            ->where('user_id', $user->id)
            ->where('type', 'hot_lead')
            ->whereBetween('date', [$prevFrom, $prevTo])
            ->whereNotNull('client_name')
            ->where('client_name', '!=', '')
            ->selectRaw('COUNT(DISTINCT client_name) as c')
            ->value('c');
        $prevDeals = \App\Models\Result::where('user_id', $user->id)
            ->where('type', 'deal_closed')
            ->whereBetween('date', [$prevFrom, $prevTo])
            ->whereNotNull('client_name')
            ->where('client_name', '!=', '')
            ->count();

        $leadsChange = $prevLeads > 0 ? round((($periodLeads - $prevLeads) / $prevLeads) * 100) : ($periodLeads > 0 ? 100 : 0);
        $dealsChange = $prevDeals > 0 ? round((($periodDeals - $prevDeals) / $prevDeals) * 100) : ($periodDeals > 0 ? 100 : 0);

        // Recent activity: newest-first, one row per client name (avoids repeated "test 22" from many revenue_action rows)
        $recentCandidates = \App\Models\Result::where('user_id', $user->id)
            ->whereIn('type', ['hot_lead', 'deal_closed', 'revenue_action', 'commission'])
            ->orderByDesc('created_at')
            ->limit(80)
            ->get(['id', 'type', 'client_name', 'value', 'source', 'date', 'created_at', 'notes']);
        $seenNames = [];
        $recentActivity = collect();
        foreach ($recentCandidates as $row) {
            $nameKey = strtolower(trim((string) ($row->client_name ?? '')));
            if ($nameKey === '') {
                $nameKey = 'id:'.$row->id;
            }
            if (isset($seenNames[$nameKey])) {
                continue;
            }
            $seenNames[$nameKey] = true;
            $recentActivity->push($row);
            if ($recentActivity->count() >= 10) {
                break;
            }
        }

        Log::info('[REVENUE_DEBUG] GET /revenue/metrics', [
            'period' => $period,
            'from' => $from,
            'to' => $to,
            'recent_activity_count' => $recentActivity->count(),
            'types' => $recentActivity->pluck('type')->toArray(),
        ]);

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $period,
                'from' => $from,
                'to' => $to,
                'hot_leads' => $hotLeads,
                'deals_closed' => $dealsClosed,
                'total_commission' => $totalCommission,
                'top_source' => $topSource,
                'leads_change' => $leadsChange,
                'deals_change' => $dealsChange,
                'recent_activity' => $recentActivity,
            ],
        ]);
    });

    // Monthly results graph data
    Route::get('/results/monthly-graph', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $months = [];
        for ($i = 5; $i >= 0; $i--) {
            $date = now()->subMonths($i);
            $monthStart = $date->copy()->startOfMonth()->toDateString();
            $monthEnd = $date->copy()->endOfMonth()->toDateString();

            $leads = \App\Models\Result::where('user_id', $user->id)
                ->where('type', 'hot_lead')
                ->whereBetween('date', [$monthStart, $monthEnd])
                ->count();

            $deals = \App\Models\Result::where('user_id', $user->id)
                ->where('type', 'deal_closed')
                ->whereBetween('date', [$monthStart, $monthEnd])
                ->count();

            $commission = \App\Models\Result::where('user_id', $user->id)
                ->whereIn('type', ['commission', 'deal_closed'])
                ->whereBetween('date', [$monthStart, $monthEnd])
                ->sum('value');

            $months[] = [
                'label' => $date->format('M'),
                'leads' => $leads,
                'deals' => $deals,
                'commission' => (float) $commission,
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $months,
        ]);
    });

    // ============== FOLLOW-UP DISCIPLINE GUARD (Phase 2) ==============

    Route::post('/follow-ups', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $data = $request->validate([
            'result_id' => ['sometimes', 'nullable', 'integer'],
            'client_name' => ['required', 'string', 'max:255'],
            'contact_info' => ['sometimes', 'nullable', 'string', 'max:255'],
            'due_at' => ['required', 'date'],
            'notes' => ['sometimes', 'nullable', 'string'],
            'priority' => ['sometimes', 'integer', 'in:1,2,3'],
        ]);

        $followUp = \App\Models\FollowUp::create([
            'user_id' => $user->id,
            'result_id' => $data['result_id'] ?? null,
            'client_name' => $data['client_name'],
            'contact_info' => $data['contact_info'] ?? null,
            'due_at' => $data['due_at'],
            'notes' => $data['notes'] ?? null,
            'priority' => $data['priority'] ?? 1,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Follow-up created',
            'data' => $followUp,
        ]);
    });

    Route::get('/follow-ups', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        // Mark overdue ones
        \App\Models\FollowUp::where('user_id', $user->id)
            ->where('is_completed', false)
            ->where('due_at', '<', now())
            ->update(['is_overdue' => true]);

        $pending = \App\Models\FollowUp::where('user_id', $user->id)
            ->where('is_completed', false)
            ->orderBy('priority', 'desc')
            ->orderBy('due_at')
            ->get();

        $completed = \App\Models\FollowUp::where('user_id', $user->id)
            ->where('is_completed', true)
            ->orderByDesc('completed_at')
            ->limit(10)
            ->get();

        $overdueCount = $pending->where('is_overdue', true)->count();

        return response()->json([
            'success' => true,
            'data' => [
                'pending' => $pending,
                'completed' => $completed,
                'overdue_count' => $overdueCount,
                // Follow-up Discipline Guard: alert message if overdue
                'guard_alert' => $overdueCount > 0
                    ? "⚠️ You have {$overdueCount} overdue follow-up(s). Hot leads cool down fast — reach out now!"
                    : null,
            ],
        ]);
    });

    Route::put('/follow-ups/{id}/complete', function (Request $request, $id) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $followUp = \App\Models\FollowUp::where('user_id', $user->id)->findOrFail($id);
        $followUp->update([
            'is_completed' => true,
            'completed_at' => now(),
            'is_overdue' => false,
        ]);

        // Log as a follow_up activity for points
        $service = new \App\Services\PerformanceService;
        $points = $service->getActivityPoints('followUp');

        \App\Models\Activity::create([
            'user_id' => $user->id,
            'title' => "Follow-up: {$followUp->client_name}",
            'type' => 'followUp',
            'category' => 'conscious',
            'points' => $points,
            'is_completed' => true,
            'completed_at' => now(),
        ]);

        $service->updateStreak($user);
        $metric = $service->calculateDailyScore($user);

        return response()->json([
            'success' => true,
            'message' => 'Follow-up completed! Activity points earned.',
            'data' => [
                'daily_score' => $metric->total_momentum_score,
                'points_earned' => $points,
            ],
        ]);
    });

    // ============== LEADERBOARD (Phase 4) ==============

    Route::get('/leaderboard', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $category = $request->get('category', 'top_realtor');
        $period = $request->get('period', 'weekly');

        $service = new \App\Services\LeaderboardService;
        $data = $service->getLeaderboard($category, $period, $user->id);

        return response()->json([
            'success' => true,
            'category' => $category,
            'period' => $period,
            'data' => $data,
        ]);
    });

    Route::get('/leaderboard/categories', function (Request $request) {
        return response()->json([
            'success' => true,
            'data' => [
                ['key' => 'top_realtor', 'name' => 'Top Realtor', 'icon' => '🏆', 'period' => 'weekly', 'description' => 'Weighted rank from revenue momentum, consistency, and weekly performance'],
                ['key' => 'consistency', 'name' => 'Consistency Leaders', 'icon' => '📅', 'period' => 'weekly', 'description' => 'Who shows up every single day'],
                ['key' => 'momentum_climber', 'name' => 'Momentum Climbers', 'icon' => '🚀', 'period' => 'weekly', 'description' => 'Biggest score improvement this week'],
                ['key' => 'deal_maker', 'name' => 'Deal Makers', 'icon' => '🤝', 'period' => 'monthly', 'description' => 'Most deals closed this month'],
                ['key' => 'revenue', 'name' => 'Revenue Kings', 'icon' => '💰', 'period' => 'monthly', 'description' => 'Highest commission this month'],
                ['key' => 'identity_discipline', 'name' => 'Identity Masters', 'icon' => '🧠', 'period' => 'weekly', 'description' => 'Highest identity conditioning score'],
            ],
        ]);
    });

    // Refresh leaderboards (can be called by admin or cron)
    Route::post('/leaderboard/refresh', function (Request $request) {
        $service = new \App\Services\LeaderboardService;
        $service->refreshLeaderboards();

        return response()->json([
            'success' => true,
            'message' => 'Leaderboards refreshed',
        ]);
    });

    // ============== BADGES (Phase 4) ==============

    Route::get('/badges', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $service = new \App\Services\BadgeService;
        $badges = $service->getUserBadges($user->id);

        $earnedCount = $badges->where('earned', true)->count();
        $totalCount = $badges->count();

        return response()->json([
            'success' => true,
            'data' => [
                'badges' => $badges,
                'earned_count' => $earnedCount,
                'total_count' => $totalCount,
                'completion_percent' => $totalCount > 0 ? round(($earnedCount / $totalCount) * 100) : 0,
            ],
        ]);
    });

    Route::get('/badges/recent', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $recent = DB::table('user_badges')
            ->join('badges', 'badges.id', '=', 'user_badges.badge_id')
            ->where('user_badges.user_id', $user->id)
            ->orderByDesc('user_badges.earned_at')
            ->limit(5)
            ->select('badges.*', 'user_badges.earned_at')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $recent,
        ]);
    });

    // ============== WEEKLY REVIEW (Phase 6 preview) ==============

    Route::get('/weekly-review', function (Request $request) {
        $user = getAuthUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $weekStart = now()->startOfWeek()->toDateString();
        $weekEnd = now()->endOfWeek()->toDateString();

        $metrics = \App\Models\PerformanceMetric::where('user_id', $user->id)
            ->whereBetween('date', [$weekStart, $weekEnd])
            ->get();

        $avgScore = $metrics->avg('total_momentum_score') ?? 0;
        $daysActive = $metrics->where('total_momentum_score', '>', 0)->count();

        $totalActivities = DB::table('activities')
            ->where('user_id', $user->id)
            ->where('is_completed', true)
            ->whereBetween('completed_at', [$weekStart, now()])
            ->count();

        $results = \App\Models\Result::where('user_id', $user->id)
            ->whereBetween('date', [$weekStart, $weekEnd])
            ->get();

        $leads = $results->where('type', 'hot_lead')->count();
        $deals = $results->where('type', 'deal_closed')->count();
        $commission = $results->whereIn('type', ['commission', 'deal_closed'])->sum('value');

        // Personal best comparison
        $allTimeAvg = \App\Models\PerformanceMetric::where('user_id', $user->id)
            ->avg('total_momentum_score') ?? 0;

        $vsAverage = $allTimeAvg > 0 ? round((($avgScore - $allTimeAvg) / $allTimeAvg) * 100) : 0;

        // Motivational message (never negative)
        $message = $vsAverage > 0
            ? "🔥 You scored {$vsAverage}% higher than your personal average this week. Keep going!"
            : "💪 Every active day builds momentum. You showed up {$daysActive}/7 days this week.";

        return response()->json([
            'success' => true,
            'data' => [
                'week' => ['start' => $weekStart, 'end' => $weekEnd],
                'avg_score' => round($avgScore),
                'days_active' => $daysActive,
                'consistency_percent' => round(($daysActive / 7) * 100),
                'total_activities' => $totalActivities,
                'leads' => $leads,
                'deals' => $deals,
                'commission' => (float) $commission,
                'streak' => $user->current_streak,
                'vs_average_percent' => $vsAverage,
                'message' => $message,
            ],
        ]);
    });

});

// Disaster Recovery & System Backups (Admin Only)
Route::group(['prefix' => 'admin/system'], function() {
    Route::get('/backups', [\App\Http\Controllers\BackupController::class, 'index']);
    Route::get('/backups/download/{filename}', [\App\Http\Controllers\BackupController::class, 'download']);
    Route::delete('/backups/{filename}', [\App\Http\Controllers\BackupController::class, 'destroy']);
    Route::get('/backup', [\App\Http\Controllers\BackupController::class, 'export']);
    Route::post('/restore', [\App\Http\Controllers\BackupController::class, 'import']);
});

EOF
