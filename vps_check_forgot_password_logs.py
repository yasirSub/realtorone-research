import os
import paramiko

HOST = os.getenv("VPS_HOST", "")
USER = os.getenv("VPS_USER", "root")
PASSWORD = os.getenv("VPS_PASSWORD", "")
APP_CONTAINER = os.getenv("APP_CONTAINER", "backend-app-1")

if not HOST or not PASSWORD:
    raise SystemExit(
        "Missing VPS credentials. Set VPS_HOST and VPS_PASSWORD environment variables."
    )

commands = [
    (
        "Containers",
        "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'",
    ),
    (
        "Recent docker logs (auth/reset/otp/mail/errors)",
        "docker logs backend-app-1 --tail 400 2>&1 | grep -Ei 'password|reset|otp|mail|smtp|exception|error|failed' || true",
    ),
    (
        "Laravel log file tail (same filters)",
        "docker exec backend-app-1 sh -lc \"test -f storage/logs/laravel.log && tail -n 400 storage/logs/laravel.log | grep -Ei 'password|reset|otp|mail|smtp|exception|error|failed' || echo 'laravel.log not found'\"",
    ),
    (
        "Mail env check",
        "docker exec backend-app-1 sh -lc \"printenv | grep -E '^(MAIL_MAILER|MAIL_HOST|MAIL_PORT|MAIL_USERNAME|MAIL_FROM_ADDRESS|APP_ENV|APP_URL)=' || true\"",
    ),
]


def run(client: paramiko.SSHClient, title: str, cmd: str, timeout: int = 240) -> None:
    print("\n" + "=" * 20 + f" {title} " + "=" * 20)
    print(f">>> {cmd}")
    _stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    code = stdout.channel.recv_exit_status()

    if out.strip():
        print(out.strip())
    if err.strip():
        print("[stderr]")
        print(err.strip())
    print(f"[exit] {code}")


client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
print("Connecting to VPS...")
client.connect(
    HOST,
    username=USER,
    password=PASSWORD,
    timeout=30,
    look_for_keys=False,
    allow_agent=False,
)
print("Connected.")

try:
    for title, cmd in commands:
        run(client, title, cmd)
finally:
    client.close()
    print("\nDone.")
