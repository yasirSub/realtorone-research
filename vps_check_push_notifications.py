import paramiko

HOST = "187.77.184.129"
USER = "root"
PASSWORD = "Onework@2026"

commands = [
    ("Containers", "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"),
    (
        "App env (Firebase + queue)",
        "docker exec backend-app-1 sh -lc \"printenv | grep -E '^(APP_ENV|APP_URL|QUEUE_CONNECTION|FIREBASE_PROJECT_ID|FIREBASE_CREDENTIALS_PATH|FIREBASE_CLIENT_EMAIL)=' || true\"",
    ),
    (
        "Firebase credentials file check",
        "docker exec backend-app-1 sh -lc \"ls -lah /var/www/html/realtor-one-firebase-adminsdk-fbsvc-4bdaeea92a.json || true\"",
    ),
    (
        "Firebase service account identity",
        "docker exec backend-app-1 sh -lc \"grep -E '\\\"project_id\\\"|\\\"client_email\\\"' /var/www/html/realtor-one-firebase-adminsdk-fbsvc-4bdaeea92a.json || true\"",
    ),
    (
        "Queue + scheduler processes",
        "docker exec backend-app-1 sh -lc \"ps aux | grep -E 'artisan queue:work|artisan schedule:work|artisan serve' | grep -v grep || true\"",
    ),
    (
        "Recent app logs (notification/fcm/queue)",
        "docker logs backend-app-1 --tail 250 2>&1 | grep -Ei 'fcm|notification|queue|push|error' || true",
    ),
    (
        "Recent FCM specific logs",
        "docker logs backend-app-1 --tail 1200 2>&1 | grep -Ei 'FCM|SendPushBroadcastJob|broadcast_id|send failed|OAuth' || true",
    ),
    (
        "DB: push tokens + broadcasts + queue",
        "docker exec backend-mysql-1 mysql -usail -ppassword -D realtorone -e \"SELECT COUNT(*) AS user_push_tokens_count FROM user_push_tokens; SELECT COUNT(*) AS broadcasts_count FROM notification_broadcasts; SELECT id,status,last_sent_count,last_error,next_run_at,last_run_at FROM notification_broadcasts ORDER BY id DESC LIMIT 10; SELECT COUNT(*) AS jobs_count FROM jobs; SELECT COUNT(*) AS failed_jobs_count FROM failed_jobs;\"",
    ),
    (
        "DB: broadcast targeting + token distribution",
        "docker exec backend-mysql-1 mysql -usail -ppassword -D realtorone -e \"SELECT id,audience,tier,target_user_ids,status,last_sent_count,last_error,scheduled_at,next_run_at,last_run_at FROM notification_broadcasts ORDER BY id DESC LIMIT 5; SELECT user_id,COUNT(*) AS tokens FROM user_push_tokens GROUP BY user_id ORDER BY tokens DESC LIMIT 20; SELECT id,email,status,membership_tier FROM users ORDER BY id DESC LIMIT 20;\"",
    ),
    (
        "Laravel recipient resolver + FCM config",
        "docker exec backend-app-1 php artisan tinker --execute='\\$b=\\App\\Models\\NotificationBroadcast::query()->latest(""id"")->first(); if(!\\$b){echo ""no_broadcast"".PHP_EOL; return;} \\$ids=(new \\App\\Services\\NotificationRecipientResolver)->resolveUserIds(\\$b); echo ""broadcast_id="".\\$b->id.PHP_EOL; echo ""audience="".\\$b->audience.PHP_EOL; echo ""resolved_users="".count(\\$ids).PHP_EOL; echo ""tokens_for_resolved="".(int)\\App\\Models\\UserPushToken::query()->whereIn(""user_id"",\\$ids)->count().PHP_EOL; echo ""fcm_configured="".(app(\\App\\Services\\FcmSenderService::class)->isConfigured()?""yes"":""no"").PHP_EOL;'",
    ),
    (
        "Direct FCM smoke test (single token)",
        "docker exec backend-app-1 php -r 'require ""vendor/autoload.php""; $app=require ""bootstrap/app.php""; $kernel=$app->make(\\Illuminate\\Contracts\\Console\\Kernel::class); $kernel->bootstrap(); $b=\\App\\Models\\NotificationBroadcast::query()->latest(""id"")->first(); if(!$b){echo ""no_broadcast\\n""; exit(0);} $ids=(new \\App\\Services\\NotificationRecipientResolver)->resolveUserIds($b); $tokens=\\App\\Models\\UserPushToken::query()->whereIn(""user_id"",$ids)->pluck(""token"")->all(); echo ""resolved_users="".count($ids)."" tokens_for_resolved="".count($tokens).""\\n""; $f=$app->make(\\App\\Services\\FcmSenderService::class); echo ""fcm_configured="".($f->isConfigured()?""yes"":""no"").""\\n""; if(count($tokens)>0){ $ok=$f->sendToToken($tokens[0], ""RealtorOne Debug"", ""FCM smoke test"", [""debug""=>""1""]); echo ""single_send="".($ok?""ok"":""fail"").""\\n""; }'",
    ),
]


def run(client, title, cmd, timeout=240):
    print("\n" + "=" * 20 + f" {title} " + "=" * 20)
    print(f">>> {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    code = stdout.channel.recv_exit_status()
    if out.strip():
        print(out.strip())
    if err.strip():
        print("[stderr]")
        print(err.strip())
    print(f"[exit] {code}")
    return code


client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
print("Connecting...")
client.connect(HOST, username=USER, password=PASSWORD, timeout=30, look_for_keys=False, allow_agent=False)
print("Connected.")

try:
    for title, cmd in commands:
        run(client, title, cmd)
finally:
    client.close()
    print("\nDone.")
