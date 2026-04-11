import paramiko
import sys

HOST = "187.77.184.129"
USER = "root"
PASSWORD = "Onework@2026"

BACKEND_REPO = "https://github.com/yasirSub/realtorone-backend.git"
WEBSITE_REPO = "https://github.com/yasirSub/realtorone-website.git"


def run_cmd(client, cmd, timeout=1800):
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
    return code, out, err


def run_or_fail(client, cmd, timeout=1800):
    code, out, err = run_cmd(client, cmd, timeout)
    if code != 0:
        raise RuntimeError(f"Command failed ({code}): {cmd}\n{err}")
    return out


client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    print("Connecting to VPS...")
    client.connect(HOST, username=USER, password=PASSWORD, timeout=30, look_for_keys=False, allow_agent=False)
    print("Connected.")

    run_or_fail(client, "df -h")
    run_cmd(client, "docker system df")
    run_cmd(client, "du -xhd1 / 2>/dev/null | sort -h")

    print("\n=== Cleanup Start ===")
    run_cmd(client, "docker container prune -f")
    run_cmd(client, "docker image prune -af")
    run_cmd(client, "docker builder prune -af")
    run_cmd(client, "docker network prune -f")
    run_cmd(client, "apt-get clean")
    run_cmd(client, "rm -rf /var/lib/apt/lists/*")
    run_cmd(client, "journalctl --vacuum-time=7d")
    run_cmd(client, "find /var/log -type f -name '*.log' -size +100M -exec truncate -s 0 {} \\; || true")
    run_or_fail(client, "df -h")

    print("\n=== Backend Deploy ===")
    backend_deploy = f"""
set -e
mkdir -p /root/realtorone/backend
cd /root/realtorone/backend
if [ ! -d .git ]; then
  git clone {BACKEND_REPO} .
fi
git fetch origin main
git reset --hard origin/main
if [ ! -f .env ]; then
  cp .env.example .env || touch .env
fi
docker compose up -d --build --remove-orphans
for i in $(seq 1 20); do
  MYSQL_STATUS=$(docker inspect -f '{{{{.State.Status}}}}' backend-mysql-1 2>/dev/null || echo "not_found")
  APP_STATUS=$(docker inspect -f '{{{{.State.Status}}}}' backend-app-1 2>/dev/null || echo "not_found")
  MYSQL_HEALTH=$(docker inspect -f '{{{{.State.Health.Status}}}}' backend-mysql-1 2>/dev/null || echo "none")
  echo "MySQL: $MYSQL_STATUS($MYSQL_HEALTH) App: $APP_STATUS Attempt: $i/20"
  if [ "$MYSQL_STATUS" = "running" ] && [ "$APP_STATUS" = "running" ]; then
    break
  fi
  sleep 5
done
docker exec backend-app-1 php artisan migrate --force
docker exec backend-app-1 php artisan db:seed --force || true
docker compose ps
"""
    run_or_fail(client, f"bash -lc {backend_deploy!r}", timeout=2400)

    print("\n=== Website Deploy ===")
    website_deploy = f"""
set -e
DEPLOY_PATH=/opt/realtorone-website
if [ ! -d \"$DEPLOY_PATH/.git\" ]; then
  rm -rf \"$DEPLOY_PATH\"
  git clone {WEBSITE_REPO} \"$DEPLOY_PATH\"
fi
cd \"$DEPLOY_PATH\"
git fetch origin main
git checkout main || git checkout -b main origin/main
git pull --ff-only origin main
systemctl stop nginx || true
systemctl disable nginx || true
docker rm -f realtorone-website || true
docker compose down --remove-orphans || true
docker compose up -d --build --remove-orphans website
docker image prune -af || true
docker ps --filter name=realtorone-website
"""
    run_or_fail(client, f"bash -lc {website_deploy!r}", timeout=2400)

    print("\n=== Final Disk Check ===")
    run_or_fail(client, "df -h")

    print("\nDONE: Cleanup + backend deploy + website deploy completed.")

finally:
    client.close()
