import paramiko

HOST = "187.77.184.129"
USER = "root"
PASSWORD = "Onework@2026"

commands = [
    "mkdir -p /root/realtorone/backend",
    "cd /root/realtorone/backend && if [ ! -d .git ]; then git clone https://github.com/yasirSub/realtorone-backend.git .; fi",
    "cd /root/realtorone/backend && git fetch origin main",
    "cd /root/realtorone/backend && git reset --hard origin/main",
    "cd /root/realtorone/backend && if [ ! -f .env ]; then cp .env.example .env || touch .env; fi",
    "cd /root/realtorone/backend && docker compose up -d --build --remove-orphans",
    "cd /root/realtorone/backend && docker compose ps",
    "docker exec backend-app-1 php artisan migrate --force",
    "docker exec backend-app-1 php artisan db:seed --force",
    "cd /root/realtorone/backend && docker compose ps",
]

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, username=USER, password=PASSWORD, timeout=30, look_for_keys=False, allow_agent=False)

print('Connected to VPS. Starting backend deploy + seed...')

for cmd in commands:
    print(f"\n>>> {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd, timeout=1800)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    code = stdout.channel.recv_exit_status()
    if out.strip():
        print(out.strip())
    if err.strip():
        print('[stderr]')
        print(err.strip())
    print(f"[exit] {code}")
    if code != 0:
        raise SystemExit(code)

print('\nBackend deploy + seeder completed successfully.')
client.close()
