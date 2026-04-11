import paramiko

HOST = "187.77.184.129"
USER = "root"
PASSWORD = "Onework@2026"

cmds = [
    "cd /root/realtorone/backend && docker compose ps",
    "for i in $(seq 1 40); do S=$(docker inspect -f '{{.State.Health.Status}}' backend-mysql-1 2>/dev/null || echo none); R=$(docker inspect -f '{{.State.Status}}' backend-mysql-1 2>/dev/null || echo missing); echo \"Attempt $i: mysql status=$R health=$S\"; if [ \"$R\" = \"running\" ] && [ \"$S\" = \"healthy\" ]; then exit 0; fi; sleep 3; done; exit 1",
    "docker exec backend-app-1 php artisan migrate --force",
    "docker exec backend-app-1 php artisan db:seed --force",
    "cd /root/realtorone/backend && docker compose ps",
]

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, username=USER, password=PASSWORD, timeout=30, look_for_keys=False, allow_agent=False)
print('Connected to VPS for migration+seed retry...')

for cmd in cmds:
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

print('\nMigration + seeder completed successfully.')
client.close()
