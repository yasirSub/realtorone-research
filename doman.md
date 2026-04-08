domain :- 

# RealtorOne Research & Domain Info (Updated Deployment)
aanantbishthealing.com



------------------server(VPS)-----------------------------
Ubuntu 24.04.4 LTS srv1423606 ttyS0
srv1423606 login: root 
password : Onework@2026

-----while deployed -------

root@srv1423606:~# ^[[200~ssh-keygen -t ed25519 -C "vps-realtorone"~
\ssh-keygen: command not found
root@srv1423606:~# ssh-keygen -t ed25519 -C "vps-realtorone"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/root/.ssh/id_ed25519):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_ed25519
Your public key has been saved in /root/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:LVHx2ClY5yPtz8Wjzmjl7Zg7WPrPyIIWtgEipQZ8hY0 vps-realtorone
The key's randomart image is:
+--[ED25519 256]--+
|.   =.    +..    |
| o E o   + B .   |
|  o o   o + B    |
|   + . . o + . . |
|  . . . S . .  .o|
|         =   =...|
|        . = *.+  |
|         + ==o=. |
|        . ..oX=+ |

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3mi6ut36iKodJt0vU+YSO3dy3lXObbJqF+uQyNoLk6 vps-realtorone




root@srv1423606:~# cat /root/.ssh/id_ed25519
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACAd5ourrd+oiqHSbdL1PmEjt3ct5Vzm2yahfrkMjaC5OgAAAJgsXNXHLFzV
xwAAAAtzc2gtZWQyNTUxOQAAACAd5ourrd+oiqHSbdL1PmEjt3ct5Vzm2yahfrkMjaC5Og
AAAEBQ0D0vJhBcNU4kyaoVWYzGUz5x2tAMLXfERey6Pi+zRx3mi6ut36iKodJt0vU+YSO3
dy3lXObbJqF+uQyNoLk6AAAADnZwcy1yZWFsdG9yb25lAQIDBAUGBw==
-----END OPENSSH PRIVATE KEY-----




/var/www/html/storage/app
/var/www/html/storage/app/.gitignore
/var/www/html/storage/app/private
/var/www/html/storage/app/private/.gitignore
/var/www/html/storage/app/public
/var/www/html/storage/app/public/course-assets

---

### Backup Manager Instructions (VPS)
The script is located at: `/root/realtorone/backup_manager.sh`

**Usage:**
- `bash /root/realtorone/backup_manager.sh list` - Show current videos on disk and in DB.
- `bash /root/realtorone/backup_manager.sh all` - Create a full zip of all media assets.
- `bash /root/realtorone/backup_manager.sh course <prefix>` - Backup specific files starting with prefix (e.g., `1774`).

---

### Video Persistence Fix
- **Compose Volume:** Added host mapping for `course-assets` to prevent data loss on redeploy.
- **DB Audit:** Found 19 video entries in `course_materials`. Only 2 exist on disk. 17 videos need to be re-uploaded.



flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://aanantbishthealing.com/api












