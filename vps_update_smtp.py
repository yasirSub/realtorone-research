import os
import paramiko

def update_vps_env():
    host = os.environ.get('VPS_HOST', '187.77.184.129')
    user = os.environ.get('VPS_USER', 'root')
    password = os.environ.get('VPS_PASSWORD', 'Onework@2026')
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(host, username=user, password=password, timeout=30)
        
        # Define the updates
        updates = [
            'sed -i "s/^MAIL_MAILER=.*/MAIL_MAILER=smtp/" .env',
            'sed -i "s/^MAIL_HOST=.*/MAIL_HOST=smtp-relay.brevo.com/" .env',
            'sed -i "s/^MAIL_PORT=.*/MAIL_PORT=587/" .env',
            'sed -i "s/^MAIL_USERNAME=.*/MAIL_USERNAME=a8239b001@smtp-brevo.com/" .env',
            'sed -i "s/^MAIL_PASSWORD=.*/MAIL_PASSWORD=xsmtpsib-02db8354f0ca6eaad36e846325cb8630dce7b9c647e042c8c66448702db5dd8a-MPVbsIzSuYKMG4NO/" .env',
            'sed -i "s/^MAIL_ENCRYPTION=.*/MAIL_ENCRYPTION=tls/" .env || echo "MAIL_ENCRYPTION=tls" >> .env',
            'sed -i "s/^MAIL_FROM_ADDRESS=.*/MAIL_FROM_ADDRESS=a8239b001@smtp-brevo.com/" .env'
        ]
        
        commands = [
            "cd /root/realtorone/backend",
            *updates,
            "docker compose exec -T app php artisan config:clear",
            "docker compose exec -T app php artisan cache:clear"
        ]
        
        full_command = " && ".join(commands)
        
        stdin, stdout, stderr = ssh.exec_command(full_command)
        print("STDOUT:", stdout.read().decode())
        print("STDERR:", stderr.read().decode())
        
    finally:
        ssh.close()

if __name__ == "__main__":
    update_vps_env()
