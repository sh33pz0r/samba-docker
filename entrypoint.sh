#!/bin/bash -e

SMBCONF="/etc/samba/smb.conf"

echo Using SMB with user $USER
echo Shareable mount $STORAGE
echo Configured Workgroup $WORKGROUP


### add user and smb account if does not exist ###
if id "$USER" >/dev/null 2>&1; then
        echo "user exists"
else
        echo "user does not exist, adding"
        useradd -u 9001 -g sudo -d /home/$USER -s /bin/bash -p $PASS $USER
        (echo "$PASS"; echo "$PASS") | smbpasswd -s -a $USER
fi


### create smb.conf ###
cat > $SMBCONF <<- EOM
[global]
workgroup = $WORKGROUP
server string = %h server
dns proxy = no
log level = 1
syslog = 1
log file = /var/log/samba/log.%m
max log size = 1000
syslog only = yes
panic action = /usr/share/samba/panic-action %d
encrypt passwords = true
passdb backend = tdbsam
obey pam restrictions = yes
unix password sync = no
passwd program = /usr/bin/passwd %u
passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
pam password change = yes
socket options = TCP_NODELAY IPTOS_LOWDELAY
guest account = nobody
load printers = no
disable spoolss = yes
printing = bsd
printcap name = /dev/null
unix extensions = yes
wide links = no
create mask = 0777
directory mask = 0777
use sendfile = yes
aio read size = 16384
aio write size = 16384
null passwords = no
local master = no
time server = no
wins support = no
#======================= Share Definitions =======================
[NAS]
path = $STORAGE
guest ok = no
read only = no
browseable = yes
inherit acls = yes
inherit permissions = no
ea support = no
store dos attributes = no
vfs objects = full_audit
full_audit:prefix = %u|%I|%m|%P|%S
full_audit:success = mkdir rename unlink rmdir pwrite
full_audit:failure = none
full_audit:facility = local7
full_audit:priority = NOTICE
printable = no
create mask = 0755
force create mode = 0644
directory mask = 0755
force directory mode = 0755
hide dot files = yes
valid users = $USER
invalid users =
read list =
write list = 
EOM


exec /usr/sbin/smbd -FS -s /etc/samba/smb.conf
