import json
import os
import re

import paramiko

HOST = os.getenv("VPS_HOST", "")
USER = os.getenv("VPS_USER", "root")
PASSWORD = os.getenv("VPS_PASSWORD", "")
TEST_EMAIL = os.getenv("TEST_EMAIL", "yasir.subhani12345@gmail.com")
NEW_PASSWORD = os.getenv("TEST_NEW_PASSWORD", "TempReset@2026!")

if not HOST or not PASSWORD:
    raise SystemExit("Set VPS_HOST and VPS_PASSWORD environment variables first.")


def run(client: paramiko.SSHClient, cmd: str, timeout: int = 180):
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    code = stdout.channel.recv_exit_status()
    return code, out, err


client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(
    HOST,
    username=USER,
    password=PASSWORD,
    timeout=30,
    look_for_keys=False,
    allow_agent=False,
)

try:
    print(f"Testing forgot-password flow for: {TEST_EMAIL}")

    forgot_payload = json.dumps({"email": TEST_EMAIL})
    forgot_cmd = (
        "curl -s -X POST http://127.0.0.1:8000/api/password/forgot "
        "-H 'Content-Type: application/json' "
        f"-d '{forgot_payload}'"
    )
    code, out, err = run(client, forgot_cmd)
    print("\n[forgot]", out.strip())
    if code != 0:
        raise SystemExit(f"forgot request failed: {err}")

    otp_cmd = (
        "docker exec backend-mysql-1 mysql -N -s -usail -ppassword -D realtorone "
        f"-e \"SELECT token FROM otps WHERE identifier='{TEST_EMAIL}' ORDER BY id DESC LIMIT 1;\""
    )
    code, out, err = run(client, otp_cmd)
    if code != 0:
        raise SystemExit(f"failed to fetch otp: {err}")

    token = out.strip().splitlines()[0].strip() if out.strip() else ""
    if not token:
        raise SystemExit("No OTP token found in DB for the test email.")

    print(f"[otp] token fetched: {token}")

    verify_payload = json.dumps({"email": TEST_EMAIL, "token": token})
    verify_cmd = (
        "curl -s -X POST http://127.0.0.1:8000/api/password/verify-token "
        "-H 'Content-Type: application/json' "
        f"-d '{verify_payload}'"
    )
    code, out, err = run(client, verify_cmd)
    print("\n[verify-token]", out.strip())
    if code != 0:
        raise SystemExit(f"verify-token request failed: {err}")

    reset_payload = json.dumps(
        {"email": TEST_EMAIL, "token": token, "password": NEW_PASSWORD}
    )
    reset_cmd = (
        "curl -s -X POST http://127.0.0.1:8000/api/password/reset "
        "-H 'Content-Type: application/json' "
        f"-d '{reset_payload}'"
    )
    code, out, err = run(client, reset_cmd)
    print("\n[reset-password]", out.strip())
    if code != 0:
        raise SystemExit(f"reset request failed: {err}")

    verify_again_cmd = (
        "curl -s -X POST http://127.0.0.1:8000/api/password/verify-token "
        "-H 'Content-Type: application/json' "
        f"-d '{verify_payload}'"
    )
    code, out, err = run(client, verify_again_cmd)
    print("\n[verify-token again]", out.strip())

finally:
    client.close()
