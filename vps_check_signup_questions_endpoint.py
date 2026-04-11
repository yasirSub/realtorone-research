import paramiko, json

HOST = "187.77.184.129"
USER = "root"
PASSWORD = "Onework@2026"

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, username=USER, password=PASSWORD, timeout=30, look_for_keys=False, allow_agent=False)

# 1) login to get token
login_cmd = "curl -s -X POST http://127.0.0.1:8000/api/admin/login -H 'Content-Type: application/json' -d '{\"email\":\"admin@realtorone.com\",\"password\":\"ChangeThisPassword123!@#\"}'"
stdin, stdout, stderr = client.exec_command(login_cmd, timeout=120)
login_out = stdout.read().decode('utf-8', errors='replace')
code = stdout.channel.recv_exit_status()
print('login code', code)
print(login_out)
obj = json.loads(login_out)
token = obj.get('token','')

# 2) internal endpoint check
q1 = f"curl -s -i http://127.0.0.1:8000/api/admin/diagnosis/questions -H 'Authorization: Bearer {token}'"
stdin, stdout, stderr = client.exec_command(q1, timeout=120)
print('\n--- internal /api/admin/diagnosis/questions ---')
print(stdout.read().decode('utf-8', errors='replace'))

# 3) public website proxy check
q2 = f"curl -s -i http://127.0.0.1/api/admin/diagnosis/questions -H 'Authorization: Bearer {token}'"
stdin, stdout, stderr = client.exec_command(q2, timeout=120)
print('\n--- via nginx /api/admin/diagnosis/questions ---')
print(stdout.read().decode('utf-8', errors='replace'))

client.close()
