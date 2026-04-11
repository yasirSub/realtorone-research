import paramiko

HOST = "187.77.184.129"
USER = "root"
PASSWORD = "Onework@2026"

commands = [
    ("Server identity", "hostnamectl; whoami; pwd"),
    ("Uptime", "uptime"),
    ("Disk usage", "df -h"),
    ("Memory", "free -h"),
    ("Root top-level", "ls -lah /"),
    ("/root contents", "ls -lah /root"),
    ("/opt contents", "ls -lah /opt || true"),
    ("/var contents", "ls -lah /var || true"),
    ("/var/www contents", "ls -lah /var/www || true"),
    ("/root/realtorone contents", "ls -lah /root/realtorone || true"),
    ("/root/realtorone/backend contents", "ls -lah /root/realtorone/backend || true"),
    ("/opt/realtorone-website contents", "ls -lah /opt/realtorone-website || true"),
    ("Docker containers", "docker ps -a"),
    ("Docker images", "docker images"),
    ("Docker volumes", "docker volume ls"),
    ("Docker networks", "docker network ls"),
    ("Docker system df", "docker system df"),
    ("Top disk consumers under /", "du -xhd1 / 2>/dev/null | sort -h"),
]

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

print("Connecting to VPS...")
client.connect(HOST, username=USER, password=PASSWORD, timeout=30, look_for_keys=False, allow_agent=False)
print("Connected.")

for title, cmd in commands:
    print("\n" + "=" * 22 + f" {title} " + "=" * 22)
    stdin, stdout, stderr = client.exec_command(cmd, timeout=120)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    code = stdout.channel.recv_exit_status()
    if out.strip():
        print(out.strip())
    if err.strip():
        print("[stderr]")
        print(err.strip())
    print(f"[exit] {code}")

client.close()
print("\nInventory complete.")
