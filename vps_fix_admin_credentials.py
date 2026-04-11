import paramiko

HOST = "187.77.184.129"
USER = "root"
PASSWORD = "Onework@2026"

cmds = [
    "docker exec backend-app-1 php artisan tinker --execute=\"\\App\\Models\\User::updateOrCreate(['email'=>'admin@realtorone.com'], ['name'=>'Admin Operator','password'=>\\Illuminate\\Support\\Facades\\Hash::make('ChangeThisPassword123!@#'),'membership_tier'=>'Titan']);\"",
    "docker exec backend-app-1 php artisan cache:clear",
    "docker exec backend-app-1 php artisan config:clear",
    "docker exec backend-app-1 php artisan route:clear",
    "docker exec backend-app-1 php artisan tinker --execute=\"dump(\\App\\Models\\User::whereIn('email',['admin@realtorone.com','admin@yas1r.local'])->get(['id','name','email'])->toArray());\"",
]

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, username=USER, password=PASSWORD, timeout=30, look_for_keys=False, allow_agent=False)
print('Connected. Applying admin credential fix...')

for cmd in cmds:
    print(f"\n>>> {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd, timeout=600)
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

client.close()
print('Admin credential fix completed.')
