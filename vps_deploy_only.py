import paramiko

HOST = "187.77.184.129"
USER = "root"
PASSWORD = "Onework@2026"

backend_cmds = [
    "mkdir -p /root/realtorone/backend",
    "cd /root/realtorone/backend && if [ ! -d .git ]; then git clone https://github.com/yasirSub/realtorone-backend.git .; fi",
    "cd /root/realtorone/backend && git fetch origin main",
    "cd /root/realtorone/backend && git reset --hard origin/main",
    "cd /root/realtorone/backend && if [ ! -f .env ]; then cp .env.example .env || touch .env; fi",
    "cd /root/realtorone/backend && docker compose up -d --build --remove-orphans",
    "docker exec backend-app-1 php artisan migrate --force",
    "docker exec backend-app-1 php artisan db:seed --force || true",
    "cd /root/realtorone/backend && docker compose ps",
]

website_cmds = [
    "DEPLOY_PATH=/opt/realtorone-website; if [ ! -d \"$DEPLOY_PATH/.git\" ]; then rm -rf \"$DEPLOY_PATH\"; git clone https://github.com/yasirSub/realtorone-website.git \"$DEPLOY_PATH\"; fi",
    "cd /opt/realtorone-website && git fetch origin main",
    "cd /opt/realtorone-website && git checkout main || git checkout -b main origin/main",
    "cd /opt/realtorone-website && git pull --ff-only origin main",
    "systemctl stop nginx || true",
    "systemctl disable nginx || true",
    "docker rm -f realtorone-website || true",
    "cd /opt/realtorone-website && docker compose down --remove-orphans || true",
    "cd /opt/realtorone-website && docker compose up -d --build --remove-orphans website",
    "docker image prune -af || true",
    "docker ps --filter name=realtorone-website",
]

def run(client, cmd, timeout=2400):
    print(f"\n>>> {cmd}")
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
client.connect(HOST, username=USER, password=PASSWORD, timeout=30, look_for_keys=False, allow_agent=False)

try:
    print("=== Backend Deploy ===")
    for c in backend_cmds:
        code = run(client, c)
        if code != 0:
            raise RuntimeError(f"Backend deploy failed: {c}")

    print("=== Website Deploy ===")
    for c in website_cmds:
        code = run(client, c)
        if code != 0:
            raise RuntimeError(f"Website deploy failed: {c}")

    print("=== Final Disk ===")
    run(client, "df -h")

    print("DONE")
finally:
    client.close()
