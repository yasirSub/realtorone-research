import paramiko

HOST = "187.77.184.129"
USER = "root"
PASSWORD = "Onework@2026"

cmd = "curl -s -X POST http://127.0.0.1:8000/api/admin/login -H 'Content-Type: application/json' -d '{\"email\":\"admin@realtorone.com\",\"password\":\"ChangeThisPassword123!@#\"}'"

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, username=USER, password=PASSWORD, timeout=30, look_for_keys=False, allow_agent=False)
stdin, stdout, stderr = client.exec_command(cmd, timeout=120)
out = stdout.read().decode('utf-8', errors='replace')
err = stderr.read().decode('utf-8', errors='replace')
code = stdout.channel.recv_exit_status()
print(out)
if err.strip():
    print('[stderr]')
    print(err)
print(f'[exit] {code}')
client.close()
