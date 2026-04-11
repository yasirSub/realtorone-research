import paramiko

HOST = "187.77.184.129"
USER = "root"
PASSWORD = "Onework@2026"

patch_cmd = "python3 - <<'PY'\nfrom pathlib import Path\np = Path('/root/realtorone/backend/routes/api.php')\ns = p.read_text(encoding='utf-8')\nold = '''if ($accessToken && $accessToken->tokenable instanceof User) {\n            return $accessToken->tokenable;\n        }'''\nnew = '''if ($accessToken && $accessToken->tokenable instanceof User) {\n            return $accessToken->tokenable->withAccessToken($accessToken);\n        }'''\nif old not in s:\n    raise SystemExit('Target snippet not found; patch not applied')\ns = s.replace(old, new, 1)\np.write_text(s, encoding='utf-8')\nprint('Patched routes/api.php')\nPY"

cmds = [
    patch_cmd,
    "cd /root/realtorone/backend && docker compose up -d --build app",
    "docker exec backend-app-1 php artisan optimize:clear",
    "TOKEN=$(curl -s -X POST http://127.0.0.1:8000/api/admin/login -H 'Content-Type: application/json' -d '{\"email\":\"admin@realtorone.com\",\"password\":\"ChangeThisPassword123!@#\"}' | python3 -c 'import sys,json; print(json.load(sys.stdin).get(\"token\",\"\"))'); curl -s -i http://127.0.0.1:8000/api/admin/diagnosis/questions -H \"Authorization: Bearer $TOKEN\"",
]

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, username=USER, password=PASSWORD, timeout=30, look_for_keys=False, allow_agent=False)
print('Connected. Applying live patch + restart...')

for cmd in cmds:
    print('\n>>>', cmd)
    stdin, stdout, stderr = client.exec_command(cmd, timeout=2400)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    code = stdout.channel.recv_exit_status()
    if out.strip():
        print(out.strip())
    if err.strip():
        print('[stderr]')
        print(err.strip())
    print('[exit]', code)
    if code != 0:
        raise SystemExit(code)

client.close()
print('Live fix complete.')
