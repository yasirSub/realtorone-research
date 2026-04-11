import paramiko

HOST = "187.77.184.129"
USER = "root"
PASSWORD = "Onework@2026"

safe_delete_cmds = [
    "df -h",
    "docker system df",
    "find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} +",
    "rm -rf /root/.cache/*",
    "find /var/tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} +",
    "find /var/log -type f -name '*.gz' -delete",
    "find /var/log -type f -name '*.1' -delete",
    "find /var/log -type f -name '*.old' -delete",
    "rm -f '/root/e up -d --build' '/root/temp_api_fix.sh'",
    "docker builder prune -af",
    "docker image prune -af",
    "docker container prune -f",
    "docker network prune -f",
    "apt-get clean",
    "rm -rf /var/lib/apt/lists/*",
    "df -h",
    "docker system df",
]

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, username=USER, password=PASSWORD, timeout=30, look_for_keys=False, allow_agent=False)

print('Connected to VPS for safe file cleanup.')
for cmd in safe_delete_cmds:
    print(f"\n>>> {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd, timeout=300)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    code = stdout.channel.recv_exit_status()
    if out.strip():
        print(out.strip())
    if err.strip():
        print('[stderr]')
        print(err.strip())
    print(f"[exit] {code}")

print('\nSafe cleanup completed.')
client.close()
